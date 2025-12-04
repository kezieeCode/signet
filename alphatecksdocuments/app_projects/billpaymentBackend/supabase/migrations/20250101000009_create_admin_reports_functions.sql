CREATE OR REPLACE FUNCTION public.admin_reports_transaction_volume(
    start_date timestamptz,
    end_date timestamptz,
    interval_unit text DEFAULT 'month'
)
RETURNS TABLE (
    period_start timestamptz,
    period_end timestamptz,
    transaction_count bigint,
    total_amount numeric
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
        COUNT(wt.id) AS transaction_count,
        COALESCE(SUM(wt.amount), 0) AS total_amount
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

CREATE OR REPLACE FUNCTION public.admin_reports_revenue_trends(
    start_date timestamptz,
    end_date timestamptz
)
RETURNS TABLE (
    period_start timestamptz,
    total_revenue numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        date_trunc('month', created_at) AS period_start,
        COALESCE(SUM(amount), 0) AS total_revenue
    FROM public.wallet_transactions
    WHERE type = 'credit'
      AND created_at >= start_date
      AND created_at <= end_date
    GROUP BY date_trunc('month', created_at)
    ORDER BY period_start;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_reports_type_distribution(
    start_date timestamptz,
    end_date timestamptz
)
RETURNS TABLE (
    transaction_type text,
    transaction_count bigint,
    total_amount numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        wt.transaction_type::text,
        COUNT(*) AS transaction_count,
        COALESCE(SUM(ABS(wt.amount)), 0) AS total_amount
    FROM public.wallet_transactions wt
    WHERE wt.created_at >= start_date
      AND wt.created_at <= end_date
    GROUP BY wt.transaction_type
    ORDER BY transaction_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION public.admin_reports_transaction_volume(timestamptz, timestamptz, text) SET search_path = public;
ALTER FUNCTION public.admin_reports_revenue_trends(timestamptz, timestamptz) SET search_path = public;
ALTER FUNCTION public.admin_reports_type_distribution(timestamptz, timestamptz) SET search_path = public;

GRANT EXECUTE ON FUNCTION public.admin_reports_transaction_volume(timestamptz, timestamptz, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_reports_revenue_trends(timestamptz, timestamptz) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_reports_type_distribution(timestamptz, timestamptz) TO service_role;
