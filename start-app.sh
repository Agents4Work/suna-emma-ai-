#!/bin/bash

# EMMA AI Startup Script with Ngrok
# This script automatically starts the entire application with ngrok tunneling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is in use
port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
}

# Function to kill processes on specific ports
kill_port() {
    if port_in_use $1; then
        print_info "Killing processes on port $1..."
        lsof -ti :$1 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local name=$2
    local max_attempts=60  # Increased timeout for frontend compilation
    local attempt=1
    
    print_info "Waiting for $name to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            print_status "$name is ready!"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$name failed to start after $((max_attempts * 2)) seconds"
    return 1
}

# Function to cleanup on exit
cleanup() {
    print_info "Cleaning up..."
    pkill -f "ngrok" 2>/dev/null || true
    kill_port 3000
    kill_port 8000
    kill_port 4040
    exit 0
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

print_header "EMMA AI - Starting Application with Ngrok"
echo ""

# Check if we're in the right directory
if [[ ! -d "frontend" ]] || [[ ! -d "backend" ]]; then
    print_error "Please run this script from the EMMA AI project root directory"
    exit 1
fi

# Check required tools
print_info "Checking required tools..."

if ! command_exists ngrok; then
    print_error "ngrok is not installed. Please install it from https://ngrok.com/download"
    exit 1
fi

if ! command_exists node; then
    print_error "Node.js is not installed"
    exit 1
fi

if ! command_exists python3; then
    print_error "Python 3 is not installed"
    exit 1
fi

if ! command_exists uv; then
    print_error "uv is not installed. Please install it from https://docs.astral.sh/uv/"
    exit 1
fi

print_status "All required tools are available"

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'v' -f2)
NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1)

if [ "$NODE_MAJOR" -lt 18 ]; then
    print_warning "Node.js version $NODE_VERSION detected. Attempting to use Node 20..."
    if [ -f "/usr/local/Cellar/node@20/20.19.4/bin/node" ]; then
        export PATH="/usr/local/Cellar/node@20/20.19.4/bin:$PATH"
        print_status "Using Node.js 20"
    else
        print_error "Node.js 18+ is required. Current version: $NODE_VERSION"
        exit 1
    fi
fi

# Clean up any existing processes
print_info "Cleaning up existing processes..."
pkill -f "ngrok" 2>/dev/null || true
kill_port 3000
kill_port 8000
kill_port 4040

# Check ngrok configuration
print_info "Checking ngrok configuration..."

NGROK_CONFIG="$HOME/.config/ngrok/ngrok.yml"
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    NGROK_CONFIG="$USERPROFILE/.ngrok2/ngrok.yml"
fi

# Copy our ngrok config if it doesn't exist or is outdated
if [[ ! -f "$NGROK_CONFIG" ]] || ! grep -q "tunnels:" "$NGROK_CONFIG" 2>/dev/null; then
    print_info "Setting up ngrok configuration..."
    mkdir -p "$(dirname "$NGROK_CONFIG")"
    cp ngrok.yml "$NGROK_CONFIG"
    print_status "Ngrok configuration updated"
fi

# Validate ngrok config
if ! ngrok config check >/dev/null 2>&1; then
    print_error "Invalid ngrok configuration. Please check your authtoken."
    print_info "Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken"
    exit 1
fi

print_status "Ngrok configuration is valid"

# Start ngrok tunnels
print_header "Starting Ngrok Tunnels"
ngrok start --all --config="$NGROK_CONFIG" --log=stdout > ngrok.log 2>&1 &
NGROK_PID=$!

# Wait for ngrok to start
print_info "Waiting for ngrok to initialize..."
sleep 8

# Check if ngrok is running
if ! kill -0 $NGROK_PID 2>/dev/null; then
    print_error "Failed to start ngrok. Check ngrok.log for details."
    cat ngrok.log
    exit 1
fi

print_status "Ngrok tunnels started"

# Configure environment with ngrok URLs
print_info "Configuring environment with ngrok URLs..."
if ! python3 scripts/setup-ngrok.py; then
    print_error "Failed to configure ngrok URLs"
    exit 1
fi

print_status "Environment configured"

# Start backend
print_header "Starting Backend"
cd backend
uv run uvicorn api:app --reload --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# Wait for backend to be ready
if ! wait_for_service "http://localhost:8000/api/health" "Backend"; then
    print_error "Backend failed to start. Check backend.log for details."
    exit 1
fi

# Start frontend
print_header "Starting Frontend"
cd frontend
PATH="/usr/local/Cellar/node@20/20.19.4/bin:$PATH" npm run dev > ../frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

# Wait for frontend to be ready
if ! wait_for_service "http://localhost:3000" "Frontend"; then
    print_error "Frontend failed to start. Check frontend.log for details."
    exit 1
fi

# Get the ngrok URLs
sleep 2
FRONTEND_URL=$(python3 -c "
import requests
try:
    r = requests.get('http://localhost:4040/api/tunnels', timeout=5)
    tunnels = r.json().get('tunnels', [])
    for tunnel in tunnels:
        if tunnel.get('name') == 'frontend' and tunnel.get('public_url', '').startswith('https://'):
            print(tunnel['public_url'])
            break
except:
    pass
")

BACKEND_URL=$(python3 -c "
import requests
try:
    r = requests.get('http://localhost:4040/api/tunnels', timeout=5)
    tunnels = r.json().get('tunnels', [])
    for tunnel in tunnels:
        if tunnel.get('name') == 'backend' and tunnel.get('public_url', '').startswith('https://'):
            print(tunnel['public_url'])
            break
except:
    pass
")

# Display success information
echo ""
print_header "🎉 EMMA AI is now running!"
echo ""
print_status "Frontend: $FRONTEND_URL"
print_status "Backend:  $BACKEND_URL/api"
print_status "Ngrok Dashboard: http://localhost:4040"
echo ""
print_info "✨ Authentication is disabled - no login required!"
print_info "🔧 All authentication errors have been fixed"
print_info "🌐 Application is accessible from anywhere via ngrok"
echo ""
print_warning "Press Ctrl+C to stop all services"
echo ""

# Keep the script running and monitor services
while true; do
    # Check if ngrok is still running
    if ! kill -0 $NGROK_PID 2>/dev/null; then
        print_error "Ngrok stopped unexpectedly"
        exit 1
    fi
    
    # Check if backend is still running
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        print_error "Backend stopped unexpectedly"
        exit 1
    fi
    
    # Check if frontend is still running
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        print_error "Frontend stopped unexpectedly"
        exit 1
    fi
    
    sleep 10
done
