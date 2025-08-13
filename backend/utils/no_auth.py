"""
Complete Authentication Bypass Module

This module provides replacement functions that completely disable all authentication,
billing, and access control checks for local single-user development environments.

All functions return permissive results to allow unrestricted access to all features.
"""

from typing import Optional, Dict, Any, List, Tuple
from utils.logger import logger

# Default single user ID for all operations
DEFAULT_USER_ID = "local-user"

# === Authentication Bypass Functions ===

async def no_auth_get_user_id(request: Optional[Any] = None) -> str:
    """Always return the default user ID - no authentication required."""
    return DEFAULT_USER_ID

async def no_auth_get_optional_user_id(request: Optional[Any] = None) -> Optional[str]:
    """Always return the default user ID - no authentication required."""
    return DEFAULT_USER_ID

async def no_auth_get_stream_user_id(request: Any, token: Optional[str] = None) -> str:
    """Always return the default user ID for streaming - no authentication required."""
    return DEFAULT_USER_ID

async def no_auth_verify_thread_access(client, thread_id: str, user_id: str):
    """Always allow thread access - no verification required."""
    logger.debug(f"No-auth: Allowing access to thread {thread_id} for user {user_id}")
    return True

async def no_auth_verify_agent_access(client, agent_id: str, user_id: str):
    """Always allow agent access - no verification required."""
    logger.debug(f"No-auth: Allowing access to agent {agent_id} for user {user_id}")
    return True

async def no_auth_verify_admin_api_key(x_admin_api_key: Optional[str] = None):
    """Always allow admin access - no API key verification required."""
    logger.debug("No-auth: Allowing admin access without API key verification")
    return True

# === Billing Bypass Functions ===

async def no_auth_can_use_model(client, user_id: str, model_name: str) -> Tuple[bool, str, List[str]]:
    """Always allow any model usage - no billing restrictions."""
    logger.debug(f"No-auth: Allowing model {model_name} for user {user_id}")
    # Return all available models as allowed
    all_models = [
        "anthropic/claude-sonnet-4-20250514",
        "anthropic/claude-3-5-sonnet-latest", 
        "anthropic/claude-3-7-sonnet-latest",
        "openai/gpt-4o",
        "openai/gpt-4o-mini",
        "openai/gpt-5-mini",
        "openai/o1",
        "openai/o1-mini",
        "openai/o1-preview",
        "openrouter/deepseek/deepseek-chat",
        "openrouter/qwen/qwen-2.5-72b-instruct",
        "gemini/gemini-2.0-flash-exp",
        "xai/grok-2-1212",
        "xai/grok-2-vision-1212"
    ]
    return True, "No-auth: All models allowed", all_models

async def no_auth_check_billing_status(client, user_id: str) -> Tuple[bool, str, Optional[Dict]]:
    """Always allow agent runs - no billing restrictions."""
    logger.debug(f"No-auth: Allowing unlimited agent runs for user {user_id}")
    return True, "No-auth: Unlimited usage allowed", {
        "price_id": "no_auth_unlimited",
        "plan_name": "No Auth Unlimited",
        "minutes_limit": "unlimited"
    }

async def no_auth_check_agent_run_limit(client, account_id: str) -> Dict[str, Any]:
    """Always allow agent runs - no limits."""
    logger.debug(f"No-auth: Allowing unlimited agent runs for account {account_id}")
    return {
        'can_start': True,
        'running_count': 0,
        'running_thread_ids': []
    }

async def no_auth_check_agent_count_limit(client, account_id: str) -> Dict[str, Any]:
    """Always allow agent creation - no limits."""
    logger.debug(f"No-auth: Allowing unlimited agents for account {account_id}")
    return {
        'can_create': True,
        'current_count': 0,
        'limit': 999999,
        'tier_name': 'unlimited'
    }

# === Feature Flag Bypass ===

async def no_auth_is_enabled(flag_name: str) -> bool:
    """Always enable all features - no restrictions."""
    logger.debug(f"No-auth: Enabling feature flag {flag_name}")
    return True

# === Access Control Bypass ===

async def no_auth_get_agent_run_with_access_check(client, agent_run_id: str, user_id: str):
    """Get agent run without access checks."""
    logger.debug(f"No-auth: Allowing access to agent run {agent_run_id}")
    
    # Just get the agent run data without any access verification
    agent_run = await client.table('agent_runs').select('*, threads(account_id)').eq('id', agent_run_id).execute()
    if not agent_run.data:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Agent run not found")
    
    return agent_run.data[0]

# === Database Query Helpers ===

def no_auth_get_account_id(user_id: str = None) -> str:
    """Always return the default user ID as account ID."""
    return DEFAULT_USER_ID

def no_auth_modify_query_for_access(query, user_id: str = None):
    """Return query without any access restrictions."""
    # Don't add any account_id or user_id filters
    return query

# === Utility Functions ===

def is_no_auth_enabled() -> bool:
    """Check if no-auth mode is enabled (always True for this module)."""
    return True

def get_default_user_id() -> str:
    """Get the default user ID for all operations."""
    return DEFAULT_USER_ID

def log_no_auth_access(operation: str, resource: str = "", user_id: str = None):
    """Log no-auth access for debugging."""
    logger.debug(f"No-auth access: {operation} on {resource} by {user_id or DEFAULT_USER_ID}")
