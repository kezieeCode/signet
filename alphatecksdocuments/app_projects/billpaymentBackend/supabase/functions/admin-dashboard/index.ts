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

interface OverviewResponse {
  totals: {
    transactions: {
      value: number
      change: number
    }
    revenue: {
      value: number
      change: number
    }
    activeUsers: {
      value: number
      change: number
    }
    newUsers: {
      value: number
      change: number
    }
  }
  totalsAllTime: {
    transactions: number
    revenue: number
    activeUsers: number
    newUsers: number
  }
  period: {
    current_start: string
    current_end: string
    previous_start: string
    previous_end: string
  }
  quickActions: Array<{ label: string; action: string }>
}

interface RecentActivityItem {
  id: string
  user: string
  transactionType: string
  amount: number
  status: string
  date: string
  source: string
}

function getRoute(url: URL): string | null {
  const trimmed = url.pathname.replace(/\/+$/, '')
  const withoutPrefix = trimmed.replace(/^\/functions\/v1\//, '')
  const segments = withoutPrefix.split('/').filter(Boolean)

  if (segments.length === 0) {
    return null
  }

  const [root, ...rest] = segments
  if (root !== 'admin-dashboard') {
    return null
  }

  return rest.join('/')
}

function toNumber(value: unknown): number {
  if (typeof value === 'number') return value
  if (typeof value === 'string') return parseFloat(value)
  return 0
}

function calculateChange(current: number, previous: number): number {
  if (previous === 0) {
    return current > 0 ? 100 : 0
  }
  return ((current - previous) / previous) * 100
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

    if (req.method === 'GET' && (route === '' || route === 'overview')) {
      const now = new Date()
      const currentStart = new Date(now)
      currentStart.setDate(currentStart.getDate() - 30)
      const previousStart = new Date(currentStart)
      previousStart.setDate(previousStart.getDate() - 30)

      const { data, error } = await supabaseAdmin.rpc('admin_dashboard_overview', {
        current_start: currentStart.toISOString(),
        previous_start: previousStart.toISOString()
      })

      if (error || !data || data.length === 0) {
        console.error('Overview RPC error:', error)
        return createErrorResponse('Failed to fetch dashboard overview', 500, error?.message)
      }

      const row = data[0]

      const overview: OverviewResponse = {
        totals: {
          transactions: {
            value: Number(row.total_transactions_current) || 0,
            change: Number(calculateChange(Number(row.total_transactions_current) || 0, Number(row.total_transactions_previous) || 0).toFixed(2))
          },
          revenue: {
            value: Number(toNumber(row.revenue_current).toFixed(2)),
            change: Number(calculateChange(toNumber(row.revenue_current), toNumber(row.revenue_previous)).toFixed(2))
          },
          activeUsers: {
            value: Number(row.active_users_current) || 0,
            change: Number(calculateChange(Number(row.active_users_current) || 0, Number(row.active_users_previous) || 0).toFixed(2))
          },
          newUsers: {
            value: Number(row.new_users_current) || 0,
            change: Number(calculateChange(Number(row.new_users_current) || 0, Number(row.new_users_previous) || 0).toFixed(2))
          }
        },
        totalsAllTime: {
          transactions: Number(row.total_transactions_all) || 0,
          revenue: Number(toNumber(row.revenue_all).toFixed(2)),
          activeUsers: Number(row.active_users_all) || 0,
          newUsers: Number(row.new_users_all) || 0
        },
        period: {
          current_start: currentStart.toISOString(),
          current_end: now.toISOString(),
          previous_start: previousStart.toISOString(),
          previous_end: currentStart.toISOString()
        },
        quickActions: [
          { label: 'New Transaction', action: 'start_transaction' },
          { label: 'View All Transactions', action: 'view_transactions' }
        ]
      }

      return createSuccessResponse(overview, 'Dashboard overview retrieved successfully')
    }

    if (req.method === 'GET' && route === 'recent-activity') {
      const limit = Math.max(1, Math.min(50, parseInt(url.searchParams.get('limit') ?? '10', 10)))
      const { data, error } = await supabaseAdmin.rpc('admin_dashboard_recent_activity', { limit_count: limit })

      if (error) {
        console.error('Recent activity RPC error:', error)
        return createErrorResponse('Failed to fetch recent activity', 500, error.message)
      }

      const items: RecentActivityItem[] = (data || []).map((item) => ({
        id: item.id,
        user: item.user_name,
        transactionType: item.transaction_type,
        amount: Number(toNumber(item.amount).toFixed(2)),
        status: item.status,
        date: item.created_at,
        source: item.source
      }))

      return createSuccessResponse({
        items,
        limit,
        count: items.length
      }, 'Recent activity retrieved successfully')
    }

    return createErrorResponse('Not found', 404)
  } catch (error) {
    console.error('Admin dashboard error:', error)
    return createErrorResponse('Internal server error', 500, error instanceof Error ? error.message : String(error))
  }
})
