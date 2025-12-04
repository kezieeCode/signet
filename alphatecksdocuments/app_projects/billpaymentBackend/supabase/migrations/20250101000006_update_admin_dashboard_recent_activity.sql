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
