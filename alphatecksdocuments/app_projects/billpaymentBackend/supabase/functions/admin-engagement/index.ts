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

function buildRoute(url: URL): string[] {
  const trimmed = url.pathname.replace(/\/+$/, '')
  const withoutPrefix = trimmed.replace(/^\/functions\/v1\//, '')
  const segments = withoutPrefix.split('/').filter(Boolean)
  if (segments.length === 0) return []
  const [root, ...rest] = segments
  if (root !== 'admin-engagement') return []
  return rest
}

function parseInterval(value: string | null): 'day' | 'week' | 'month' {
  if (!value) return 'month'
  const lower = value.toLowerCase()
  if (lower === 'day' || lower === 'week' || lower === 'month') {
    return lower
  }
  return 'month'
}

function parseDate(value: string | null, fallback: Date): Date {
  if (!value) return fallback
  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) {
    return fallback
  }
  return parsed
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

    const segments = buildRoute(url)
    if (segments.length === 0) {
      return createErrorResponse('Not found', 404)
    }

    const supabaseAdmin = createSupabaseAdmin()

    const defaultEnd = new Date()
    const defaultStart = new Date(defaultEnd)
    defaultStart.setDate(defaultStart.getDate() - 30)

    const startDate = parseDate(url.searchParams.get('startDate'), defaultStart)
    const endDate = parseDate(url.searchParams.get('endDate'), defaultEnd)
    const interval = parseInterval(url.searchParams.get('interval'))

    // GET /admin-engagement/overview
    if (req.method === 'GET' && segments.length === 1 && (segments[0] === 'overview' || segments[0] === 'summary')) {
      const [{ data: newUserData, error: newUserError }, { data: activeUserData, error: activeUserError }] = await Promise.all([
        supabaseAdmin.rpc('admin_engagement_new_users', {
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString(),
          interval_unit: interval
        }),
        supabaseAdmin.rpc('admin_engagement_active_users', {
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString(),
          interval_unit: interval
        })
      ])

      if (newUserError) {
        console.error('admin_engagement_new_users error:', newUserError)
        return createErrorResponse('Failed to fetch new users data', 500, newUserError.message)
      }

      if (activeUserError) {
        console.error('admin_engagement_active_users error:', activeUserError)
        return createErrorResponse('Failed to fetch active users data', 500, activeUserError.message)
      }

      const newUsers = (newUserData ?? []).map((row) => ({
        periodStart: row.period_start,
        periodEnd: row.period_end,
        count: Number(row.new_users ?? 0)
      }))

      const activeUsers = (activeUserData ?? []).map((row) => ({
        periodStart: row.period_start,
        periodEnd: row.period_end,
        count: Number(row.active_users ?? 0)
      }))

      const totals = {
        newUsers: newUsers.reduce((sum, item) => sum + item.count, 0),
        activeUsers: activeUsers.reduce((sum, item) => sum + item.count, 0)
      }

      return createSuccessResponse({
        period: {
          startDate: startDate.toISOString(),
          endDate: endDate.toISOString(),
          interval
        },
        newUsers,
        activeUsers,
        totals
      }, 'Engagement overview retrieved successfully')
    }

    // GET /admin-engagement/services
    if (req.method === 'GET' && segments.length === 1 && segments[0] === 'services') {
      const limit = parseInt(url.searchParams.get('limit') ?? '5', 10)
      const topLimit = Number.isNaN(limit) ? 5 : Math.max(1, Math.min(limit, 10))

      const [{ data: revenueData, error: revenueError }, { data: volumeData, error: volumeError }] = await Promise.all([
        supabaseAdmin.rpc('admin_service_performance_revenue', {
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString(),
          limit_count: topLimit
        }),
        supabaseAdmin.rpc('admin_service_performance_volume', {
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString(),
          limit_count: topLimit
        })
      ])

      if (revenueError) {
        console.error('admin_service_performance_revenue error:', revenueError)
        return createErrorResponse('Failed to fetch service revenue data', 500, revenueError.message)
      }

      if (volumeError) {
        console.error('admin_service_performance_volume error:', volumeError)
        return createErrorResponse('Failed to fetch service volume data', 500, volumeError.message)
      }

      const topByRevenue = (revenueData ?? []).map((row) => ({
        service: row.service_name,
        revenue: Number(row.total_revenue ?? 0)
      }))

      const topByVolume = (volumeData ?? []).map((row) => ({
        service: row.service_name,
        transactions: Number(row.total_transactions ?? 0)
      }))

      return createSuccessResponse({
        period: {
          startDate: startDate.toISOString(),
          endDate: endDate.toISOString()
        },
        topByRevenue,
        topByVolume
      }, 'Service performance retrieved successfully')
    }

    return createErrorResponse('Not found', 404)
  } catch (error) {
    console.error('Admin engagement error:', error)
    return createErrorResponse('Internal server error', 500, error instanceof Error ? error.message : String(error))
  }
})



