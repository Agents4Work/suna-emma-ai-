#!/usr/bin/env python3
"""
Ngrok setup script for Suna development.
This script automatically detects running ngrok tunnels and updates environment files.
"""

import json
import os
import sys
import time
import requests
from pathlib import Path

def get_ngrok_tunnels():
    """Get running ngrok tunnels from the local API."""
    try:
        response = requests.get("http://localhost:4040/api/tunnels", timeout=5)
        response.raise_for_status()
        data = response.json()
        return data.get("tunnels", [])
    except requests.exceptions.RequestException as e:
        print(f"❌ Error connecting to ngrok API: {e}")
        print("Make sure ngrok is running with: ngrok start --all")
        return []

def find_tunnel_urls():
    """Find frontend and backend tunnel URLs."""
    tunnels = get_ngrok_tunnels()
    
    if not tunnels:
        print("❌ No ngrok tunnels found. Start ngrok first with: ngrok start --all")
        return None, None
    
    frontend_url = None
    backend_url = None
    
    for tunnel in tunnels:
        name = tunnel.get("name", "")
        public_url = tunnel.get("public_url", "")
        
        # Prefer HTTPS URLs
        if public_url.startswith("https://"):
            if name == "frontend":
                frontend_url = public_url
            elif name == "backend":
                backend_url = public_url
    
    return frontend_url, backend_url

def update_frontend_env(frontend_url, backend_url):
    """Update frontend/.env.local with ngrok URLs."""
    env_file = Path("frontend/.env.local")
    
    # Read existing env file or create new one
    env_lines = []
    if env_file.exists():
        with open(env_file, 'r') as f:
            env_lines = f.readlines()
    
    # Update or add required variables
    updates = {
        "NEXT_PUBLIC_URL": frontend_url,
        "NEXT_PUBLIC_APP_URL": frontend_url,
        "NEXT_PUBLIC_BACKEND_URL": f"{backend_url}/api",
        "BACKEND_URL": backend_url,
    }
    
    # Process existing lines
    updated_lines = []
    updated_keys = set()
    
    for line in env_lines:
        line = line.strip()
        if not line or line.startswith('#'):
            updated_lines.append(line)
            continue
            
        if '=' in line:
            key = line.split('=')[0]
            if key in updates:
                updated_lines.append(f"{key}={updates[key]}")
                updated_keys.add(key)
            else:
                updated_lines.append(line)
        else:
            updated_lines.append(line)
    
    # Add new variables that weren't in the file
    for key, value in updates.items():
        if key not in updated_keys:
            updated_lines.append(f"{key}={value}")
    
    # Write updated file
    with open(env_file, 'w') as f:
        for line in updated_lines:
            f.write(line + '\n')
    
    print(f"✅ Updated {env_file}")

def update_backend_env(frontend_url, backend_url):
    """Update backend/.env with ngrok URLs."""
    env_file = Path("backend/.env")
    
    if not env_file.exists():
        print(f"❌ {env_file} not found. Create it first by copying backend/.env.example")
        return
    
    # Read existing env file
    with open(env_file, 'r') as f:
        env_lines = f.readlines()
    
    # Update or add required variables
    updates = {
        "CORS_ALLOWED_ORIGINS": frontend_url,
        "WEBHOOK_BASE_URL": backend_url,
        "NEXT_PUBLIC_URL": frontend_url,
    }
    
    # Process existing lines
    updated_lines = []
    updated_keys = set()
    
    for line in env_lines:
        line = line.strip()
        if not line or line.startswith('#'):
            updated_lines.append(line)
            continue
            
        if '=' in line:
            key = line.split('=')[0]
            if key in updates:
                updated_lines.append(f"{key}={updates[key]}")
                updated_keys.add(key)
            else:
                updated_lines.append(line)
        else:
            updated_lines.append(line)
    
    # Add new variables that weren't in the file
    for key, value in updates.items():
        if key not in updated_keys:
            updated_lines.append(f"{key}={value}")
    
    # Write updated file
    with open(env_file, 'w') as f:
        for line in updated_lines:
            f.write(line + '\n')
    
    print(f"✅ Updated {env_file}")

def main():
    """Main setup function."""
    print("🚀 Setting up ngrok for Suna development...")
    
    # Check if we're in the right directory
    if not Path("frontend").exists() or not Path("backend").exists():
        print("❌ Please run this script from the Suna project root directory")
        sys.exit(1)
    
    # Wait a moment for ngrok to fully start if just launched
    print("🔍 Looking for ngrok tunnels...")
    time.sleep(2)
    
    frontend_url, backend_url = find_tunnel_urls()
    
    if not frontend_url or not backend_url:
        print("❌ Could not find both frontend and backend tunnels")
        print("Expected tunnel names: 'frontend' (port 3000) and 'backend' (port 8000)")
        print("Start ngrok with: ngrok start --all")
        sys.exit(1)
    
    print(f"📱 Frontend URL: {frontend_url}")
    print(f"🔧 Backend URL: {backend_url}")
    
    # Update environment files
    update_frontend_env(frontend_url, backend_url)
    update_backend_env(frontend_url, backend_url)
    
    print("\n✅ Ngrok setup complete!")
    print("\n📋 Next steps:")
    print("1. Restart your frontend: cd frontend && npm run dev")
    print("2. Restart your backend if it's running")
    print(f"3. Access your app at: {frontend_url}")
    print("\n💡 If you need to update OAuth redirect URLs:")
    print(f"   - Supabase Site URL: {frontend_url}")
    print(f"   - Supabase Redirect URLs: {frontend_url}/auth/callback")
    print(f"   - Slack Redirect URI: {frontend_url}/api/integrations/slack/callback")

if __name__ == "__main__":
    main()
