'use client';

import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  ReactNode,
} from 'react';
import { createClient } from '@/lib/supabase/client';
import { User, Session } from '@supabase/supabase-js';
import { SupabaseClient } from '@supabase/supabase-js';
import { checkAndInstallSunaAgent } from '@/lib/utils/install-suna-agent';

type AuthContextType = {
  supabase: SupabaseClient;
  session: Session | null;
  user: User | null;
  isLoading: boolean;
  signOut: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const supabase = createClient();
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const getInitialSession = async () => {
      try {
        const {
          data: { session: currentSession },
        } = await supabase.auth.getSession();
        setSession(currentSession);
        setUser(currentSession?.user ?? null);
      } catch (error) {
        // Silently handle auth errors for EMMA AI - no authentication required
        console.log('Auth session not available, continuing without authentication');
        setSession(null);
        setUser(null);
      } finally {
        setIsLoading(false);
      }
    };

    getInitialSession();

    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (event, newSession) => {
        try {
          setSession(newSession);
          setUser(newSession?.user ?? null);

          if (isLoading) setIsLoading(false);
          switch (event) {
            case 'SIGNED_IN':
              if (newSession?.user) {
                try {
                  await checkAndInstallSunaAgent(newSession.user.id, newSession.user.created_at);
                } catch (error) {
                  console.log('Failed to install agent, continuing without authentication');
                }
              }
              break;
            case 'SIGNED_OUT':
              break;
            case 'TOKEN_REFRESHED':
              break;
            case 'MFA_CHALLENGE_VERIFIED':
              break;
            default:
          }
        } catch (error) {
          console.log('Auth state change error, continuing without authentication');
          setSession(null);
          setUser(null);
          if (isLoading) setIsLoading(false);
        }
      },
    );

    return () => {
      authListener?.subscription.unsubscribe();
    };
  }, [supabase]); // Removed isLoading from dependencies to prevent infinite loops

  const signOut = async () => {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      console.error('❌ Error signing out:', error);
    }
  };

  const value = {
    supabase,
    session,
    user,
    isLoading,
    signOut,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    // For EMMA AI, return a default context instead of throwing an error
    console.log('useAuth used outside AuthProvider, returning default values');
    return {
      supabase: createClient(),
      session: null,
      user: null,
      isLoading: false,
      signOut: async () => {},
    };
  }
  return context;
};
