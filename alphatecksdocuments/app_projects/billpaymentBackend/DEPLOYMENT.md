# Deployment Configuration

## Prerequisites for Deployment

1. **Docker Desktop** - Required for local development
   - Install Docker Desktop from https://www.docker.com/products/docker-desktop/
   - Start Docker Desktop before running `supabase start`

2. **Supabase Project** - Create a project at https://supabase.com/dashboard
   - Note down your project reference ID
   - Get your API keys from Settings > API

## Deployment Steps

### 1. Create Supabase Project
1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Choose your organization
4. Enter project name: "bill-payment-backend"
5. Set a strong database password
6. Choose a region close to your users
7. Click "Create new project"

### 2. Link Local Project to Supabase
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

### 3. Deploy Database Schema
```bash
supabase db push
```

### 4. Deploy Edge Functions
```bash
supabase functions deploy bill-payment
```

### 5. Set Production Environment Variables
```bash
supabase secrets set SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
supabase secrets set SUPABASE_ANON_KEY=YOUR_ANON_KEY
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
```

### 6. Test Deployment
```bash
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/bill-payment' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "amount": 100.00,
    "billType": "electricity",
    "accountNumber": "TEST123456"
  }'
```

## Environment Variables Reference

### Required Variables
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` - Your Supabase service role key

### Optional Variables
- `OPENAI_API_KEY` - For Supabase AI features
- `SENDGRID_API_KEY` - For email notifications
- `SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN` - For SMS notifications

## Local Development Setup

1. **Start Docker Desktop**
2. **Start Supabase locally:**
   ```bash
   supabase start
   ```
3. **Access services:**
   - API: http://localhost:54321
   - Studio: http://localhost:54323
   - Database: localhost:54322

## Troubleshooting

### Docker Issues
- Ensure Docker Desktop is running
- Check Docker daemon status: `docker ps`
- Restart Docker Desktop if needed

### Supabase CLI Issues
- Update CLI: `brew upgrade supabase`
- Check version: `supabase --version`
- Debug mode: `supabase start --debug`

### Function Deployment Issues
- Check function logs: `supabase functions logs bill-payment`
- Verify function syntax: `supabase functions serve bill-payment`
- Test locally before deployment





