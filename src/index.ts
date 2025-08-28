/**
 * @akaoio/stacker - Universal Shell Framework TypeScript Interface
 * Version: 0.0.2 (Honest development versioning)
 * 
 * Hybrid architecture: Shell foundation + TypeScript API
 * Provides both shell and Node.js interfaces for maximum compatibility
 */

import { execSync, spawn, ChildProcess } from "child_process";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export interface StackerConfig {
  name: string;
  description: string;
  repository?: string;
  executable: string;
  version: string;
  configDir: string;
  dataDir: string;
  stackerPath: string;
}

export interface StackerInstallOptions {
  systemd?: boolean;
  cron?: boolean;
  manual?: boolean;
  interval?: number;
  autoUpdate?: boolean;
}

export interface StackerModuleInfo {
  name: string;
  loaded: boolean;
  dependencies: string[];
  path: string;
  description?: string;
}

/**
 * Main Stacker Framework TypeScript Interface
 * Bridges shell framework with Node.js ecosystem
 */
export class Stacker {
  private stackerPath: string;
  private initialized: boolean = false;
  private loadedModules: string[] = [];

  constructor(options: { stackerPath?: string } = {}) {
    this.stackerPath = options.stackerPath || this.findStackerPath();
    
    if (!this.stackerPath) {
      throw new Error("Stacker framework not found. Install with: npm install @akaoio/stacker");
    }
  }

  /**
   * Find Stacker installation path
   */
  private findStackerPath(): string {
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
  async init(config: {
    name: string;
    repository?: string;
    executable?: string;
    description?: string;
  }): Promise<void> {
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
  async install(options: StackerInstallOptions = {}): Promise<void> {
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
  async service(action: "start" | "stop" | "restart" | "status" | "enable" | "disable"): Promise<string> {
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
  async update(options: { check?: boolean; force?: boolean } = {}): Promise<void> {
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
  async getConfig(key: string): Promise<string> {
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
  async setConfig(key: string, value: string): Promise<void> {
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
  async health(verbose: boolean = false): Promise<any> {
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
        error: error
      };
    }
  }

  /**
   * Get version info
   */
  async version(): Promise<string> {
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
  async exec(command: string, args: string[] = []): Promise<string> {
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
  async addPackage(packageUrl: string, scope: "local" | "user" | "system" = "local"): Promise<void> {
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
  async removePackage(packageName: string, scope: "local" | "user" | "system" = "local"): Promise<void> {
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
  async listPackages(scope?: "local" | "user" | "system"): Promise<string[]> {
    const script = `"${this.stackerPath}" list ${scope ? `--${scope}` : ""}`;

    try {
      const output = execSync(script, { encoding: "utf8" });
      return output.split("\n").filter(line => line.trim());
    } catch (error) {
      return [];
    }
  }

  /**
   * Search packages
   */
  async searchPackages(query: string): Promise<string[]> {
    const script = `"${this.stackerPath}" search "${query}"`;

    try {
      const output = execSync(script, { encoding: "utf8" });
      return output.split("\n").filter(line => line.trim() && line.includes("gh:"));
    } catch (error) {
      return [];
    }
  }

  /**
   * Static helper: Check if Stacker is available
   */
  static isAvailable(): boolean {
    const instance = new Stacker();
    return Boolean(instance.stackerPath);
  }

  /**
   * Static helper: Get Stacker version
   */
  static async getVersion(): Promise<string> {
    if (!this.isAvailable()) return "not installed";
    
    const instance = new Stacker();
    return await instance.version();
  }
}

/**
 * Default export for convenient importing
 */
export default Stacker;

/**
 * Singleton instance for global use
 */
export const stacker = new Stacker();

/**
 * Utility functions for common operations
 */
export const StackerUtils = {
  /**
   * Quick health check
   */
  async isHealthy(): Promise<boolean> {
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
  async safeInit(config: {
    name: string;
    repository?: string;
    executable?: string;
    description?: string;
  }): Promise<boolean> {
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
  async install(options: StackerInstallOptions = {}): Promise<boolean> {
    try {
      await stacker.install(options);
      return true;
    } catch (error) {
      console.warn("Stacker installation failed:", error);
      return false;
    }
  }
};