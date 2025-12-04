-- Create bill_payments table
CREATE TABLE IF NOT EXISTS public.bill_payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_id VARCHAR(255) UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    bill_type VARCHAR(100) NOT NULL,
    account_number VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bill_payments_transaction_id ON public.bill_payments(transaction_id);
CREATE INDEX IF NOT EXISTS idx_bill_payments_status ON public.bill_payments(status);
CREATE INDEX IF NOT EXISTS idx_bill_payments_created_at ON public.bill_payments(created_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_bill_payments_updated_at 
    BEFORE UPDATE ON public.bill_payments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE public.bill_payments ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users
CREATE POLICY "Users can view their own payments" ON public.bill_payments
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert their own payments" ON public.bill_payments
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update their own payments" ON public.bill_payments
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Grant necessary permissions
GRANT ALL ON public.bill_payments TO authenticated;
GRANT ALL ON public.bill_payments TO service_role;





