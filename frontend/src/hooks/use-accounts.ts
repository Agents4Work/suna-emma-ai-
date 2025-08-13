import { useQuery, UseQueryOptions } from '@tanstack/react-query';
import { createClient } from '@/lib/supabase/client';
import { GetAccountsResponse } from '@usebasejump/shared';

export const useAccounts = (options?: UseQueryOptions<GetAccountsResponse>) => {
  const supabaseClient = createClient();
  return useQuery<GetAccountsResponse>({
    queryKey: ['accounts'],
    queryFn: async () => {
      try {
        // Check if user is authenticated first
        const { data: { session }, error: sessionError } = await supabaseClient.auth.getSession();

        if (sessionError || !session?.user) {
          // For EMMA AI, return empty array when no authentication
          console.log('No authentication available for accounts, returning empty array');
          return [];
        }

        const { data, error } = await supabaseClient.rpc('get_accounts');
        if (error) {
          // Handle specific auth-related errors gracefully
          if (error.code === '42501' || error.message.includes('permission') || error.message.includes('auth')) {
            console.log('Permission error for accounts, returning empty array');
            return [];
          }
          throw new Error(error.message);
        }
        return data;
      } catch (error: any) {
        // For EMMA AI, gracefully handle all auth-related errors
        console.log('Error fetching accounts, returning empty array:', error.message);
        return [];
      }
    },
    // Don't retry on auth errors
    retry: (failureCount, error) => {
      if (error?.message?.includes('permission') || error?.message?.includes('auth')) {
        return false;
      }
      return failureCount < 3;
    },
    ...options,
  });
};