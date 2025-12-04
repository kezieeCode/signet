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

interface ReportsOverviewResponse {
  period: {
    startDate: string
    endDate: string
    interval: 'day' | 'week' | 'month'
  }
  transactionVolume: Array<{
    periodStart: string
    periodEnd: string
    count: number
    amount: number
  }>
  revenueTrends: Array<{
    periodStart: string
    totalRevenue: number
  }>
  typeDistribution: Array<{
    transactionType: string
    count: number
    amount: number
  }>
  totals: {
    transactions: number
    revenue: number
  }
}

function parseInterval(value: string | null): 'day' | 'week' | 'month' {
  if (!value) return 'month'
  const normalized = value.toLowerCase()
  if (normalized === 'day' || normalized === 'week' || normalized === 'month') {
    return normalized
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

function buildRoute(url: URL): string[] {
  const trimmed = url.pathname.replace(/\/+$/, '')
  const withoutPrefix = trimmed.replace(/^\/functions\/v1\//, '')
  const segments = withoutPrefix.split('/').filter(Boolean)
  if (segments.length === 0) return []
  const [root, ...rest] = segments
  if (root !== 'admin-reports') return []
  return rest
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

    // GET /admin-reports/filters
    if (req.method === 'GET' && segments.length === 1 && segments[0] === 'filters') {
      const now = new Date()
      const thirtyDaysAgo = new Date(now)
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)

      return createSuccessResponse({
        reportTypes: [
          { id: 'overview', label: 'Overview' },
          { id: 'volume', label: 'Transaction Volume' },
          { id: 'revenue', label: 'Revenue Trends' },
          { id: 'distribution', label: 'Transaction Type Distribution' }
        ],
        timeRanges: [
          { id: '30d', label: 'Last 30 Days' },
          { id: '90d', label: 'Last 90 Days' },
          { id: '12m', label: 'Last 12 Months' }
        ],
        defaults: {
          startDate: thirtyDaysAgo.toISOString(),
          endDate: now.toISOString(),
          interval: 'month'
        }
      }, 'Report filters retrieved successfully')
    }

    // GET /admin-reports/overview
    if (req.method === 'GET' && segments.length === 1 && (segments[0] === 'overview' || segments[0] === 'summary')) {
      const defaultEnd = new Date()
      const defaultStart = new Date(defaultEnd)
      defaultStart.setDate(defaultStart.getDate() - 30)

      const startDate = parseDate(url.searchParams.get('startDate'), defaultStart)
      const endDate = parseDate(url.searchParams.get('endDate'), defaultEnd)
      const interval = parseInterval(url.searchParams.get('interval'))

      const [{ data: volumeData, error: volumeError }, { data: revenueData, error: revenueError }, { data: distributionData, error: distributionError }] = await Promise.all([
        supabaseAdmin.rpc('admin_reports_transaction_volume', {
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString(),
          interval_unit: interval
        }),
        supabaseAdmin.rpc('admin_reports_revenue_trends', {
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString()
        }),
        supabaseAdmin.rpc('admin_reports_type_distribution', {
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString()
        })
      ])

      if (volumeError) {
        console.error('admin_reports_transaction_volume error:', volumeError)
        return createErrorResponse('Failed to fetch transaction volume', 500, volumeError.message)
      }

      if (revenueError) {
        console.error('admin_reports_revenue_trends error:', revenueError)
        return createErrorResponse('Failed to fetch revenue trends', 500, revenueError.message)
      }

      if (distributionError) {
        console.error('admin_reports_type_distribution error:', distributionError)
        return createErrorResponse('Failed to fetch transaction type distribution', 500, distributionError.message)
      }

      const transactionVolume = (volumeData ?? []).map((row) => ({
        periodStart: row.period_start,
        periodEnd: row.period_end,
        count: Number(row.transaction_count ?? 0),
        amount: Number(row.total_amount ?? 0)
      }))

      const revenueTrends = (revenueData ?? []).map((row) => ({
        periodStart: row.period_start,
        totalRevenue: Number(row.total_revenue ?? 0)
      }))

      const typeDistribution = (distributionData ?? []).map((row) => ({
        transactionType: row.transaction_type,
        count: Number(row.transaction_count ?? 0),
        amount: Number(row.total_amount ?? 0)
      }))

      const totals = transactionVolume.reduce(
        (acc, item) => {
          acc.transactions += item.count
          acc.revenue += item.amount
          return acc
        },
        { transactions: 0, revenue: 0 }
      )

      const response: ReportsOverviewResponse = {
        period: {
          startDate: startDate.toISOString(),
          endDate: endDate.toISOString(),
          interval
        },
        transactionVolume,
        revenueTrends,
        typeDistribution,
        totals
      }

      return createSuccessResponse(response, 'Reports overview retrieved successfully')
    }

    // GET /admin-reports/export (placeholder returning signed URL or message)
    if (req.method === 'GET' && segments.length === 1 && segments[0] === 'export') {
      return createSuccessResponse({
        message: 'Export generation is not yet implemented. Call this endpoint once export logic is added.'
      }, 'Export endpoint placeholder')
    }

    return createErrorResponse('Not found', 404)
  } catch (error) {
    console.error('Admin reports error:', error)
    return createErrorResponse('Internal server error', 500, error instanceof Error ? error.message : String(error))
  }
})
