/**
 * @akaoio/stacker - Universal Shell Framework TypeScript Interface
 * Version: 0.0.2 (Honest development versioning)
 *
 * Hybrid architecture: Shell foundation + TypeScript API
 * Provides both shell and Node.js interfaces for maximum compatibility
 */
interface StackerConfig {
    name: string;
    description: string;
    repository?: string;
    executable: string;
    version: string;
    configDir: string;
    dataDir: string;
    stackerPath: string;
}
interface StackerInstallOptions {
    systemd?: boolean;
    cron?: boolean;
    manual?: boolean;
    interval?: number;
    autoUpdate?: boolean;
}
interface StackerModuleInfo {
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
declare class Stacker {
    private stackerPath;
    private initialized;
    private loadedModules;
    constructor(options?: {
        stackerPath?: string;
    });
    /**
     * Find Stacker installation path
     */
    private findStackerPath;
    /**
     * Initialize Stacker for a project
     */
    init(config: {
        name: string;
        repository?: string;
        executable?: string;
        description?: string;
    }): Promise<void>;
    /**
     * Install application using Stacker
     */
    install(options?: StackerInstallOptions): Promise<void>;
    /**
     * Control services
     */
    service(action: "start" | "stop" | "restart" | "status" | "enable" | "disable"): Promise<string>;
    /**
     * Update application
     */
    update(options?: {
        check?: boolean;
        force?: boolean;
    }): Promise<void>;
    /**
     * Get configuration value
     */
    getConfig(key: string): Promise<string>;
    /**
     * Set configuration value
     */
    setConfig(key: string, value: string): Promise<void>;
    /**
     * Health check
     */
    health(verbose?: boolean): Promise<any>;
    /**
     * Get version info
     */
    version(): Promise<string>;
    /**
     * Execute raw Stacker command
     */
    exec(command: string, args?: string[]): Promise<string>;
    /**
     * Package management
     */
    addPackage(packageUrl: string, scope?: "local" | "user" | "system"): Promise<void>;
    /**
     * Remove package
     */
    removePackage(packageName: string, scope?: "local" | "user" | "system"): Promise<void>;
    /**
     * List packages
     */
    listPackages(scope?: "local" | "user" | "system"): Promise<string[]>;
    /**
     * Search packages
     */
    searchPackages(query: string): Promise<string[]>;
    /**
     * Static helper: Check if Stacker is available
     */
    static isAvailable(): boolean;
    /**
     * Static helper: Get Stacker version
     */
    static getVersion(): Promise<string>;
}

/**
 * Singleton instance for global use
 */
declare const stacker: Stacker;
/**
 * Utility functions for common operations
 */
declare const StackerUtils: {
    /**
     * Quick health check
     */
    isHealthy(): Promise<boolean>;
    /**
     * Safe initialization with error handling
     */
    safeInit(config: {
        name: string;
        repository?: string;
        executable?: string;
        description?: string;
    }): Promise<boolean>;
    /**
     * Install with fallback
     */
    install(options?: StackerInstallOptions): Promise<boolean>;
};

export { Stacker, type StackerConfig, type StackerInstallOptions, type StackerModuleInfo, StackerUtils, Stacker as default, stacker };
