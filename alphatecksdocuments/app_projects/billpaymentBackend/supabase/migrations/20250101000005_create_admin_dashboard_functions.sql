CREATE OR REPLACE FUNCTION public.admin_dashboard_overview(current_start timestamptz, previous_start timestamptz)
RETURNS TABLE (
    total_transactions_current bigint,
    total_transactions_previous bigint,
    total_transactions_all bigint,
    revenue_current numeric,
    revenue_previous numeric,
    revenue_all numeric,
    active_users_current bigint,
    active_users_previous bigint,
    active_users_all bigint,
    new_users_current bigint,
    new_users_previous bigint,
    new_users_all bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM public.wallet_transactions WHERE created_at >= current_start) AS total_transactions_current,
        (SELECT COUNT(*) FROM public.wallet_transactions WHERE created_at >= previous_start AND created_at < current_start) AS total_transactions_previous,
        (SELECT COUNT(*) FROM public.wallet_transactions) AS total_transactions_all,
        (SELECT COALESCE(SUM(amount), 0) FROM public.wallet_transactions WHERE type = 'credit' AND created_at >= current_start) AS revenue_current,
        (SELECT COALESCE(SUM(amount), 0) FROM public.wallet_transactions WHERE type = 'credit' AND created_at >= previous_start AND created_at < current_start) AS revenue_previous,
        (SELECT COALESCE(SUM(amount), 0) FROM public.wallet_transactions WHERE type = 'credit') AS revenue_all,
        (SELECT COUNT(DISTINCT user_id) FROM public.wallet_transactions WHERE created_at >= current_start) AS active_users_current,
        (SELECT COUNT(DISTINCT user_id) FROM public.wallet_transactions WHERE created_at >= previous_start AND created_at < current_start) AS active_users_previous,
        (SELECT COUNT(DISTINCT user_id) FROM public.wallet_transactions) AS active_users_all,
        (SELECT COUNT(*) FROM public.profiles WHERE created_at >= current_start) AS new_users_current,
        (SELECT COUNT(*) FROM public.profiles WHERE created_at >= previous_start AND created_at < current_start) AS new_users_previous,
        (SELECT COUNT(*) FROM public.profiles) AS new_users_all;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION public.admin_dashboard_overview(timestamptz, timestamptz) SET search_path = public;
GRANT EXECUTE ON FUNCTION public.admin_dashboard_overview(timestamptz, timestamptz) TO service_role;

CREATE OR REPLACE FUNCTION public.admin_dashboard_recent_activity(limit_count integer DEFAULT 10)
RETURNS TABLE (
    id uuid,
    user_name text,
    transaction_type text,
    amount numeric,
    status text,
    created_at timestamptz,
    source text
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        wt.id::uuid,
        COALESCE(p.first_name || ' ' || p.last_name, 'Unknown User')::text AS user_name,
        wt.transaction_type::text,
        ABS(wt.amount)::numeric AS amount,
        CASE WHEN wt.type = 'credit' THEN 'Completed' ELSE 'Debited' END::text AS status,
        wt.created_at::timestamptz,
        'wallet_transaction'::text AS source
    FROM public.wallet_transactions wt
    LEFT JOIN public.profiles p ON p.id = wt.user_id

    UNION ALL

    SELECT
        bp.id::uuid,
        ('Account ' || bp.account_number)::text AS user_name,
        bp.bill_type::text AS transaction_type,
        bp.amount::numeric AS amount,
        INITCAP(bp.status)::text AS status,
        bp.created_at::timestamptz,
        'bill_payment'::text AS source
    FROM public.bill_payments bp
    ORDER BY created_at DESC
    LIMIT COALESCE(limit_count, 10);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION public.admin_dashboard_recent_activity(integer) SET search_path = public;
GRANT EXECUTE ON FUNCTION public.admin_dashboard_recent_activity(integer) TO service_role;
