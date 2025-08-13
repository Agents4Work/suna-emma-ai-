import React from 'react';
import { useQuery, useQueries } from '@tanstack/react-query';

const API_URL = process.env.NEXT_PUBLIC_BACKEND_URL || '';

export interface FeatureFlag {
  flag_name: string;
  enabled: boolean;
  details?: {
    description?: string;
    updated_at?: string;
  } | null;
}

export interface FeatureFlagsResponse {
  flags: Record<string, boolean>;
}

const flagCache = new Map<string, { value: boolean; timestamp: number }>();
const CACHE_DURATION = 5 * 60 * 1000;

let globalFlagsCache: { flags: Record<string, boolean>; timestamp: number } | null = null;

export class FeatureFlagManager {
  private static instance: FeatureFlagManager;
  
  private constructor() {}
  
  static getInstance(): FeatureFlagManager {
    if (!FeatureFlagManager.instance) {
      FeatureFlagManager.instance = new FeatureFlagManager();
    }
    return FeatureFlagManager.instance;
  }

  async isEnabled(flagName: string): Promise<boolean> {
    try {
      const cached = flagCache.get(flagName);
      if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
        return cached.value;
      }

      // For EMMA AI, if no backend URL is configured, return default values
      if (!API_URL) {
        console.log(`No backend URL configured, using default for feature flag ${flagName}`);
        return this._getDefaultFlagValue(flagName);
      }

      const response = await fetch(`${API_URL}/feature-flags/${flagName}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        // Add timeout to prevent hanging
        signal: AbortSignal.timeout(5000),
      });

      if (!response.ok) {
        console.log(`Backend unavailable for feature flag ${flagName}, using default`);
        return this._getDefaultFlagValue(flagName);
      }

      // Check if response is actually JSON
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        console.log(`Non-JSON response for feature flag ${flagName}, using default`);
        return this._getDefaultFlagValue(flagName);
      }

      const data: FeatureFlag = await response.json();

      flagCache.set(flagName, {
        value: data.enabled,
        timestamp: Date.now(),
      });

      return data.enabled;
    } catch (error) {
      console.log(`Error checking feature flag ${flagName}, using default:`, error instanceof Error ? error.message : error);
      return this._getDefaultFlagValue(flagName);
    }
  }

  private _getDefaultFlagValue(flagName: string): boolean {
    // Default values for EMMA AI when backend is unavailable
    const defaults: Record<string, boolean> = {
      'custom_agents': true,
      'agent_marketplace': true,
      'mcp_module': true,
      'templates_api': true,
      'triggers_api': true,
      'workflows_api': true,
      'knowledge_base': true,
      'pipedream': true,
      'credentials_api': true,
      'suna_default_agent': true,
    };

    return defaults[flagName] ?? false;
  }
  
  async getFlagDetails(flagName: string): Promise<FeatureFlag | null> {
    try {
      // For EMMA AI, if no backend URL is configured, return default
      if (!API_URL) {
        console.log(`No backend URL configured, using default for feature flag details ${flagName}`);
        return {
          flag_name: flagName,
          enabled: this._getDefaultFlagValue(flagName),
          details: {
            description: 'Default value (backend unavailable)',
            updated_at: new Date().toISOString(),
          }
        };
      }

      const response = await fetch(`${API_URL}/feature-flags/${flagName}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        // Add timeout to prevent hanging
        signal: AbortSignal.timeout(5000),
      });

      if (!response.ok) {
        console.log(`Backend unavailable for feature flag details ${flagName}`);
        return null;
      }

      // Check if response is actually JSON
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        console.log(`Non-JSON response for feature flag details ${flagName}`);
        return null;
      }

      const data: FeatureFlag = await response.json();
      return data;
    } catch (error) {
      console.log(`Error fetching feature flag details for ${flagName}:`, error instanceof Error ? error.message : error);
      return null;
    }
  }
  
  async getAllFlags(): Promise<Record<string, boolean>> {
    try {
      if (globalFlagsCache && Date.now() - globalFlagsCache.timestamp < CACHE_DURATION) {
        return globalFlagsCache.flags;
      }

      // For EMMA AI, if no backend URL is configured, return defaults
      if (!API_URL) {
        console.log('No backend URL configured, using default feature flags');
        return this._getAllDefaultFlags();
      }

      const response = await fetch(`${API_URL}/feature-flags`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        // Add timeout to prevent hanging
        signal: AbortSignal.timeout(5000),
      });

      if (!response.ok) {
        console.log(`Backend unavailable for feature flags, using defaults`);
        return this._getAllDefaultFlags();
      }

      // Check if response is actually JSON
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        console.log(`Non-JSON response for feature flags, using defaults`);
        return this._getAllDefaultFlags();
      }

      const data: FeatureFlagsResponse = await response.json();
      globalFlagsCache = {
        flags: data.flags,
        timestamp: Date.now(),
      };

      Object.entries(data.flags).forEach(([flagName, enabled]) => {
        flagCache.set(flagName, {
          value: enabled,
          timestamp: Date.now(),
        });
      });

      return data.flags;
    } catch (error) {
      console.log('Error fetching all feature flags, using defaults:', error instanceof Error ? error.message : error);
      return this._getAllDefaultFlags();
    }
  }

  private _getAllDefaultFlags(): Record<string, boolean> {
    // Default values for EMMA AI when backend is unavailable
    return {
      'custom_agents': true,
      'agent_marketplace': true,
      'mcp_module': true,
      'templates_api': true,
      'triggers_api': true,
      'workflows_api': true,
      'knowledge_base': true,
      'pipedream': true,
      'credentials_api': true,
      'suna_default_agent': true,
    };
  }

  clearCache(): void {
    flagCache.clear();
    globalFlagsCache = null;
  }

  async preloadFlags(flagNames: string[]): Promise<void> {
    try {
      const promises = flagNames.map(flagName => this.isEnabled(flagName));
      await Promise.all(promises);
    } catch (error) {
      console.error('Error preloading feature flags:', error);
    }
  }
}

