import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import tsconfigPaths from 'vite-tsconfig-paths';
import svgr from "vite-plugin-svgr";

export default defineConfig({
  plugins: [react(), tsconfigPaths(), svgr({
    include: "**/*.svg?react",
  }),],
  ssr: {
    noExternal: ['@stellar/freighter-api', '@creit.tech/stellar-wallets-kit'],
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'src/test/'],
    },
  },
});
