#!/usr/bin/env python3
"""
Script to completely disable ALL authentication across the EMMA AI system.

This script modifies all API endpoints to remove authentication dependencies
and replaces them with no-auth bypass functions for local single-user development.

Run this script to convert the entire system to no-auth mode.
"""

import os
import re
import sys
from pathlib import Path

def find_auth_dependencies(directory):
    """Find all files with authentication dependencies."""
    auth_patterns = [
        r'Depends\(get_current_user_id_from_jwt\)',
        r'Depends\(get_optional_user_id_from_jwt\)',
        r'Depends\(get_user_id_from_stream_auth\)',
        r'Depends\(verify_admin_api_key\)',
        r'get_current_user_id_from_jwt',
        r'verify_thread_access',
        r'verify_agent_access',
    ]
    
    files_with_auth = []
    
    for root, dirs, files in os.walk(directory):
        # Skip certain directories
        if any(skip in root for skip in ['.git', '__pycache__', 'node_modules', '.env']):
            continue
            
        for file in files:
            if file.endswith('.py'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        
                    for pattern in auth_patterns:
                        if re.search(pattern, content):
                            files_with_auth.append(file_path)
                            break
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")
    
    return files_with_auth

def create_no_auth_replacements():
    """Create replacement patterns for authentication functions."""
    replacements = [
        # Replace authentication dependencies
        (r'user_id: str = Depends\(get_current_user_id_from_jwt\)', 
         'user_id: str = Depends(lambda: "local-user")'),
        
        (r'user_id: Optional\[str\] = Depends\(get_optional_user_id_from_jwt\)', 
         'user_id: Optional[str] = Depends(lambda: "local-user")'),
         
        (r'current_user_id: str = Depends\(get_current_user_id_from_jwt\)', 
         'current_user_id: str = Depends(lambda: "local-user")'),
         
        (r'Depends\(verify_admin_api_key\)', 
         'Depends(lambda: True)'),
         
        # Replace function calls
        (r'await verify_thread_access\(([^)]+)\)', 
         r'# No-auth: await verify_thread_access(\1)'),
         
        (r'await verify_agent_access\(([^)]+)\)', 
         r'# No-auth: await verify_agent_access(\1)'),
    ]
    
    return replacements

def apply_no_auth_mode(file_path):
    """Apply no-auth modifications to a file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        replacements = create_no_auth_replacements()
        
        # Apply replacements
        for pattern, replacement in replacements:
            content = re.sub(pattern, replacement, content)
        
        # Add no-auth import if needed
        if 'from utils.no_auth import' not in content and content != original_content:
            # Find the last import line
            lines = content.split('\n')
            last_import_line = -1
            for i, line in enumerate(lines):
                if line.strip().startswith(('import ', 'from ')) and 'import' in line:
                    last_import_line = i
            
            if last_import_line >= 0:
                lines.insert(last_import_line + 1, 
                           '# No-auth mode imports\nfrom utils.no_auth import get_default_user_id')
                content = '\n'.join(lines)
        
        # Only write if content changed
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Modified: {file_path}")
            return True
        else:
            print(f"⏭️  No changes needed: {file_path}")
            return False
            
    except Exception as e:
        print(f"❌ Error modifying {file_path}: {e}")
        return False

def main():
    """Main function to disable all authentication."""
    print("🔓 Disabling ALL authentication in EMMA AI system...")
    print("=" * 60)
    
    # Get the backend directory
    backend_dir = Path(__file__).parent
    
    # Find all files with authentication dependencies
    print("🔍 Scanning for authentication dependencies...")
    auth_files = find_auth_dependencies(backend_dir)
    
    if not auth_files:
        print("✅ No authentication dependencies found!")
        return
    
    print(f"📁 Found {len(auth_files)} files with authentication dependencies:")
    for file_path in auth_files:
        rel_path = os.path.relpath(file_path, backend_dir)
        print(f"   - {rel_path}")
    
    print("\n🔧 Applying no-auth modifications...")
    
    modified_count = 0
    for file_path in auth_files:
        rel_path = os.path.relpath(file_path, backend_dir)
        if apply_no_auth_mode(file_path):
            modified_count += 1
    
    print("\n" + "=" * 60)
    print(f"✅ Authentication bypass complete!")
    print(f"📊 Modified {modified_count} out of {len(auth_files)} files")
    print("\n🎉 EMMA AI is now running in complete no-auth mode!")
    print("🔓 All features and models are now accessible without restrictions")
    
    # Verify no-auth mode is enabled in config
    config_path = backend_dir / "utils" / "config.py"
    if config_path.exists():
        with open(config_path, 'r') as f:
            config_content = f.read()
        
        if 'NO_AUTH_MODE: bool = True' in config_content:
            print("✅ NO_AUTH_MODE is enabled in config")
        else:
            print("⚠️  Please ensure NO_AUTH_MODE = True in utils/config.py")

if __name__ == "__main__":
    main()
