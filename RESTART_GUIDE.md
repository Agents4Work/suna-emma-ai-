# EMMA AI No-Auth System Restart Guide

## 🎯 Quick Restart (Recommended)

### Option 1: Automated Script
```bash
# Run the automated restart script
./backend/restart_no_auth_system.sh
```

### Option 2: Manual Restart
```bash
# 1. Stop any existing processes
pkill -f "python.*api.py"
pkill -f "uvicorn"
pkill -f "next"

# 2. Start backend
cd backend
python -m uvicorn api:app --host 0.0.0.0 --port 8000 --reload &

# 3. Start frontend (in new terminal)
cd frontend
npm run dev &
```

## 🔧 System Configuration Verification

### Check No-Auth Mode Status
```bash
# Verify NO_AUTH_MODE is enabled
grep "NO_AUTH_MODE" backend/utils/config.py
# Should show: NO_AUTH_MODE: bool = True
```

### Verify No-Auth Module
```bash
# Check if no-auth module exists
ls -la backend/utils/no_auth.py
# Should exist and contain bypass functions
```

## 🌐 Access Points After Restart

- **Frontend Dashboard**: http://localhost:3000
- **Backend API**: http://localhost:8000  
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/api/health

## ✅ Expected Behavior

### Frontend (http://localhost:3000)
- ✅ Loads directly to dashboard (no login screen)
- ✅ All models available in dropdown (GPT-4o, Claude Sonnet 4, O1, etc.)
- ✅ Chat interface works immediately
- ✅ All features accessible without restrictions

### Backend (http://localhost:8000)
- ✅ All API endpoints work without authentication headers
- ✅ No JWT token validation
- ✅ All models allowed without billing checks
- ✅ Unlimited agent creation and execution

## 🧪 Quick Test Sequence

### 1. Test Frontend Access
```bash
curl http://localhost:3000
# Should return HTML (not redirect to login)
```

### 2. Test Backend Health
```bash
curl http://localhost:8000/api/health
# Should return: {"status": "ok", "timestamp": "...", "instance_id": "..."}
```

### 3. Test No-Auth Configuration
```bash
curl http://localhost:8000/docs
# Should return API documentation without authentication
```

### 4. Test Agent Initiation (Optional)
```bash
curl -X POST "http://localhost:8000/api/agent/initiate" \
  -H "Content-Type: multipart/form-data" \
  -F "prompt=Hello, test message"
# Should work without authentication headers
```

## 🔍 Troubleshooting

### Port Conflicts
```bash
# Check what's using ports
lsof -i :3000  # Frontend
lsof -i :8000  # Backend

# Kill processes if needed
kill -9 $(lsof -ti:3000)
kill -9 $(lsof -ti:8000)
```

### Backend Issues
```bash
# Check backend logs
cd backend
python -m uvicorn api:app --host 0.0.0.0 --port 8000 --reload --log-level debug
```

### Frontend Issues
```bash
# Check frontend logs
cd frontend
npm run dev
```

### Configuration Issues
```bash
# Verify no-auth module imports
cd backend
python -c "from utils.no_auth import *; print('✅ No-auth module working')"

# Verify config
python -c "from utils.config import config; print(f'NO_AUTH_MODE: {getattr(config, \"NO_AUTH_MODE\", False)}')"
```

## 🚀 Success Indicators

### System is Ready When:
- ✅ Frontend loads at http://localhost:3000 without login
- ✅ Backend responds at http://localhost:8000/api/health
- ✅ All premium models appear in model selector
- ✅ Chat interface accepts and processes messages
- ✅ No authentication errors in browser console
- ✅ No billing or usage limit errors

### Authentication Bypass Working When:
- ✅ No login screens or authentication prompts
- ✅ All API calls work without Authorization headers
- ✅ All models available (not just free tier)
- ✅ Unlimited agent creation and execution
- ✅ All advanced features accessible immediately

## 🎉 Ready for Integration

Once restarted successfully, your EMMA AI system will be:
- **Completely authentication-free**
- **Unrestricted access to all models and features**
- **Ready for integration into your own application**
- **No billing, usage, or access limitations**

The system will function as a powerful, unrestricted AI agent platform that you can embed directly into your own application without any authentication complexity.
