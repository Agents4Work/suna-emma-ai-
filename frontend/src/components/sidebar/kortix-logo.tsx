'use client';

import { useTheme } from 'next-themes';
import { useEffect, useState } from 'react';

interface EmmaLogoProps {
  size?: number;
}
export function EmmaLogo({ size = 24 }: EmmaLogoProps) {
  const { theme, systemTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  // After mount, we can access the theme
  useEffect(() => {
    setMounted(true);
  }, []);

  const shouldInvert = mounted && (
    theme === 'dark' || (theme === 'system' && systemTheme === 'dark')
  );

  return (
    <div
      className={`${shouldInvert ? 'text-white' : 'text-black'} flex-shrink-0 font-bold flex items-center justify-center`}
      style={{ width: size, height: size, minWidth: size, minHeight: size, fontSize: size * 0.4 }}
    >
      EMMA
    </div>
  );
}

// Keep the old export for backward compatibility
export const KortixLogo = EmmaLogo;
