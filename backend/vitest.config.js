// backend/vitest.config.js
//
// Vitest Configuration for Comprehensive Testing
// Configures test runner, coverage, and performance monitoring
//

import { defineConfig } from 'vitest/config';
import { resolve } from 'path';

export default defineConfig({
  test: {
    // Test environment
    environment: 'node',
    
    // Global setup
    globalSetup: './tests/setup.js',
    
    // Test files
    include: [
      'tests/**/*.test.js',
      'tests/**/*.spec.js',
    ],
    
    // Exclude files
    exclude: [
      'node_modules',
      'dist',
      '.git',
      'coverage',
    ],
    
    // Test timeout
    testTimeout: 30000,
    hookTimeout: 10000,
    
    // Coverage configuration
    coverage: {
      reporter: ['text', 'json', 'html', 'lcov'],
      reportsDirectory: './coverage',
      
      // Coverage thresholds
      thresholds: {
        global: {
          branches: 90,
          functions: 90,
          lines: 90,
          statements: 90,
        },
        
        // Per-file thresholds
        './src/services/': {
          branches: 95,
          functions: 95,
          lines: 95,
          statements: 95,
        },
        
        './src/routes/': {
          branches: 85,
          functions: 85,
          lines: 85,
          statements: 85,
        },
        
        './src/middleware/': {
          branches: 90,
          functions: 90,
          lines: 90,
          statements: 90,
        },
      },
      
      // Include files in coverage
      include: [
        'src/**/*.js',
        '!src/**/*.test.js',
        '!src/**/*.spec.js',
        '!src/migrations/**',
        '!src/scripts/**',
      ],
      
      // Exclude from coverage
      exclude: [
        'src/index.js', // Main entry point
        'src/config/**',
        'node_modules/**',
        'coverage/**',
        'tests/**',
      ],
    },
    
    // Performance monitoring
    bail: 10, // Stop after 10 failures
    maxConcurrency: 10,
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: false,
        isolate: true,
      },
    },
    
    // Reporting
    reporter: [
      'verbose',
      'json',
      'html',
      'junit',
    ],
    outputFile: {
      json: './test-results/results.json',
      html: './test-results/index.html',
      junit: './test-results/junit.xml',
    },
    
    // Globals
    globals: true,
    
    // Watch mode
    watch: false,
    
    // Retry failed tests
    retry: 2,
    
    // Performance benchmarks
    benchmark: {
      include: ['tests/**/*.benchmark.js'],
      exclude: ['node_modules'],
    },
  },
  
  // Resolve configuration
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@tests': resolve(__dirname, './tests'),
    },
  },
  
  // Define constants
  define: {
    __TEST__: true,
    __VERSION__: JSON.stringify(process.env.npm_package_version || '1.0.0'),
  },
});
