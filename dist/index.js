import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
class Stacker {
  stackerPath;
  initialized = false;
  loadedModules = [];
  constructor(options = {}) {
    this.stackerPath = options.stackerPath || this.findStackerPath();
    if (!this.stackerPath) {
      throw new Error("Stacker framework not found. Install with: npm install @akaoio/stacker");
    }
  }
  /**
   * Find Stacker installation path
   */
  findStackerPath() {
    const possiblePaths = [
      // Current package
      path.join(__dirname, "..", "stacker.sh"),
      // Development
      path.join(process.cwd(), "stacker.sh"),
      // Global installation
      path.join(process.env.HOME || "", ".local", "bin", "stacker"),
      // System installation
      "/usr/local/bin/stacker"
    ];
    for (const stackerPath of possiblePaths) {
      if (fs.existsSync(stackerPath)) {
        return stackerPath;
      }
    }
    return "";
  }
  /**
   * Initialize Stacker for a project
   */
  async init(config) {
    if (this.initialized) return;
    const script = `
      "${this.stackerPath}" init \\
        --name="${config.name}" \\
        ${config.repository ? `--repo="${config.repository}"` : ""} \\
        ${config.executable ? `--script="${config.executable}"` : ""} \\
        ${config.description ? `--description="${config.description}"` : ""}
    `;
    try {
      execSync(script, { stdio: "inherit" });
      this.initialized = true;
    } catch (error) {
      throw new Error(`Failed to initialize Stacker: ${error}`);
    }
  }
  /**
   * Install application using Stacker
   */
  async install(options = {}) {
    const args = [];
    if (options.systemd) args.push("--systemd");
    if (options.cron) args.push("--cron");
    if (options.manual) args.push("--manual");
    if (options.interval) args.push(`--interval=${options.interval}`);
    if (options.autoUpdate) args.push("--auto-update");
    const script = `"${this.stackerPath}" install ${args.join(" ")}`;
    try {
      execSync(script, { stdio: "inherit" });
    } catch (error) {
      throw new Error(`Installation failed: ${error}`);
    }
  }
  /**
   * Control services
   */
  async service(action) {
    const script = `"${this.stackerPath}" service ${action}`;
    try {
      return execSync(script, { encoding: "utf8" });
    } catch (error) {
      throw new Error(`Service ${action} failed: ${error}`);
    }
  }
  /**
   * Update application
   */
  async update(options = {}) {
    const args = [];
    if (options.check) args.push("--check");
    if (options.force) args.push("--force");
    const script = `"${this.stackerPath}" update ${args.join(" ")}`;
    try {
      execSync(script, { stdio: "inherit" });
    } catch (error) {
      throw new Error(`Update failed: ${error}`);
    }
  }
  /**
   * Get configuration value
   */
  async getConfig(key) {
    const script = `"${this.stackerPath}" config get "${key}"`;
    try {
      return execSync(script, { encoding: "utf8" }).trim();
    } catch (error) {
      throw new Error(`Failed to get config ${key}: ${error}`);
    }
  }
  /**
   * Set configuration value
   */
  async setConfig(key, value) {
    const script = `"${this.stackerPath}" config set "${key}" "${value}"`;
    try {
      execSync(script, { stdio: "inherit" });
    } catch (error) {
      throw new Error(`Failed to set config ${key}: ${error}`);
    }
  }
  /**
   * Health check
   */
  async health(verbose = false) {
    const script = `"${this.stackerPath}" health ${verbose ? "--verbose" : ""}`;
    try {
      const output = execSync(script, { encoding: "utf8" });
      return {
        healthy: true,
        output: output.trim()
      };
    } catch (error) {
      return {
        healthy: false,
        error
      };
    }
  }
  /**
   * Get version info
   */
  async version() {
    const script = `"${this.stackerPath}" version`;
    try {
      return execSync(script, { encoding: "utf8" }).trim();
    } catch (error) {
      return "0.0.2";
    }
  }
  /**
   * Execute raw Stacker command
   */
  async exec(command, args = []) {
    const script = `"${this.stackerPath}" ${command} ${args.join(" ")}`;
    try {
      return execSync(script, { encoding: "utf8" });
    } catch (error) {
      throw new Error(`Command failed: ${script} - ${error}`);
    }
  }
  /**
   * Package management
   */
  async addPackage(packageUrl, scope = "local") {
    const script = `"${this.stackerPath}" add "${packageUrl}" --${scope}`;
    try {
      execSync(script, { stdio: "inherit" });
    } catch (error) {
      throw new Error(`Failed to add package: ${error}`);
    }
  }
  /**
   * Remove package
   */
  async removePackage(packageName, scope = "local") {
    const script = `"${this.stackerPath}" remove "${packageName}" --${scope}`;
    try {
      execSync(script, { stdio: "inherit" });
    } catch (error) {
      throw new Error(`Failed to remove package: ${error}`);
    }
  }
  /**
   * List packages
   */
  async listPackages(scope) {
    const script = `"${this.stackerPath}" list ${scope ? `--${scope}` : ""}`;
    try {
      const output = execSync(script, { encoding: "utf8" });
      return output.split("\n").filter((line) => line.trim());
    } catch (error) {
      return [];
    }
  }
  /**
   * Search packages
   */
  async searchPackages(query) {
    const script = `"${this.stackerPath}" search "${query}"`;
    try {
      const output = execSync(script, { encoding: "utf8" });
      return output.split("\n").filter((line) => line.trim() && line.includes("gh:"));
    } catch (error) {
      return [];
    }
  }
  /**
   * Static helper: Check if Stacker is available
   */
  static isAvailable() {
    const instance = new Stacker();
    return Boolean(instance.stackerPath);
  }
  /**
   * Static helper: Get Stacker version
   */
  static async getVersion() {
    if (!this.isAvailable()) return "not installed";
    const instance = new Stacker();
    return await instance.version();
  }
}
var index_default = Stacker;
const stacker = new Stacker();
const StackerUtils = {
  /**
   * Quick health check
   */
  async isHealthy() {
    try {
      const result = await stacker.health();
      return result.healthy;
    } catch {
      return false;
    }
  },
  /**
   * Safe initialization with error handling
   */
  async safeInit(config) {
    try {
      await stacker.init(config);
      return true;
    } catch (error) {
      console.warn("Stacker initialization failed:", error);
      return false;
    }
  },
  /**
   * Install with fallback
   */
  async install(options = {}) {
    try {
      await stacker.install(options);
      return true;
    } catch (error) {
      console.warn("Stacker installation failed:", error);
      return false;
    }
  }
};

export { Stacker, StackerUtils, index_default as default, stacker };
//# sourceMappingURL=index.js.map
//# sourceMappingURL=index.js.map