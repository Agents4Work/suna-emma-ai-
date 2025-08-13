# Ngrok Setup for Suna Development

This guide helps you expose your local Suna development environment to the internet using ngrok, which is required for proper functionality.

## Why Ngrok?

Suna requires internet connectivity even when running locally because it:
- Needs to receive webhooks from external services
- Requires OAuth callbacks from providers like Google, GitHub, Slack
- Uses external APIs that need to callback to your application

## Quick Setup

### 1. Install ngrok
Download and install ngrok from https://ngrok.com/download

### 2. Get your authtoken
1. Sign up at https://ngrok.com
2. Get your authtoken from https://dashboard.ngrok.com/get-started/your-authtoken

### 3. Configure ngrok
Copy the provided ngrok.yml to your ngrok config directory:

**Linux/Mac:**
```bash
mkdir -p ~/.config/ngrok
cp ngrok.yml ~/.config/ngrok/ngrok.yml
```

**Windows:**
```cmd
mkdir %USERPROFILE%\.ngrok2
copy ngrok.yml %USERPROFILE%\.ngrok2\ngrok.yml
```

Edit the config file and replace `YOUR_AUTHTOKEN` with your actual token.

### 4. Start everything automatically
From the Suna project root:

```bash
./scripts/start-ngrok.sh
```

This script will:
- Start ngrok tunnels for frontend (port 3000) and backend (port 8000)
- Automatically update your environment files with the tunnel URLs
- Configure CORS settings for the backend

### 5. Start your development servers
After ngrok is configured:

```bash
# Terminal 1: Start backend
cd backend
python -m uvicorn api:app --reload --host 0.0.0.0 --port 8000

# Terminal 2: Start frontend  
cd frontend
npm run dev
```

## Manual Setup

If you prefer manual configuration:

### 1. Start ngrok tunnels
```bash
ngrok start --all
```

### 2. Update environment files
Run the setup script to automatically update your .env files:
```bash
python3 scripts/setup-ngrok.py
```

Or manually update:

**frontend/.env.local:**
```env
NEXT_PUBLIC_URL=https://your-frontend-url.ngrok-free.app
NEXT_PUBLIC_APP_URL=https://your-frontend-url.ngrok-free.app
NEXT_PUBLIC_BACKEND_URL=https://your-backend-url.ngrok-free.app/api
BACKEND_URL=https://your-backend-url.ngrok-free.app
```

**backend/.env:**
```env
CORS_ALLOWED_ORIGINS=https://your-frontend-url.ngrok-free.app
WEBHOOK_BASE_URL=https://your-backend-url.ngrok-free.app
NEXT_PUBLIC_URL=https://your-frontend-url.ngrok-free.app
```

## OAuth Configuration

Update your OAuth providers with the new URLs:

### Supabase
In your Supabase dashboard → Authentication → URL Configuration:
- **Site URL:** `https://your-frontend-url.ngrok-free.app`
- **Redirect URLs:** Add:
  - `https://your-frontend-url.ngrok-free.app/auth/callback`
  - `https://your-frontend-url.ngrok-free.app/auth/github-popup`

### Slack App (if using)
- **Redirect URL:** `https://your-frontend-url.ngrok-free.app/api/integrations/slack/callback`
- Update `SLACK_REDIRECT_URI` in backend/.env

### Discord/Teams (if using)
- **Discord:** `https://your-frontend-url.ngrok-free.app/api/integrations/discord/callback`
- **Teams:** `https://your-frontend-url.ngrok-free.app/api/integrations/teams/callback`

## Testing

1. **Backend health check:**
   ```bash
   curl https://your-backend-url.ngrok-free.app/api/health
   ```

2. **Frontend access:**
   Open `https://your-frontend-url.ngrok-free.app` in your browser

3. **Check ngrok dashboard:**
   Visit http://localhost:4040 to see tunnel status and traffic

## Troubleshooting

### CORS Errors
- Ensure `CORS_ALLOWED_ORIGINS` in backend/.env includes your frontend ngrok URL
- Restart the backend after changing environment variables

### Tunnel URLs Change
- Free ngrok accounts get new URLs each time you restart
- Run `python3 scripts/setup-ngrok.py` to update configs with new URLs
- Consider upgrading to ngrok Pro for reserved domains

### OAuth Failures
- Double-check redirect URLs in your OAuth provider settings
- Ensure they match your current ngrok frontend URL exactly

### Webhook Issues
- Verify `WEBHOOK_BASE_URL` points to your backend ngrok URL
- Check that external services can reach your webhook endpoints

## Tips

- **Reserved domains:** Upgrade to ngrok Pro to get consistent URLs
- **Multiple developers:** Each developer needs their own ngrok tunnels
- **Production:** This setup is for development only - use proper hosting for production
- **Security:** Ngrok free tier shows a warning page - click "Visit Site" to continue

## Scripts Reference

- `./scripts/start-ngrok.sh` - Start ngrok and auto-configure
- `python3 scripts/setup-ngrok.py` - Update environment files with current tunnel URLs
- `pkill ngrok` - Stop all ngrok processes
