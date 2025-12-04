# Bill Payment Backend - Supabase TypeScript Setup

This project is a bill payment backend built with Supabase and TypeScript, designed for deployment using the Supabase CLI.

## Project Structure

```
billpaymentBackend/
├── supabase/
│   ├── functions/
│   │   └── bill-payment/
│   │       └── index.ts          # TypeScript Edge Function
│   ├── migrations/
│   │   └── 20240101000001_create_bill_payments_table.sql
│   ├── seed.sql                  # Database seed data
│   └── config.toml              # Supabase configuration
├── types/                       # TypeScript type definitions
├── package.json                 # Node.js dependencies
├── tsconfig.json               # TypeScript configuration
└── env.example                 # Environment variables template
```

## Prerequisites

1. **Supabase CLI** (already installed via Homebrew)
2. **Node.js** (for local development)
3. **Supabase Account** (for deployment)

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Configuration

Copy the environment template and configure your variables:

```bash
cp env.example .env
```

Update `.env` with your actual Supabase project values.

### 3. Local Development

Start the local Supabase development environment:

```bash
npm run dev
```

This will:
- Start Supabase services locally
- Run database migrations
- Seed the database
- Start Edge Functions runtime

### 4. Generate TypeScript Types

Generate TypeScript types from your database schema:

```bash
npm run types
```

## Deployment

### 1. Link to Supabase Project

```bash
supabase link --project-ref your-project-ref
```

### 2. Deploy Database Migrations

```bash
supabase db push
```

### 3. Deploy Edge Functions

Deploy all functions:
```bash
npm run deploy-all
```

Deploy specific function:
```bash
supabase functions deploy bill-payment
```

### 4. Set Environment Variables

Set environment variables for your deployed functions:

```bash
supabase secrets set SUPABASE_URL=https://your-project-ref.supabase.co
supabase secrets set SUPABASE_ANON_KEY=your-anon-key
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## API Usage

### Bill Payment Endpoint

**POST** `/functions/v1/bill-payment`

Request body:
```json
{
  "amount": 150.00,
  "billType": "electricity",
  "accountNumber": "ELC123456789",
  "description": "Monthly electricity bill payment"
}
```

Response:
```json
{
  "success": true,
  "transactionId": "TXN_1703123456789_abc123def",
  "message": "Payment processed successfully"
}
```

## Available Scripts

- `npm run dev` - Start local development environment
- `npm run stop` - Stop local Supabase services
- `npm run reset` - Reset local database and run migrations
- `npm run deploy` - Deploy Edge Functions
- `npm run deploy-all` - Deploy all functions without JWT verification
- `npm run logs` - View function logs
- `npm run types` - Generate TypeScript types from database

## Database Schema

The `bill_payments` table includes:
- `id` - UUID primary key
- `transaction_id` - Unique transaction identifier
- `amount` - Payment amount (decimal)
- `bill_type` - Type of bill (electricity, water, etc.)
- `account_number` - Account number for the bill
- `description` - Optional description
- `status` - Payment status (pending, completed, failed, cancelled)
- `created_at` - Timestamp when record was created
- `updated_at` - Timestamp when record was last updated

## Security Features

- Row Level Security (RLS) enabled
- Authentication required for all operations
- Input validation and sanitization
- CORS headers configured
- Error handling and logging

## Next Steps

1. Integrate with actual payment gateways
2. Add user authentication and authorization
3. Implement payment history and reporting
4. Add email notifications
5. Set up monitoring and logging
6. Add unit tests for Edge Functions





