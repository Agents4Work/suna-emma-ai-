#!/bin/bash

# EMMA AI Stop Script
# Stops all running services including ngrok

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_header() {
    echo -e "${BLUE}🛑 $1${NC}"
}

# Function to check if a port is in use
port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
}

# Function to kill processes on specific ports
kill_port() {
    if port_in_use $1; then
        print_info "Stopping processes on port $1..."
        lsof -ti :$1 | xargs kill -9 2>/dev/null || true
        sleep 1
        if port_in_use $1; then
            print_warning "Some processes on port $1 may still be running"
        else
            print_status "Port $1 cleared"
        fi
    else
        print_info "No processes running on port $1"
    fi
}

print_header "Stopping EMMA AI Application"
echo ""

# Stop ngrok processes
print_info "Stopping ngrok tunnels..."
pkill -f "ngrok" 2>/dev/null || true
sleep 2

if pgrep -f "ngrok" >/dev/null; then
    print_warning "Some ngrok processes may still be running"
    pkill -9 -f "ngrok" 2>/dev/null || true
else
    print_status "Ngrok stopped"
fi

# Stop processes on specific ports
print_info "Stopping services on ports..."
kill_port 3000  # Frontend
kill_port 8000  # Backend
kill_port 4040  # Ngrok dashboard

# Stop any remaining Node.js processes that might be running the frontend
print_info "Stopping Node.js processes..."
pkill -f "next dev" 2>/dev/null || true
pkill -f "npm run dev" 2>/dev/null || true

# Stop any remaining Python/uvicorn processes that might be running the backend
print_info "Stopping Python/uvicorn processes..."
pkill -f "uvicorn" 2>/dev/null || true
pkill -f "api:app" 2>/dev/null || true

# Clean up log files
print_info "Cleaning up log files..."
rm -f ngrok.log backend.log frontend.log 2>/dev/null || true

print_status "All EMMA AI services stopped"
echo ""
print_info "To start again, run: ./start-app.sh"
echo ""
