# Anonymous Access Implementation

This document outlines the changes made to enable anonymous access to the EMMA AI agent functionality.

## Summary of Changes

### 1. Agent Initiation Endpoint (`backend/agent/api.py`)

**Modified**: `initiate_agent_with_files` function
- Changed dependency from `get_current_user_id_from_jwt` to `get_optional_user_id_from_jwt`
- Added logic to handle `None` user_id by setting it to `"anonymous"`
- Modified agent query logic to allow anonymous users to access public or default Suna agents

### 2. Billing Service (`backend/services/billing.py`)

**Modified**: `can_use_model` function
- Added anonymous user handling to allow free tier models only
- Anonymous users get access to free tier models without subscription checks

**Modified**: `check_billing_status` function  
- Added anonymous user handling to allow limited usage
- Returns permissive billing status for anonymous users

### 3. Agent Utils (`backend/agent/utils.py`)

**Modified**: `check_agent_run_limit` function
- Added anonymous user handling to bypass agent run limits
- Anonymous users can start agents without concurrent run restrictions

### 4. Authentication Utils (`backend/utils/auth_utils.py`)

**Modified**: `verify_thread_access` function
- Added logic for anonymous users to access anonymous threads and public projects
- Prevents anonymous users from accessing private authenticated user threads

**Modified**: `get_agent_run_with_access_check` function (in agent/api.py)
- Added anonymous user access control for agent run streaming
- Anonymous users can only access their own (anonymous) agent runs

### 5. Streaming Endpoint (`backend/agent/api.py`)

**Modified**: `stream_agent_run` function
- Changed to handle authentication failures gracefully
- Falls back to anonymous access when no authentication is provided

## How Anonymous Access Works

1. **User Flow**: 
   - Frontend loads without authentication ✅ (already implemented)
   - User can immediately access dashboard and chat interface ✅ (already implemented)
   - User submits prompt → Backend receives request with no JWT token
   - Backend sets `user_id = "anonymous"` and proceeds

2. **Agent Creation**:
   - Anonymous users get `account_id = "anonymous"`
   - Threads and agent runs are created with anonymous ownership
   - Only free tier models are allowed for anonymous users

3. **Access Control**:
   - Anonymous users can only access their own anonymous threads/agent runs
   - Anonymous users can access public agents and default Suna agents
   - Anonymous users cannot access private authenticated user content

4. **Billing & Limits**:
   - Anonymous users bypass subscription checks
   - Anonymous users get free tier model access only
   - Anonymous users bypass agent run limits (for demo purposes)

## Testing the Implementation

### Manual Testing Steps

1. **Start the application** without authentication
2. **Navigate to dashboard** - should load immediately
3. **Submit a prompt** in the chat interface
4. **Verify agent response** streams back successfully
5. **Check that only free tier models** are available for anonymous users

### Automated Testing

Run the test script:
```bash
cd backend
python test_anonymous_access.py
```

### Expected Behavior

- ✅ Frontend loads without login prompts
- ✅ Dashboard is immediately accessible  
- ✅ Chat interface accepts prompts
- ✅ Agent initiation works without authentication
- ✅ Agent responses stream back successfully
- ✅ Only free tier models are accessible
- ✅ Anonymous users cannot access private content

## Security Considerations

1. **Data Isolation**: Anonymous users can only access anonymous threads
2. **Model Restrictions**: Anonymous users limited to free tier models
3. **No Persistent Data**: Anonymous sessions don't persist across browser sessions
4. **Rate Limiting**: Consider implementing rate limiting for anonymous users in production

## Environment Configuration

The implementation respects the `ENV_MODE` configuration:
- **Local Mode**: All billing checks are bypassed (development)
- **Production Mode**: Anonymous users get free tier access only

## Files Modified

- `backend/agent/api.py` - Main agent endpoints
- `backend/services/billing.py` - Billing and model access checks  
- `backend/agent/utils.py` - Agent run limits
- `backend/utils/auth_utils.py` - Authentication and access control

## Next Steps

1. Test the complete user flow from frontend to backend
2. Verify agent responses work end-to-end
3. Consider implementing rate limiting for anonymous users
4. Monitor anonymous usage patterns
5. Add analytics to track anonymous vs authenticated usage
