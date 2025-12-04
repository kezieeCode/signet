-- Create Paystack dedicated virtual accounts table for wallet funding
-- Migration: 20240101000003_create_paystack_accounts.sql

CREATE TABLE IF NOT EXISTS public.paystack_dedicated_accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    account_name VARCHAR(200) NOT NULL,
    paystack_customer_code VARCHAR(100),
    paystack_customer_id VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_paystack_accounts_user_id ON public.paystack_dedicated_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_paystack_accounts_account_number ON public.paystack_dedicated_accounts(account_number);
CREATE INDEX IF NOT EXISTS idx_paystack_accounts_paystack_customer_code ON public.paystack_dedicated_accounts(paystack_customer_code);
CREATE INDEX IF NOT EXISTS idx_paystack_accounts_is_active ON public.paystack_dedicated_accounts(is_active);

-- Create updated_at trigger
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'update_paystack_accounts_updated_at'
    ) THEN
        CREATE TRIGGER update_paystack_accounts_updated_at
            BEFORE UPDATE ON public.paystack_dedicated_accounts
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Enable Row Level Security (RLS)
ALTER TABLE public.paystack_dedicated_accounts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own dedicated accounts'
    ) THEN
        CREATE POLICY "Users can view their own dedicated accounts" ON public.paystack_dedicated_accounts
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own dedicated accounts'
    ) THEN
        CREATE POLICY "Users can insert their own dedicated accounts" ON public.paystack_dedicated_accounts
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own dedicated accounts'
    ) THEN
        CREATE POLICY "Users can update their own dedicated accounts" ON public.paystack_dedicated_accounts
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Grant necessary permissions
GRANT ALL ON public.paystack_dedicated_accounts TO authenticated;
GRANT ALL ON public.paystack_dedicated_accounts TO service_role;
