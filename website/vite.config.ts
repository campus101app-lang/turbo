import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import tsconfigPaths from "vite-tsconfig-paths";
import { nodePolyfills } from "vite-plugin-node-polyfills";
import path from "path";

const frontendRoot = path.resolve(__dirname);
const repoRoot = path.resolve(__dirname, "..");

export default defineConfig(({ mode }) => {
  const envLocal = loadEnv(mode, frontendRoot, "");
  const envRepo = loadEnv(mode, repoRoot, "");
  const cloneApiPort = Number(
    process.env.CLONE_API_PORT ||
      envLocal.CLONE_API_PORT ||
      envRepo.CLONE_API_PORT ||
      8788,
  );

  return {
  plugins: [
    react(),
    tsconfigPaths(),
    nodePolyfills({
      include: ["buffer"],
      globals: { Buffer: true },
    }),
  ],
  resolve: {
    dedupe: ["@stellar/stellar-base", "@stellar/stellar-sdk"],
    alias: {
      "@": path.resolve(__dirname, "src"),
      "@/pages": path.resolve(__dirname, "src/pages"),
      "@/sections": path.resolve(__dirname, "src/sections"),
      "@/components": path.resolve(__dirname, "src/components"),
      "@/hooks": path.resolve(__dirname, "src/hooks"),
      "@/services": path.resolve(__dirname, "src/services"),
      "@/state": path.resolve(__dirname, "src/state"),
      "@/utils": path.resolve(__dirname, "src/utils"),
      "@/config": path.resolve(__dirname, "src/config"),
      "@/types": path.resolve(__dirname, "src/types"),
      "@/dev": path.resolve(__dirname, "src/dev"),
    },
  },
  server: {
    port: 3000,
    open: true,
    proxy: {
      "/api": {
        target: `http://127.0.0.1:${cloneApiPort}`,
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: "build",
    sourcemap: true,
  },
  css: {
    preprocessorOptions: {
      scss: {},
    },
  },
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: "./src/test/setup.ts",
    server: {
      deps: {
        inline: [/@csstools/],
      },
    },
  },
  };
});
