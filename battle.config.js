/**
 * @akaoio/stacker - Battle Testing Configuration
 * Universal terminal testing for hybrid shell+TypeScript framework
 */

export default {
  // Project metadata
  name: "@akaoio/stacker",
  version: "0.0.2",
  
  // Test discovery
  testPattern: "tests/**/*.{test,spec}.{js,ts,sh}",
  testFiles: [
    "test/battle-integration.test.ts",
    "test/battle-simple.test.ts", 
    "tests/battle/hybrid-architecture.test.ts",
    "tests/battle/shell-compatibility.test.sh"
  ],
  
  // Test environment
  environment: {
    // Shell testing environment  
    shell: "/bin/sh",
    alternateShells: ["/bin/bash", "/bin/dash"],
    
    // TypeScript testing environment
    typescript: {
      runtime: "node",
      version: ">=16"
    },
    
    // Test data directories
    fixtures: "tests/fixtures",
    tmp: "tests/tmp"
  },
  
  // Test types configuration
  testTypes: {
    // Shell script testing
    shell: {
      pattern: "tests/**/*.{test,spec}.sh",
      runner: "shell",
      timeout: 30000,
      
      // POSIX compliance testing
      posixCompliance: true,
      multiShellTesting: true,
      
      // Stacker-specific shell testing
      stackerModules: true,
      moduleLoading: true,
      errorHandling: true
    },
    
    // TypeScript API testing  
    typescript: {
      pattern: "tests/**/*.{test,spec}.{ts,js}",
      runner: "node",
      timeout: 15000,
      
      // Hybrid architecture testing
      shellIntegration: true,
      apiConsistency: true,
      errorPropagation: true
    },
    
    // Integration testing
    integration: {
      pattern: "tests/integration/**/*.{test,spec}.{ts,js,sh}",
      runner: "hybrid",
      timeout: 60000,
      
      // Cross-interface testing
      shellToTypeScript: true,
      typeScriptToShell: true,
      configConsistency: true
    }
  },
  
  // PTY configuration for terminal testing
  pty: {
    // Terminal dimensions
    cols: 80,
    rows: 24,
    
    // Shell emulation
    shell: process.env.SHELL || "/bin/sh",
    
    // Environment variables
    env: {
      TERM: "xterm-256color",
      STACKER_TEST_MODE: "true",
      STACKER_DEBUG: "false",
      CI: process.env.CI || "false"
    }
  },
  
  // Reporting configuration
  reporting: {
    // Output formats
    formats: ["console", "json", "junit"],
    
    // Report files
    output: {
      console: true,
      json: "tests/results/battle-report.json",
      junit: "tests/results/junit.xml"
    },
    
    // Coverage tracking (for TypeScript)
    coverage: {
      enabled: true,
      threshold: 70, // Early development - low threshold
      exclude: ["tests/**", "dist/**"]
    },
    
    // Screenshots for terminal testing
    screenshots: {
      enabled: true,
      path: "tests/results/screenshots",
      onFailure: true,
      onSuccess: false
    }
  },
  
  // Test data and fixtures
  fixtures: {
    // Sample Stacker projects
    projects: "tests/fixtures/projects",
    
    // Configuration files
    configs: "tests/fixtures/configs",
    
    // Mock shell environments
    shells: "tests/fixtures/shells"
  },
  
  // Hooks for test lifecycle
  hooks: {
    "test:start": () => console.log("🧪 Starting Stacker hybrid architecture tests..."),
    "test:complete": (results) => {
      console.log(`✅ Tests completed: ${results.passed}/${results.total} passed`);
      if (results.failed > 0) {
        console.log(`⚠️  Early development (v0.0.2) - ${results.failed} failures expected`);
      }
    },
    
    // Setup test environment
    "setup": async () => {
      // Ensure test directories exist
      const fs = await import('fs');
      const dirs = ['tests/tmp', 'tests/results', 'tests/results/screenshots'];
      for (const dir of dirs) {
        fs.mkdirSync(dir, { recursive: true });
      }
    },
    
    // Cleanup after tests
    "teardown": async () => {
      // Clean up temporary test files
      console.log("🧹 Cleaning up test artifacts...");
    }
  },
  
  // Early development configuration
  development: {
    // Relaxed failure thresholds for v0.0.2
    expectFailures: true,
    failureThreshold: 50, // Allow 50% failures in early development
    
    // Debug options
    verbose: true,
    keepTempFiles: true,
    
    // Experimental features testing
    experimentalFeatures: true
  },
  
  // CI/CD specific configuration
  ci: {
    // More tolerant settings for CI environments
    timeout: 60000,
    retries: 2,
    
    // CI reporting requirements
    exitOnFailure: false, // Don't exit immediately on v0.0.2 failures
    generateReports: true,
    
    // CI environment detection
    isCI: process.env.CI === 'true',
    ciProvider: process.env.GITHUB_ACTIONS ? 'github' : 'unknown',
    
    // Artifact generation
    artifacts: {
      screenshots: true,
      logs: true,
      reports: true
    }
  },
  
  // Parallel execution
  parallel: {
    enabled: true,
    workers: 2, // Conservative for early development
    
    // Test isolation
    isolation: true,
    timeout: 90000
  }
};