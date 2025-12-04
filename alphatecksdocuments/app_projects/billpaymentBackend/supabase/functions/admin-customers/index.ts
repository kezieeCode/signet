import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import {
  corsHeaders,
  handleCors,
  createErrorResponse,
  createSuccessResponse,
  verifyAdminSession,
  createSupabaseAdmin
} from '../_shared/utils.ts'

const ADMIN_TOKEN_HEADER = 'x-admin-session'
const ADMIN_TOKEN_FALLBACK_HEADER = 'x-admin-token'

interface CustomerListItem {
  id: string
  customerId: string
  name: string
  email: string | null
  phone: string | null
  status: 'active' | 'suspended'
  registrationDate: string
}

interface CustomersResponse {
  items: CustomerListItem[]
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
  filters: {
    applied: Record<string, unknown>
  }
}

interface CustomerDetail {
  id: string
  customerId: string
  firstName: string | null
  lastName: string | null
  username: string | null
  email: string | null
  phone: string | null
  status: 'active' | 'suspended'
  registrationDate: string
  walletBalance: number
}

function parseInteger(value: string | null, fallback: number): number {
  if (!value) return fallback
  const parsed = parseInt(value, 10)
  return Number.isNaN(parsed) ? fallback : parsed
}

function parseDate(value: string | null): string | null {
  if (!value) return null
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return null
  }
  return date.toISOString()
}

function parseUUID(value: string | null): string | null {
  if (!value) return null
  const normalized = value.trim()
  if (!/^[0-9a-fA-F-]{36}$/.test(normalized)) {
    return null
  }
  return normalized
}

