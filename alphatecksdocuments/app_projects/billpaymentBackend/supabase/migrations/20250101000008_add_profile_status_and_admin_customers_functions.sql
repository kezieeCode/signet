-- Add status column to profiles for admin user management
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS status TEXT;

UPDATE public.profiles
SET status = COALESCE(status, 'active');

UPDATE public.profiles
SET status = LOWER(status);

ALTER TABLE public.profiles
ALTER COLUMN status SET DEFAULT 'active';

ALTER TABLE public.profiles
ALTER COLUMN status SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage
        WHERE table_schema = 'public'
          AND table_name = 'profiles'
          AND constraint_name = 'profiles_status_check'
    ) THEN
        ALTER TABLE public.profiles
        ADD CONSTRAINT profiles_status_check CHECK (status IN ('active', 'suspended'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);

-- SQL helpers for admin customers listing
CREATE OR REPLACE FUNCTION public.admin_customers_query(
    search_text text DEFAULT NULL,
    status_filter text DEFAULT NULL,
    start_date timestamptz DEFAULT NULL,
    end_date timestamptz DEFAULT NULL,
    sort_direction text DEFAULT 'desc',
    limit_count integer DEFAULT 25,
    offset_count integer DEFAULT 0
)
RETURNS TABLE (
    user_id uuid,
    customer_id text,
    full_name text,
    email text,
    phone text,
    status text,
    created_at timestamptz
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.id::text AS customer_id,
        COALESCE(p.first_name || ' ' || p.last_name, p.username, 'Unknown User')::text AS full_name,
        au.email::text,
        p.phone::text,
        p.status::text,
        p.created_at::timestamptz
    FROM public.profiles p
    LEFT JOIN auth.users au ON au.id = p.id
    WHERE (search_text IS NULL OR
           p.username ILIKE '%' || search_text || '%' OR
           (p.first_name || ' ' || p.last_name) ILIKE '%' || search_text || '%' OR
           au.email ILIKE '%' || search_text || '%' OR
           p.phone ILIKE '%' || search_text || '%')
      AND (status_filter IS NULL OR LOWER(p.status) = LOWER(status_filter))
      AND (start_date IS NULL OR p.created_at >= start_date)
      AND (end_date IS NULL OR p.created_at <= end_date)
    ORDER BY
        CASE WHEN LOWER(sort_direction) = 'asc' THEN p.created_at END ASC,
        CASE WHEN LOWER(sort_direction) <> 'asc' THEN p.created_at END DESC
    LIMIT COALESCE(limit_count, 25)
    OFFSET COALESCE(offset_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_customers_count(
    search_text text DEFAULT NULL,
    status_filter text DEFAULT NULL,
    start_date timestamptz DEFAULT NULL,
    end_date timestamptz DEFAULT NULL
)
RETURNS bigint AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM public.profiles p
        LEFT JOIN auth.users au ON au.id = p.id
        WHERE (search_text IS NULL OR
               p.username ILIKE '%' || search_text || '%' OR
               (p.first_name || ' ' || p.last_name) ILIKE '%' || search_text || '%' OR
               au.email ILIKE '%' || search_text || '%' OR
               p.phone ILIKE '%' || search_text || '%')
          AND (status_filter IS NULL OR LOWER(p.status) = LOWER(status_filter))
          AND (start_date IS NULL OR p.created_at >= start_date)
          AND (end_date IS NULL OR p.created_at <= end_date)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_customers_filter_options()
RETURNS TABLE (
    statuses text[],
    registration_dates jsonb
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ARRAY['active', 'suspended']::text[] AS statuses,
        jsonb_build_object(
            'min', (SELECT MIN(created_at) FROM public.profiles),
            'max', (SELECT MAX(created_at) FROM public.profiles)
        ) AS registration_dates;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER FUNCTION public.admin_customers_query(text, text, timestamptz, timestamptz, text, integer, integer) SET search_path = public;
ALTER FUNCTION public.admin_customers_count(text, text, timestamptz, timestamptz) SET search_path = public;
ALTER FUNCTION public.admin_customers_filter_options() SET search_path = public;

GRANT EXECUTE ON FUNCTION public.admin_customers_query(text, text, timestamptz, timestamptz, text, integer, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_customers_count(text, text, timestamptz, timestamptz) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_customers_filter_options() TO service_role;
