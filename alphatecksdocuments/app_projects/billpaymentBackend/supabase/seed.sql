-- Seed data for bill_payments table
INSERT INTO public.bill_payments (transaction_id, amount, bill_type, account_number, description, status) VALUES
('TXN_DEMO_001', 150.00, 'electricity', 'ELC123456789', 'Monthly electricity bill payment', 'completed'),
('TXN_DEMO_002', 75.50, 'water', 'WTR987654321', 'Water utility payment', 'completed'),
('TXN_DEMO_003', 200.00, 'internet', 'INT456789123', 'Internet service payment', 'pending'),
('TXN_DEMO_004', 45.00, 'phone', 'PHN789123456', 'Mobile phone bill', 'failed'),
('TXN_DEMO_005', 300.00, 'rent', 'RNT321654987', 'Monthly rent payment', 'completed');





