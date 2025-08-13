#!/bin/bash

# EMMA AI No-Auth System Restart Script
# This script restarts the entire EMMA AI system with authentication completely disabled

echo "🔄 Restarting EMMA AI System with No Authentication..."
echo "=" * 60

# Function to check if a process is running on a port
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Port $port is in use"
        return 0
    else
        echo "✅ Port $port is available"
        return 1
    fi
}

# Function to kill processes on specific ports
kill_port() {
    local port=$1
    echo "🔪 Killing processes on port $port..."
    lsof -ti:$port | xargs kill -9 2>/dev/null || true
    sleep 2
}

# Stop existing processes
echo "🛑 Stopping existing processes..."

# Kill common development ports
kill_port 3000  # Frontend
kill_port 8000  # Backend
kill_port 8001  # Alternative backend
kill_port 5432  # PostgreSQL
kill_port 6379  # Redis

# Kill any Python processes that might be running the backend
echo "🔪 Stopping Python backend processes..."
pkill -f "python.*api.py" 2>/dev/null || true
pkill -f "uvicorn" 2>/dev/null || true
pkill -f "fastapi" 2>/dev/null || true

# Kill any Node.js processes that might be running the frontend
echo "🔪 Stopping Node.js frontend processes..."
pkill -f "next" 2>/dev/null || true
pkill -f "node.*3000" 2>/dev/null || true

echo "⏳ Waiting for processes to terminate..."
sleep 5

# Verify no-auth configuration
echo "🔧 Verifying no-auth configuration..."

# Check if NO_AUTH_MODE is enabled
if grep -q "NO_AUTH_MODE: bool = True" backend/utils/config.py; then
    echo "✅ NO_AUTH_MODE is enabled in config"
else
    echo "⚠️  Enabling NO_AUTH_MODE in config..."
    # Enable NO_AUTH_MODE if not already enabled
    sed -i.bak 's/NO_AUTH_MODE: bool = False/NO_AUTH_MODE: bool = True/g' backend/utils/config.py 2>/dev/null || true
fi

# Check if no-auth module exists
if [ -f "backend/utils/no_auth.py" ]; then
    echo "✅ No-auth bypass module is present"
else
    echo "❌ No-auth bypass module is missing!"
    echo "Please ensure backend/utils/no_auth.py exists"
    exit 1
fi

# Set environment variables for no-auth mode
export NO_AUTH_MODE=true
export ENV_MODE=local

echo "🚀 Starting EMMA AI system..."

# Start backend
echo "🔧 Starting backend server..."
cd backend
python -m uvicorn api:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!
cd ..

# Wait for backend to start
echo "⏳ Waiting for backend to initialize..."
sleep 10

# Check if backend is running
if check_port 8000; then
    echo "✅ Backend is running on port 8000"
else
    echo "❌ Backend failed to start"
    exit 1
fi

# Start frontend
echo "🎨 Starting frontend server..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

# Wait for frontend to start
echo "⏳ Waiting for frontend to initialize..."
sleep 15

# Check if frontend is running
if check_port 3000; then
    echo "✅ Frontend is running on port 3000"
else
    echo "❌ Frontend failed to start"
    exit 1
fi

echo ""
echo "🎉 EMMA AI System Started Successfully!"
echo "=" * 60
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend:  http://localhost:8000"
echo "📚 API Docs: http://localhost:8000/docs"
echo ""
echo "🔓 Authentication Status: COMPLETELY DISABLED"
echo "✅ All models available: GPT-4o, Claude Sonnet 4, O1, etc."
echo "✅ All features unlocked: Unlimited agents, tools, workflows"
echo "✅ No restrictions: No billing, no limits, no access controls"
echo ""
echo "🚀 Ready for integration into your application!"
echo ""
echo "Process IDs:"
echo "Backend PID: $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo ""
echo "To stop the system, run:"
echo "kill $BACKEND_PID $FRONTEND_PID"
echo "or use Ctrl+C in the terminals"

# Keep script running to monitor processes
echo "📊 Monitoring system status..."
while true; do
    sleep 30
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo "❌ Backend process died"
        break
    fi
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "❌ Frontend process died"
        break
    fi
    echo "✅ System running normally - $(date)"
done
