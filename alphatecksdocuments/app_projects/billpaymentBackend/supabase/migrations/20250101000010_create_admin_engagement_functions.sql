CREATE OR REPLACE FUNCTION public.admin_engagement_new_users(
    start_date timestamptz,
    end_date timestamptz,
    interval_unit text DEFAULT 'month'
)
RETURNS TABLE (
    period_start timestamptz,
    period_end timestamptz,
    new_users bigint
) AS $$
BEGIN
    RETURN QUERY
    WITH buckets AS (
        SELECT generate_series(start_date, end_date,
            CASE interval_unit
                WHEN 'day' THEN interval '1 day'
                WHEN 'week' THEN interval '1 week'
                ELSE interval '1 month'
            END
        ) AS bucket_start
    )
    SELECT
        b.bucket_start AS period_start,
        b.bucket_start +
            CASE interval_unit
                WHEN 'day' THEN interval '1 day'
                WHEN 'week' THEN interval '1 week'
                ELSE interval '1 month'
            END AS period_end,
        COUNT(p.id) AS new_users
    FROM buckets b
    LEFT JOIN public.profiles p
      ON p.created_at >= b.bucket_start
     AND p.created_at < b.bucket_start +
            CASE interval_unit
                WHEN 'day' THEN interval '1 day'
                WHEN 'week' THEN interval '1 week'
                ELSE interval '1 month'
            END
    GROUP BY b.bucket_start
    ORDER BY b.bucket_start;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_engagement_active_users(
    start_date timestamptz,
    end_date timestamptz,
    interval_unit text DEFAULT 'month'
)
RETURNS TABLE (
    period_start timestamptz,
    period_end timestamptz,
    active_users bigint
) AS $$
BEGIN
    RETURN QUERY
    WITH buckets AS (
        SELECT generate_series(start_date, end_date,
            CASE interval_unit
                WHEN 'day' THEN interval '1 day'
                WHEN 'week' THEN interval '1 week'
                ELSE interval '1 month'
            END
        ) AS bucket_start
    )
    SELECT
        b.bucket_start AS period_start,
        b.bucket_start +
            CASE interval_unit
                WHEN 'day' THEN interval '1 day'
                WHEN 'week' THEN interval '1 week'
                ELSE interval '1 month'
            END AS period_end,
        COUNT(DISTINCT wt.user_id) AS active_users
    FROM buckets b
    LEFT JOIN public.wallet_transactions wt
      ON wt.created_at >= b.bucket_start
     AND wt.created_at < b.bucket_start +
            CASE interval_unit
                WHEN 'day' THEN interval '1 day'
                WHEN 'week' THEN interval '1 week'
                ELSE interval '1 month'
            END
    GROUP BY b.bucket_start
    ORDER BY b.bucket_start;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_service_performance_revenue(
    start_date timestamptz,
    end_date timestamptz,
    limit_count integer DEFAULT 5
)
RETURNS TABLE (
    service_name text,
    total_revenue numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        wt.transaction_type::text AS service_name,
        COALESCE(SUM(ABS(wt.amount)), 0) AS total_revenue
    FROM public.wallet_transactions wt
    WHERE wt.type = 'credit'
      AND wt.created_at >= start_date
      AND wt.created_at <= end_date
    GROUP BY wt.transaction_type
    ORDER BY total_revenue DESC
    LIMIT COALESCE(limit_count, 5);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_service_performance_volume(
    start_date timestamptz,
    end_date timestamptz,
    limit_count integer DEFAULT 5
)
RETURNS TABLE (
    service_name text,
    total_transactions bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        wt.transaction_type::text AS service_name,
        COUNT(*) AS total_transactions
    FROM public.wallet_transactions wt
    WHERE wt.created_at >= start_date
      AND wt.created_at <= end_date
    GROUP BY wt.transaction_type
    ORDER BY total_transactions DESC
    LIMIT COALESCE(limit_count, 5);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION public.admin_engagement_new_users(timestamptz, timestamptz, text) SET search_path = public;
ALTER FUNCTION public.admin_engagement_active_users(timestamptz, timestamptz, text) SET search_path = public;
ALTER FUNCTION public.admin_service_performance_revenue(timestamptz, timestamptz, integer) SET search_path = public;
ALTER FUNCTION public.admin_service_performance_volume(timestamptz, timestamptz, integer) SET search_path = public;

GRANT EXECUTE ON FUNCTION public.admin_engagement_new_users(timestamptz, timestamptz, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_engagement_active_users(timestamptz, timestamptz, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_service_performance_revenue(timestamptz, timestamptz, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_service_performance_volume(timestamptz, timestamptz, integer) TO service_role;