function getRouteSegments(url: URL): string[] {
  const trimmed = url.pathname.replace(/\/+$/, '')
  const withoutPrefix = trimmed.replace(/^\/functions\/v1\//, '')
  const segments = withoutPrefix.split('/').filter(Boolean)
  if (segments.length === 0) return []
  const [root, ...rest] = segments
  if (root !== 'admin-customers') return []
  return rest
}

function normalizeStatus(status: string | null): 'active' | 'suspended' | null {
  if (!status) return null
  const lower = status.toLowerCase()
  if (lower === 'active' || lower === 'suspended') {
    return lower
  }
  return null
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    const url = new URL(req.url)
    const adminToken = req.headers.get(ADMIN_TOKEN_HEADER) ?? req.headers.get(ADMIN_TOKEN_FALLBACK_HEADER)

    if (!adminToken) {
      return createErrorResponse('Admin session token required', 401)
    }

    const adminSession = await verifyAdminSession(adminToken)
    if (!adminSession.valid || !adminSession.admin) {
      return createErrorResponse('Invalid or expired admin session', 401)
    }

    const segments = getRouteSegments(url)

    const supabaseAdmin = createSupabaseAdmin()

    // GET /admin-customers/filters
    if (req.method === 'GET' && segments.length === 1 && segments[0] === 'filters') {
      const { data, error } = await supabaseAdmin.rpc('admin_customers_filter_options')
      if (error || !data || data.length === 0) {
        console.error('admin_customers_filter_options error:', error)
        return createErrorResponse('Failed to fetch filter options', 500, error?.message)
      }

      const row = data[0]
      return createSuccessResponse({
        statuses: row.statuses ?? ['active', 'suspended'],
        registrationDates: row.registration_dates ?? {}
      }, 'Customer filter options retrieved successfully')
    }

    // Treat root or /list as listing endpoint
    const isListRequest = req.method === 'GET' && (segments.length === 0 || (segments.length === 1 && segments[0] === 'list'))
    if (isListRequest) {
      const limit = Math.max(1, Math.min(100, parseInteger(url.searchParams.get('limit'), 25)))
      const page = Math.max(1, parseInteger(url.searchParams.get('page'), 1))
      const offset = (page - 1) * limit

      const search = url.searchParams.get('search')?.trim() || null
      const statusFilter = normalizeStatus(url.searchParams.get('status'))
      const startDate = parseDate(url.searchParams.get('startDate'))
      const endDate = parseDate(url.searchParams.get('endDate'))
      const sortDirection = url.searchParams.get('sort')?.toLowerCase() === 'asc' ? 'asc' : 'desc'

      const [{ data: rows, error: rowsError }, { data: countData, error: countError }] = await Promise.all([
        supabaseAdmin.rpc('admin_customers_query', {
          search_text: search,
          status_filter: statusFilter,
          start_date: startDate,
          end_date: endDate,
          sort_direction: sortDirection,
          limit_count: limit,
          offset_count: offset
        }),
        supabaseAdmin.rpc('admin_customers_count', {
          search_text: search,
          status_filter: statusFilter,
          start_date: startDate,
          end_date: endDate
        })
      ])

      if (rowsError) {
        console.error('admin_customers_query error:', rowsError)
        return createErrorResponse('Failed to fetch customers', 500, rowsError.message)
      }

      if (countError) {
        console.error('admin_customers_count error:', countError)
        return createErrorResponse('Failed to fetch customer totals', 500, countError.message)
      }

      const totalRaw = Array.isArray(countData)
        ? (countData[0]?.admin_customers_count ?? countData[0]?.count)
        : countData
      const total = Number(totalRaw ?? 0)
      const totalPages = total === 0 ? 1 : Math.max(1, Math.ceil(total / limit))

      const items: CustomerListItem[] = (rows ?? []).map((row) => ({
        id: row.user_id,
        customerId: row.customer_id,
        name: row.full_name,
        email: row.email,
        phone: row.phone,
        status: (row.status as 'active' | 'suspended') ?? 'active',
        registrationDate: row.created_at
      }))

      const response: CustomersResponse = {
        items,
        pagination: {
          page,
          limit,
          total,
          totalPages
        },
        filters: {
          applied: {
            search,
            status: statusFilter,
            startDate,
            endDate,
            sort: sortDirection
          }
        }
      }

      return createSuccessResponse(response, 'Customers retrieved successfully')
    }

    // GET /admin-customers/:id
    if (req.method === 'GET' && segments.length === 1 && segments[0] !== 'filters' && segments[0] !== 'list') {
      const customerId = parseUUID(segments[0])
      if (!customerId) {
        return createErrorResponse('Invalid customer id', 400)
      }

      const [{ data: profile, error: profileError }, { data: walletData, error: walletError }, { data: authUser, error: authError }] = await Promise.all([
        supabaseAdmin
          .from('profiles')
          .select('id, first_name, last_name, username, phone, status, created_at')
          .eq('id', customerId)
          .maybeSingle(),
        supabaseAdmin.rpc('get_user_wallet_balance', { user_uuid: customerId }),
        supabaseAdmin.auth.admin.getUserById(customerId)
      ])

      if (profileError || !profile) {
        console.error('Fetch customer profile error:', profileError)
        return createErrorResponse('Customer not found', 404)
      }

      if (walletError) {
        console.error('get_user_wallet_balance error:', walletError)
      }

      if (authError) {
        console.error('Fetch auth user error:', authError)
      }

      const detail: CustomerDetail = {
        id: profile.id,
        customerId: profile.id,
        firstName: profile.first_name,
        lastName: profile.last_name,
        username: profile.username,
        email: authUser?.user?.email ?? null,
        phone: profile.phone,
        status: (profile.status as 'active' | 'suspended') ?? 'active',
        registrationDate: profile.created_at,
        walletBalance: Number(walletData ?? 0)
      }

      return createSuccessResponse(detail, 'Customer details retrieved successfully')
    }

    // PATCH /admin-customers/:id/status
    if (req.method === 'PATCH' && segments.length === 2 && segments[1] === 'status') {
      const customerId = parseUUID(segments[0])
      if (!customerId) {
        return createErrorResponse('Invalid customer id', 400)
      }

      const body = await req.json()
      const status = normalizeStatus(body?.status ?? null)
      if (!status) {
        return createErrorResponse('Invalid status value', 400)
      }

      const { data: updated, error: updateError } = await supabaseAdmin
        .from('profiles')
        .update({ status })
        .eq('id', customerId)
        .select('id, status, updated_at')
        .maybeSingle()

      if (updateError || !updated) {
        console.error('Update customer status error:', updateError)
        return createErrorResponse('Failed to update customer status', 500, updateError?.message)
      }

      return createSuccessResponse({
        id: updated.id,
        status: updated.status,
        updatedAt: updated.updated_at
      }, 'Customer status updated successfully')
    }

    return createErrorResponse('Not found', 404)
  } catch (error) {
    console.error('Admin customers error:', error)
    return createErrorResponse('Internal server error', 500, error instanceof Error ? error.message : String(error))
  }
})
