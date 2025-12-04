CREATE OR REPLACE FUNCTION public.admin_transactions_query(
    search_text text DEFAULT NULL,
    filter_type text DEFAULT NULL,
    filter_status text DEFAULT NULL,
    filter_user uuid DEFAULT NULL,
    start_date timestamptz DEFAULT NULL,
    end_date timestamptz DEFAULT NULL,
    limit_count integer DEFAULT 25,
    offset_count integer DEFAULT 0
)
RETURNS TABLE (
    transaction_id text,
    user_id uuid,
    user_name text,
    transaction_type text,
    amount numeric,
    status text,
    created_at timestamptz,
    source text
) AS $$
BEGIN
    RETURN QUERY
    WITH combined AS (
        SELECT
            COALESCE(wt.reference_id, 'WTX-' || wt.id::text)::text AS transaction_id,
            wt.user_id,
            COALESCE(p.first_name || ' ' || p.last_name, p.username, 'Unknown User')::text AS user_name,
            wt.transaction_type::text AS transaction_type,
            ABS(wt.amount)::numeric AS amount,
            CASE WHEN wt.type = 'credit' THEN 'Completed' ELSE 'Debited' END::text AS status,
            wt.created_at::timestamptz AS created_at,
            'wallet_transaction'::text AS source
        FROM public.wallet_transactions wt
        LEFT JOIN public.profiles p ON p.id = wt.user_id

        UNION ALL

        SELECT
            bp.transaction_id::text,
            da.user_id,
            COALESCE(p.first_name || ' ' || p.last_name, p.username, 'Unknown User')::text AS user_name,
            bp.bill_type::text AS transaction_type,
            bp.amount::numeric AS amount,
            INITCAP(bp.status)::text AS status,
            bp.created_at::timestamptz AS created_at,
            'bill_payment'::text AS source
        FROM public.bill_payments bp
        LEFT JOIN public.paystack_dedicated_accounts da ON da.account_number = bp.account_number
        LEFT JOIN public.profiles p ON p.id = da.user_id
    )
    SELECT *
    FROM combined c
    WHERE (search_text IS NULL OR c.transaction_id ILIKE '%' || search_text || '%' OR c.user_name ILIKE '%' || search_text || '%' OR c.transaction_type ILIKE '%' || search_text || '%')
      AND (filter_type IS NULL OR LOWER(c.transaction_type) = LOWER(filter_type))
      AND (filter_status IS NULL OR LOWER(c.status) = LOWER(filter_status))
      AND (filter_user IS NULL OR c.user_id = filter_user)
      AND (start_date IS NULL OR c.created_at >= start_date)
      AND (end_date IS NULL OR c.created_at <= end_date)
    ORDER BY c.created_at DESC
    LIMIT COALESCE(limit_count, 25)
    OFFSET COALESCE(offset_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_transactions_count(
    search_text text DEFAULT NULL,
    filter_type text DEFAULT NULL,
    filter_status text DEFAULT NULL,
    filter_user uuid DEFAULT NULL,
    start_date timestamptz DEFAULT NULL,
    end_date timestamptz DEFAULT NULL
)
RETURNS bigint AS $$
BEGIN
    RETURN (
        WITH combined AS (
            SELECT
                COALESCE(wt.reference_id, 'WTX-' || wt.id::text)::text AS transaction_id,
                wt.user_id,
                COALESCE(p.first_name || ' ' || p.last_name, p.username, 'Unknown User')::text AS user_name,
                wt.transaction_type::text AS transaction_type,
                CASE WHEN wt.type = 'credit' THEN 'Completed' ELSE 'Debited' END::text AS status,
                wt.created_at::timestamptz AS created_at
            FROM public.wallet_transactions wt
            LEFT JOIN public.profiles p ON p.id = wt.user_id

            UNION ALL

            SELECT
                bp.transaction_id::text,
                da.user_id,
                COALESCE(p.first_name || ' ' || p.last_name, p.username, 'Unknown User')::text AS user_name,
                bp.bill_type::text AS transaction_type,
                INITCAP(bp.status)::text AS status,
                bp.created_at::timestamptz AS created_at
            FROM public.bill_payments bp
            LEFT JOIN public.paystack_dedicated_accounts da ON da.account_number = bp.account_number
            LEFT JOIN public.profiles p ON p.id = da.user_id
        )
        SELECT COUNT(*)
        FROM combined c
        WHERE (search_text IS NULL OR c.transaction_id ILIKE '%' || search_text || '%' OR c.user_name ILIKE '%' || search_text || '%' OR c.transaction_type ILIKE '%' || search_text || '%')
          AND (filter_type IS NULL OR LOWER(c.transaction_type) = LOWER(filter_type))
          AND (filter_status IS NULL OR LOWER(c.status) = LOWER(filter_status))
          AND (filter_user IS NULL OR c.user_id = filter_user)
          AND (start_date IS NULL OR c.created_at >= start_date)
          AND (end_date IS NULL OR c.created_at <= end_date)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_transactions_filter_options()
RETURNS TABLE (
    transaction_types text[],
    statuses text[],
    users jsonb
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (
            SELECT array_agg(DISTINCT t.transaction_type ORDER BY t.transaction_type)
            FROM (
                SELECT transaction_type::text FROM public.wallet_transactions WHERE transaction_type IS NOT NULL
                UNION
                SELECT bill_type::text FROM public.bill_payments WHERE bill_type IS NOT NULL
            ) t
        )::text[],
        (
            SELECT array_agg(DISTINCT s.status ORDER BY s.status)
            FROM (
                SELECT CASE WHEN type = 'credit' THEN 'Completed' ELSE 'Debited' END::text AS status FROM public.wallet_transactions
                UNION
                SELECT INITCAP(status)::text FROM public.bill_payments
            ) s
        )::text[],
        (
            SELECT COALESCE(jsonb_agg(jsonb_build_object(
                'id', u.id,
                'name', u.name,
                'email', u.email
            ) ORDER BY u.name), '[]'::jsonb)
            FROM (
                SELECT DISTINCT p.id,
                    COALESCE(p.first_name || ' ' || p.last_name, p.username, 'Unknown User') AS name,
                    au.email
                FROM public.profiles p
                LEFT JOIN auth.users au ON au.id = p.id
            ) u
        ) AS users;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION public.admin_transactions_query(text, text, text, uuid, timestamptz, timestamptz, integer, integer) SET search_path = public;
ALTER FUNCTION public.admin_transactions_count(text, text, text, uuid, timestamptz, timestamptz) SET search_path = public;
ALTER FUNCTION public.admin_transactions_filter_options() SET search_path = public;

GRANT EXECUTE ON FUNCTION public.admin_transactions_query(text, text, text, uuid, timestamptz, timestamptz, integer, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_transactions_count(text, text, text, uuid, timestamptz, timestamptz) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_transactions_filter_options() TO service_role;
