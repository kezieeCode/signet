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

interface TransactionItem {
  transactionId: string
  userId: string | null
  user: string
  type: string
  amount: number
  status: string
  date: string
  source: string
}

interface TransactionsResponse {
  items: TransactionItem[]
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
  filters?: {
    applied: Record<string, unknown>
  }
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

function getRoute(url: URL): string | null {
  const trimmed = url.pathname.replace(/\/+$/, '')
  const withoutPrefix = trimmed.replace(/^\/functions\/v1\//, '')
  const segments = withoutPrefix.split('/').filter(Boolean)
  if (segments.length === 0) {
    return null
  }
  const [root, ...rest] = segments
  if (root !== 'admin-transactions') {
    return null
  }
  return rest.join('/')
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

    const route = getRoute(url)
    if (route === null) {
      return createErrorResponse('Not found', 404)
    }

    const supabaseAdmin = createSupabaseAdmin()

    if (req.method === 'GET' && route === 'filters') {
      const { data, error } = await supabaseAdmin.rpc('admin_transactions_filter_options')

      if (error || !data || data.length === 0) {
        console.error('admin_transactions_filter_options error:', error)
        return createErrorResponse('Failed to fetch filter options', 500, error?.message)
      }

      const row = data[0]

      return createSuccessResponse({
        transactionTypes: row.transaction_types ?? [],
        statuses: row.statuses ?? [],
        users: row.users ?? []
      }, 'Filter options retrieved successfully')
    }

    if (req.method === 'GET' && (route === '' || route === 'list')) {
      const limit = Math.max(1, Math.min(100, parseInteger(url.searchParams.get('limit'), 25)))
      const page = Math.max(1, parseInteger(url.searchParams.get('page'), 1))
      const offset = (page - 1) * limit

      const search = url.searchParams.get('search')?.trim() || null
      const type = url.searchParams.get('type')?.trim() || null
      const status = url.searchParams.get('status')?.trim() || null
      const userId = parseUUID(url.searchParams.get('userId'))
      const startDate = parseDate(url.searchParams.get('startDate'))
      const endDate = parseDate(url.searchParams.get('endDate'))

      const rpcPayload: Record<string, unknown> = {
        search_text: search,
        filter_type: type,
        filter_status: status,
        filter_user: userId,
        start_date: startDate,
        end_date: endDate,
        limit_count: limit,
        offset_count: offset
      }

      const [{ data: rows, error: rowsError }, { data: countData, error: countError }] = await Promise.all([
        supabaseAdmin.rpc('admin_transactions_query', rpcPayload),
        supabaseAdmin.rpc('admin_transactions_count', {
          search_text: search,
          filter_type: type,
          filter_status: status,
          filter_user: userId,
          start_date: startDate,
          end_date: endDate
        })
      ])

      if (rowsError) {
        console.error('admin_transactions_query error:', rowsError)
        return createErrorResponse('Failed to fetch transactions', 500, rowsError.message)
      }

      if (countError) {
        console.error('admin_transactions_count error:', countError)
        return createErrorResponse('Failed to fetch transaction totals', 500, countError.message)
      }

      const totalRaw = Array.isArray(countData)
        ? (countData[0]?.admin_transactions_count ?? countData[0]?.count)
        : countData
      const total = Number(totalRaw ?? 0)
      const totalPages = total === 0 ? 1 : Math.max(1, Math.ceil(total / limit))

      const items: TransactionItem[] = (rows ?? []).map((row) => ({
        transactionId: row.transaction_id,
        userId: row.user_id ?? null,
        user: row.user_name,
        type: row.transaction_type,
        amount: Number(row.amount ?? 0),
        status: row.status,
        date: row.created_at,
        source: row.source
      }))

      const response: TransactionsResponse = {
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
            type,
            status,
            userId,
            startDate,
            endDate
          }
        }
      }

      return createSuccessResponse(response, 'Transactions retrieved successfully')
    }

    return createErrorResponse('Not found', 404)
  } catch (error) {
    console.error('Admin transactions error:', error)
    return createErrorResponse('Internal server error', 500, error instanceof Error ? error.message : String(error))
  }
})
