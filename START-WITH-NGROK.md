# 🚀 EMMA AI - Always Run with Ngrok

This guide ensures EMMA AI always runs with ngrok tunneling for internet accessibility.

## ⚡ Quick Start

**One command to start everything:**

```bash
./start-app.sh
```

This script automatically:
- ✅ Starts ngrok tunnels for frontend (port 3000) and backend (port 8000)
- ✅ Configures environment variables with ngrok URLs
- ✅ Starts the backend with uv
- ✅ Starts the frontend with Node 20
- ✅ Monitors all services and restarts if needed
- ✅ Provides live URLs for internet access

## 📋 Prerequisites

Make sure you have these installed:

1. **Ngrok** - Download from https://ngrok.com/download
2. **Node.js 18+** - The script will use Node 20 if available
3. **Python 3** - For the backend
4. **uv** - Python package manager (https://docs.astral.sh/uv/)

## 🔧 First Time Setup

1. **Get ngrok authtoken:**
   - Sign up at https://ngrok.com
   - Get your token from https://dashboard.ngrok.com/get-started/your-authtoken

2. **Configure ngrok:**
   ```bash
   ngrok config add-authtoken YOUR_TOKEN_HERE
   ```

3. **Run the app:**
   ```bash
   ./start-app.sh
   ```

## 🌐 What You'll Get

After running `./start-app.sh`, you'll see:

```
🎉 EMMA AI is now running!

✅ Frontend: https://abc123.ngrok-free.app
✅ Backend:  https://def456.ngrok-free.app/api
✅ Ngrok Dashboard: http://localhost:4040

ℹ️  ✨ Authentication is disabled - no login required!
ℹ️  🔧 All authentication errors have been fixed
ℹ️  🌐 Application is accessible from anywhere via ngrok
```

## 🔄 How It Works

The `start-app.sh` script:

1. **Validates environment** - Checks all required tools
2. **Configures ngrok** - Sets up tunnels using `ngrok.yml`
3. **Starts services** - Backend → Frontend → Monitoring
4. **Updates config** - Automatically configures environment variables
5. **Monitors health** - Restarts services if they crash

## 🛠️ Manual Steps (if needed)

If you prefer manual control:

```bash
# 1. Start ngrok tunnels
ngrok start --all --config ~/.config/ngrok/ngrok.yml

# 2. Update environment files
python3 scripts/setup-ngrok.py

# 3. Start backend
cd backend && uv run uvicorn api:app --reload --host 0.0.0.0 --port 8000

# 4. Start frontend (in new terminal)
cd frontend && npm run dev
```

## 🔍 Monitoring & Logs

- **Ngrok Dashboard:** http://localhost:4040
- **Backend Logs:** `backend.log`
- **Frontend Logs:** `frontend.log`
- **Ngrok Logs:** `ngrok.log`

## 🚨 Troubleshooting

### Ngrok Issues
```bash
# Check ngrok status
ngrok config check

# View active tunnels
curl http://localhost:4040/api/tunnels
```

### Port Conflicts
```bash
# Kill processes on ports
lsof -ti :3000 | xargs kill -9
lsof -ti :8000 | xargs kill -9
```

### Authentication Errors
- ✅ **Already Fixed!** The app now runs without authentication
- No login required for development
- All auth errors have been resolved

## 🎯 Key Features

- **🔒 No Authentication Required** - Bypass login for development
- **🌐 Internet Accessible** - Share your local app with anyone
- **🔄 Auto-Restart** - Services restart automatically if they crash
- **📊 Real-time Monitoring** - Health checks every 10 seconds
- **🎨 Colored Output** - Easy to read status messages
- **🧹 Clean Shutdown** - Ctrl+C stops everything cleanly

## 📝 Environment Files

The script automatically updates:

**frontend/.env.local:**
```env
NEXT_PUBLIC_URL=https://your-frontend.ngrok-free.app
NEXT_PUBLIC_APP_URL=https://your-frontend.ngrok-free.app
NEXT_PUBLIC_BACKEND_URL=https://your-backend.ngrok-free.app/api
BACKEND_URL=https://your-backend.ngrok-free.app
```

**backend/.env:**
```env
CORS_ALLOWED_ORIGINS=https://your-frontend.ngrok-free.app
WEBHOOK_BASE_URL=https://your-backend.ngrok-free.app
NEXT_PUBLIC_URL=https://your-frontend.ngrok-free.app
```

## 🎉 Success!

Once running, your EMMA AI application will be:
- ✅ Accessible from anywhere via ngrok URLs
- ✅ Running without authentication requirements
- ✅ Automatically configured for internet access
- ✅ Monitored and auto-restarting

**Just run `./start-app.sh` and you're ready to go!** 🚀