const featureFlagManager = FeatureFlagManager.getInstance();

export const isEnabled = (flagName: string): Promise<boolean> => {
  return featureFlagManager.isEnabled(flagName);
};

export const isFlagEnabled = isEnabled;

export const getFlagDetails = (flagName: string): Promise<FeatureFlag | null> => {
  return featureFlagManager.getFlagDetails(flagName);
};

export const getAllFlags = (): Promise<Record<string, boolean>> => {
  return featureFlagManager.getAllFlags();
};

export const clearFlagCache = (): void => {
  featureFlagManager.clearCache();
};

export const preloadFlags = (flagNames: string[]): Promise<void> => {
  return featureFlagManager.preloadFlags(flagNames);
};

// React Query key factories
export const featureFlagKeys = {
  all: ['feature-flags'] as const,
  flag: (flagName: string) => [...featureFlagKeys.all, 'flag', flagName] as const,
  flagDetails: (flagName: string) => [...featureFlagKeys.all, 'details', flagName] as const,
  allFlags: () => [...featureFlagKeys.all, 'allFlags'] as const,
};

// Query functions
const fetchFeatureFlag = async (flagName: string): Promise<boolean> => {
  // Use the feature flag manager for consistent behavior
  return await featureFlagManager.isEnabled(flagName);
};

const fetchFeatureFlagDetails = async (flagName: string): Promise<FeatureFlag> => {
  // Use the feature flag manager for consistent behavior
  const details = await featureFlagManager.getFlagDetails(flagName);
  if (!details) {
    throw new Error(`Failed to fetch feature flag details for ${flagName}`);
  }
  return details;
};

const fetchAllFeatureFlags = async (): Promise<Record<string, boolean>> => {
  // Use the feature flag manager for consistent behavior
  return await featureFlagManager.getAllFlags();
};

// React Query Hooks
export const useFeatureFlag = (flagName: string, options?: {
  enabled?: boolean;
  staleTime?: number;
  gcTime?: number;
  refetchOnWindowFocus?: boolean;
}) => {
  const query = useQuery({
    queryKey: featureFlagKeys.flag(flagName),
    queryFn: () => fetchFeatureFlag(flagName),
    staleTime: options?.staleTime ?? 5 * 60 * 1000, // 5 minutes
    gcTime: options?.gcTime ?? 10 * 60 * 1000, // 10 minutes
    refetchOnWindowFocus: options?.refetchOnWindowFocus ?? false,
    enabled: options?.enabled ?? true,
    retry: (failureCount, error) => {
      // Don't retry on 4xx errors, but retry on network errors
      if (error instanceof Error && error.message.includes('4')) {
        return false;
      }
      return failureCount < 3;
    },
    meta: {
      errorMessage: `Failed to fetch feature flag: ${flagName}`,
    },
  });

  // Return backward-compatible interface
  return {
    enabled: query.data ?? false,
    loading: query.isLoading,
    // Also expose React Query properties for advanced usage
    ...query,
  };
};

export const useFeatureFlagDetails = (flagName: string, options?: {
  enabled?: boolean;
  staleTime?: number;
  gcTime?: number;
}) => {
  return useQuery({
    queryKey: featureFlagKeys.flagDetails(flagName),
    queryFn: () => fetchFeatureFlagDetails(flagName),
    staleTime: options?.staleTime ?? 5 * 60 * 1000, // 5 minutes
    gcTime: options?.gcTime ?? 10 * 60 * 1000, // 10 minutes
    enabled: options?.enabled ?? true,
    retry: (failureCount, error) => {
      if (error instanceof Error && error.message.includes('4')) {
        return false;
      }
      return failureCount < 3;
    },
  });
};

export const useAllFeatureFlags = (options?: {
  enabled?: boolean;
  staleTime?: number;
  gcTime?: number;
}) => {
  return useQuery({
    queryKey: featureFlagKeys.allFlags(),
    queryFn: fetchAllFeatureFlags,
    staleTime: options?.staleTime ?? 5 * 60 * 1000, // 5 minutes
    gcTime: options?.gcTime ?? 10 * 60 * 1000, // 10 minutes
    enabled: options?.enabled ?? true,
    retry: (failureCount, error) => {
      if (error instanceof Error && error.message.includes('4')) {
        return false;
      }
      return failureCount < 3;
    },
  });
};

export const useFeatureFlags = (flagNames: string[], options?: {
  enabled?: boolean;
  staleTime?: number;
  gcTime?: number;
}) => {
  const queries = useQueries({
    queries: flagNames.map((flagName) => ({
      queryKey: featureFlagKeys.flag(flagName),
      queryFn: () => fetchFeatureFlag(flagName),
      staleTime: options?.staleTime ?? 5 * 60 * 1000, // 5 minutes
      gcTime: options?.gcTime ?? 10 * 60 * 1000, // 10 minutes
      enabled: options?.enabled ?? true,
      retry: (failureCount: number, error: Error) => {
        if (error.message.includes('4')) {
          return false;
        }
        return failureCount < 3;
      },
    })),
  });

  // Transform the results into a more convenient format
  const flags = React.useMemo(() => {
    const result: Record<string, boolean> = {};
    flagNames.forEach((flagName, index) => {
      const query = queries[index];
      result[flagName] = query.data ?? false;
    });
    return result;
  }, [queries, flagNames]);

  const loading = queries.some(query => query.isLoading);
  const error = queries.find(query => query.error)?.error?.message ?? null;

  return { flags, loading, error };
};
