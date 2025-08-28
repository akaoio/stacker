/**
 * @akaoio/stacker - Builder Configuration
 * Hybrid TypeScript + Shell framework build setup
 */

export default {
  // Project metadata
  name: "@akaoio/stacker",
  version: "0.0.2",
  
  // Entry point
  entry: "src/index.ts",
  
  // Output configuration - multiple formats for maximum compatibility
  outDir: "dist",
  formats: ["esm", "cjs"],
  
  // Platform targets
  platform: "node",
  target: "node",
  
  // TypeScript configuration
  typescript: {
    declaration: false, // Temporarily disabled due to type resolution issues
    declarationMap: false,
    skipLibCheck: true
  },
  
  // Bundle configuration
  bundle: true,
  splitting: true,
  treeshake: true,
  minify: false, // Keep readable for debugging during 0.0.x development
  
  // External dependencies (don't bundle Node.js built-ins)
  external: [
    "child_process",
    "fs", 
    "path",
    "url",
    "os",
    "process"
  ],
  
  // Source maps for development
  sourcemap: true,
  
  // File outputs
  outputs: {
    // ES Module (modern)
    "index.mjs": {
      format: "esm",
      platform: "node"
    },
    // CommonJS (compatibility)
    "index.cjs": {
      format: "cjs", 
      platform: "node"
    },
    // Standard JS (auto-detect)
    "index.js": {
      format: "cjs",
      platform: "node"
    }
  },
  
  // Development mode
  watch: process.env.NODE_ENV === "development",
  
  // Build hooks
  hooks: {
    "build:start": () => console.log("🔨 Building Stacker TypeScript interface..."),
    "build:complete": () => console.log("✅ Stacker build complete - hybrid shell+TS ready!")
  },
  
  // Copy static assets
  copy: [
    { from: "stacker.sh", to: "stacker.sh" },
    { from: "stacker-loader.sh", to: "stacker-loader.sh" },
    { from: "modules/", to: "modules/" },
    { from: "README.md", to: "README.md" }
  ],
  
  // Clean before build
  clean: true,
  
  // Development server (for testing)
  dev: {
    port: 3000,
    host: "localhost"
  }
};