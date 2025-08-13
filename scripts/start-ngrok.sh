#!/bin/bash

# Start ngrok and automatically configure Suna for development
# This script starts ngrok tunnels and updates environment files

set -e

echo "🚀 Starting ngrok for Suna development..."

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok is not installed. Please install it from https://ngrok.com/download"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -d "frontend" ]] || [[ ! -d "backend" ]]; then
    echo "❌ Please run this script from the Suna project root directory"
    exit 1
fi

# Check if ngrok config exists
NGROK_CONFIG="$HOME/.config/ngrok/ngrok.yml"
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    NGROK_CONFIG="$USERPROFILE/.ngrok2/ngrok.yml"
fi

if [[ ! -f "$NGROK_CONFIG" ]]; then
    echo "❌ Ngrok config not found at $NGROK_CONFIG"
    echo "📋 Please:"
    echo "1. Copy ngrok.yml from this repo to $NGROK_CONFIG"
    echo "2. Replace YOUR_AUTHTOKEN with your actual token from https://dashboard.ngrok.com/get-started/your-authtoken"
    exit 1
fi

# Check if authtoken is configured
if grep -q "YOUR_AUTHTOKEN" "$NGROK_CONFIG" 2>/dev/null; then
    echo "❌ Please update your authtoken in $NGROK_CONFIG"
    echo "Replace YOUR_AUTHTOKEN with your actual token from https://dashboard.ngrok.com/get-started/your-authtoken"
    exit 1
fi

# Check if ngrok config is valid
if ! ngrok config check >/dev/null 2>&1; then
    echo "❌ Invalid ngrok configuration. Please check your authtoken."
    echo "Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken"
    exit 1
fi

echo "🌐 Starting ngrok tunnels..."

# Start ngrok in background
ngrok start --all --config="$NGROK_CONFIG" &
NGROK_PID=$!

# Wait for ngrok to start
echo "⏳ Waiting for ngrok to start..."
sleep 5

# Check if ngrok is running
if ! kill -0 $NGROK_PID 2>/dev/null; then
    echo "❌ Failed to start ngrok"
    exit 1
fi

echo "✅ Ngrok started successfully!"

# Run the Python setup script
echo "🔧 Configuring environment files..."
python3 scripts/setup-ngrok.py

echo ""
echo "🎉 Setup complete! Ngrok is running in the background."
echo ""
echo "📋 To stop ngrok later, run: pkill ngrok"
echo "📊 View ngrok dashboard at: http://localhost:4040"
echo ""
echo "💡 Remember to restart your frontend and backend servers to pick up the new environment variables!"
