/**
 * @akaoio/stacker - Composer Configuration
 * Documentation generation for hybrid shell+TypeScript framework
 */

module.exports = {
  // Project metadata
  name: "@akaoio/stacker",
  version: "0.0.2",
  
  // Source configuration
  source: {
    // YAML atoms containing structured project data
    atoms: [
      "src/doc/overview.yaml",
      "src/doc/commands.yaml"
    ],
    
    // Template directory
    templates: "templates/",
    
    // Additional data sources
    package: "package.json"
  },
  
  // Output configuration
  output: {
    // Main documentation files
    "README.md": "readme.md",
    "CLAUDE.md": "claude.md", 
    "API.md": "api.md",
    "ARCHITECTURE.md": "architecture.md"
  },
  
  // Template engine configuration
  handlebars: {
    // Custom helpers for shell + TypeScript hybrid docs
    helpers: {
      // Format shell command examples
      shellExample: (command) => `\`\`\`bash\n${command}\n\`\`\``,
      
      // Format TypeScript examples
      tsExample: (code) => `\`\`\`typescript\n${code}\n\`\`\``,
      
      // Format version with honest development state
      devVersion: (version) => `${version} (Early Development - Hot Development State)`,
      
      // Hybrid usage examples (shell + TypeScript)
      hybridUsage: (shellCmd, tsCode) => {
        return `**Shell Usage:**\n\`\`\`bash\n${shellCmd}\n\`\`\`\n\n**TypeScript Usage:**\n\`\`\`typescript\n${tsCode}\n\`\`\``;
      }
    },
    
    // Template data transformation
    data: {
      // Add hybrid architecture info
      architecture: "Shell Foundation + TypeScript API",
      developmentState: "Early Development (v0.0.x)",
      honestVersioning: true
    }
  },
  
  // Generation hooks
  hooks: {
    "generate:start": () => console.log("📚 Generating Stacker documentation..."),
    "generate:complete": () => console.log("✅ Documentation generated - hybrid architecture documented!"),
    
    // Post-process generated files
    "file:generated": (filePath, content) => {
      // Add development warning to all generated docs
      if (filePath.endsWith(".md")) {
        const devWarning = `\n---\n*⚠️ Development Version 0.0.2 - API may change rapidly*\n`;
        return content + devWarning;
      }
      return content;
    }
  },
  
  // Watch mode for development
  watch: process.env.NODE_ENV === "development",
  
  // Cleanup old files before generation
  clean: true,
  
  // Include shell script documentation
  includeShellDocs: true,
  
  // TypeScript API documentation
  includeTypeScriptDocs: true
};