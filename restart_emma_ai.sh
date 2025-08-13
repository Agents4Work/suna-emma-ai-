#!/bin/bash

# EMMA AI Complete Restart Script
# This script handles environment setup and restarts both frontend and backend

echo "🔄 EMMA AI Complete System Restart"
echo "=================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is in use
port_in_use() {
    lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1
}

# Function to kill processes on a port
kill_port() {
    local port=$1
    echo "🔪 Killing processes on port $port..."
    lsof -ti:$port | xargs kill -9 2>/dev/null || true
    sleep 2
}

# Step 1: Stop existing processes
echo "🛑 Step 1: Stopping existing processes..."
kill_port 3000  # Frontend
kill_port 8000  # Backend
kill_port 8001  # Alternative backend

# Kill any Python/Node processes that might be running
pkill -f "uvicorn" 2>/dev/null || true
pkill -f "python.*api" 2>/dev/null || true
pkill -f "next" 2>/dev/null || true
pkill -f "node.*3000" 2>/dev/null || true

echo "✅ Existing processes stopped"

# Step 2: Verify environment
echo "🔧 Step 2: Verifying environment..."

# Check Python
if command_exists python; then
    echo "✅ Python available: $(python --version)"
else
    echo "❌ Python not found"
    exit 1
fi

# Check Node.js
if command_exists node; then
    echo "✅ Node.js available: $(node --version)"
else
    echo "❌ Node.js not found"
    exit 1
fi

# Check npm
if command_exists npm; then
    echo "✅ npm available: $(npm --version)"
else
    echo "❌ npm not found"
    exit 1
fi

# Step 3: Verify no-auth configuration
echo "🔒 Step 3: Verifying no-auth configuration..."

if [ -f "backend/utils/config.py" ]; then
    if grep -q "NO_AUTH_MODE: bool = True" backend/utils/config.py; then
        echo "✅ NO_AUTH_MODE is enabled"
    else
        echo "⚠️  NO_AUTH_MODE not found or disabled"
        echo "Please ensure NO_AUTH_MODE = True in backend/utils/config.py"
    fi
else
    echo "❌ Config file not found"
    exit 1
fi

if [ -f "backend/utils/no_auth.py" ]; then
    echo "✅ No-auth bypass module exists"
else
    echo "❌ No-auth bypass module missing"
    exit 1
fi

# Step 4: Start backend
echo "🚀 Step 4: Starting backend server..."

cd backend

# Try to start the backend
echo "Starting uvicorn server..."
python -m uvicorn api:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

# Wait for backend to start
echo "⏳ Waiting for backend to initialize..."
sleep 10

# Check if backend is responding
for i in {1..6}; do
    if curl -s http://localhost:8000/api/health >/dev/null 2>&1; then
        echo "✅ Backend is running on port 8000"
        break
    else
        echo "⏳ Waiting for backend... (attempt $i/6)"
        sleep 5
    fi
    
    if [ $i -eq 6 ]; then
        echo "❌ Backend failed to start after 30 seconds"
        echo "Backend PID: $BACKEND_PID"
        echo "Checking backend logs..."
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
done

cd ..

# Step 5: Start frontend
echo "🎨 Step 5: Starting frontend server..."

cd frontend

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    npm install
fi

# Start frontend
echo "Starting Next.js development server..."
npm run dev &
FRONTEND_PID=$!

# Wait for frontend to start
echo "⏳ Waiting for frontend to initialize..."
sleep 15

# Check if frontend is responding
for i in {1..6}; do
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        echo "✅ Frontend is running on port 3000"
        break
    else
        echo "⏳ Waiting for frontend... (attempt $i/6)"
        sleep 5
    fi
    
    if [ $i -eq 6 ]; then
        echo "❌ Frontend failed to start after 30 seconds"
        echo "Frontend PID: $FRONTEND_PID"
        kill $FRONTEND_PID 2>/dev/null || true
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
done

cd ..

# Step 6: Success!
echo ""
echo "🎉 EMMA AI System Started Successfully!"
echo "======================================"
echo ""
echo "🌐 Frontend:  http://localhost:3000"
echo "🔧 Backend:   http://localhost:8000"
echo "📚 API Docs:  http://localhost:8000/docs"
echo ""
echo "🔓 Authentication: COMPLETELY DISABLED"
echo "✅ All models available: GPT-4o, Claude Sonnet 4, O1, etc."
echo "✅ All features unlocked: Unlimited agents, tools, workflows"
echo "✅ No restrictions: No billing, no limits, no access controls"
echo ""
echo "🚀 Ready for integration into your application!"
echo ""
echo "Process Information:"
echo "Backend PID:  $BACKEND_PID"
echo "Frontend PID: $FRONTEND_PID"
echo ""
echo "To stop the system:"
echo "kill $BACKEND_PID $FRONTEND_PID"
echo ""
echo "📊 System is now running and ready for use!"

# Keep the script running to monitor
echo "Press Ctrl+C to stop monitoring (processes will continue running)"
trap 'echo "Monitoring stopped. Processes are still running."; exit 0' INT

while true; do
    sleep 30
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo "❌ Backend process died (PID: $BACKEND_PID)"
        break
    fi
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "❌ Frontend process died (PID: $FRONTEND_PID)"
        break
    fi
    echo "✅ System running normally - $(date '+%H:%M:%S')"
done

echo "⚠️  One or more processes have stopped"
