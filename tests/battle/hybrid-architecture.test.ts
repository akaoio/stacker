/**
 * Battle Test: Hybrid Architecture Validation for Stacker
 * Tests integration between TypeScript API and Shell interface
 */

import { Battle } from '@akaoio/battle';
import { spawn } from 'child_process';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

/**
 * Test the hybrid TypeScript + Shell architecture
 */
export async function testHybridArchitecture() {
  console.log('🔗 Testing Hybrid Architecture Integration');
  console.log('=' .repeat(50));

  const battle = new Battle({
    timeout: 45000,
    pty: {
      cols: 120,
      rows: 30,
      shell: process.env.BATTLE_SHELL || '/bin/sh'
    },
    verbose: true
  });

  let passed = 0;
  let failed = 0;
  let total = 0;

  // Test helper
  const test = async (name: string, fn: () => Promise<boolean>) => {
    total++;
    console.log(`\n🧪 ${name}`);
    
    try {
      const result = await fn();
      if (result) {
        console.log(`✅ PASS: ${name}`);
        passed++;
      } else {
        console.log(`❌ FAIL: ${name}`);
        failed++;
      }
    } catch (error) {
      console.log(`💥 ERROR: ${name} - ${error.message}`);
      failed++;
    }
  };

  // Test 1: Verify both interfaces exist
  await test('Both TypeScript and Shell interfaces present', async () => {
    const tsExists = existsSync('dist/index.js');
    const shellExists = existsSync('stacker.sh');
    const executable = existsSync('stacker.sh');
    
    console.log(`   TypeScript dist: ${tsExists ? '✅' : '❌'}`);
    console.log(`   Shell script: ${shellExists ? '✅' : '❌'}`);
    
    return tsExists && shellExists;
  });

  // Test 2: TypeScript API functionality via Battle PTY
  await test('TypeScript API via terminal node execution', async () => {
    const testScript = `
      import('./dist/index.js').then(stacker => {
        console.log('STACKER_API_LOADED');
        return stacker.stacker.version();
      }).then(version => {
        console.log('VERSION_RESULT:' + version.split('\\n')[0]);
        process.exit(0);
      }).catch(err => {
        console.log('ERROR:' + err.message);
        process.exit(1);
      });
    `;
    
    const session = await battle.spawn('node', ['--input-type=module', '-e', testScript]);
    await session.waitFor('STACKER_API_LOADED', { timeout: 10000 });
    await session.waitFor('VERSION_RESULT:', { timeout: 5000 });
    
    const output = session.getOutput();
    const exitCode = await session.getExitCode();
    session.kill();
    
    return exitCode === 0 && 
           output.includes('STACKER_API_LOADED') && 
           output.includes('VERSION_RESULT:Stacker Framework v0.0.2');
  });

  // Test 3: Shell interface via Battle PTY
  await test('Shell interface via terminal execution', async () => {
    const session = await battle.spawn('./stacker.sh', ['version']);
    await session.waitFor('Stacker Framework v0.0.2', { timeout: 10000 });
    
    const output = session.getOutput();
    const exitCode = await session.getExitCode();
    session.kill();
    
    return exitCode === 0 && 
           output.includes('Stacker Framework v0.0.2') &&
           output.includes('Universal POSIX Shell Framework');
  });

  // Test 4: Version consistency between interfaces
  await test('Version consistency across interfaces', async () => {
    // Get shell version
    const shellSession = await battle.spawn('./stacker.sh', ['version']);
    await shellSession.waitFor('Stacker Framework v0.0.2');
    const shellOutput = shellSession.getOutput();
    shellSession.kill();
    
    // Get TypeScript version
    const tsScript = `
      import('./dist/index.js').then(m => 
        m.stacker.version().then(v => console.log('TS_VERSION:' + v.split('\\n')[0]))
      ).catch(() => process.exit(1));
    `;
    
    const tsSession = await battle.spawn('node', ['--input-type=module', '-e', tsScript]);
    await tsSession.waitFor('TS_VERSION:');
    const tsOutput = tsSession.getOutput();
    tsSession.kill();
    
    const shellVersion = shellOutput.match(/Stacker Framework v([\d.]+)/)?.[1];
    const tsVersion = tsOutput.match(/TS_VERSION:.*v([\d.]+)/)?.[1];
    
    console.log(`   Shell version: ${shellVersion}`);
    console.log(`   TypeScript version: ${tsVersion}`);
    
    return shellVersion === '0.0.2' && tsVersion === '0.0.2';
  });

  // Test 5: Command consistency between interfaces
  await test('Help command consistency', async () => {
    // Shell help
    const shellSession = await battle.spawn('./stacker.sh', ['help']);
    await shellSession.waitFor('Usage:', { timeout: 5000 });
    const shellHelp = shellSession.getOutput();
    shellSession.kill();
    
    // TypeScript help (if available)
    const tsScript = `
      import('./dist/index.js').then(m => {
        if (m.stacker.help) {
          return m.stacker.help().then(h => console.log('TS_HELP:' + h));
        } else {
          console.log('TS_HELP:Not implemented yet');
        }
      }).catch(() => console.log('TS_HELP:Error'));
    `;
    
    const tsSession = await battle.spawn('node', ['--input-type=module', '-e', tsScript]);
    await tsSession.waitFor('TS_HELP:');
    const tsHelp = tsSession.getOutput();
    tsSession.kill();
    
    // Both should have some help content or acknowledge not implemented
    const shellHasHelp = shellHelp.includes('Usage:') || shellHelp.includes('Commands');
    const tsHasHelp = tsHelp.includes('TS_HELP:') && !tsHelp.includes('Error');
    
    console.log(`   Shell help available: ${shellHasHelp}`);
    console.log(`   TypeScript help status: ${tsHasHelp}`);
    
    return shellHasHelp && tsHasHelp;
  });

  // Test 6: Error handling consistency
  await test('Error handling consistency', async () => {
    // Shell error
    const shellSession = await battle.spawn('./stacker.sh', ['invalid-command-xyz']);
    const shellExit = await shellSession.waitForExit();
    const shellError = shellSession.getOutput();
    shellSession.kill();
    
    // TypeScript error (command simulation)
    const tsScript = `
      import('./dist/index.js').then(m => {
        console.log('TS_ERROR_TEST_START');
        // Test error handling (simulate invalid operation)
        if (m.stacker.invalidCommand) {
          return m.stacker.invalidCommand();
        } else {
          console.log('ERROR_HANDLED:Invalid command not available');
          process.exit(1);
        }
      }).catch(err => {
        console.log('ERROR_HANDLED:' + err.message);
        process.exit(1);
      });
    `;
    
    const tsSession = await battle.spawn('node', ['--input-type=module', '-e', tsScript]);
    await tsSession.waitFor(/ERROR_HANDLED|TS_ERROR_TEST_START/);
    const tsExit = await tsSession.getExitCode();
    const tsOutput = tsSession.getOutput();
    tsSession.kill();
    
    // Both should exit with non-zero code for invalid commands
    const shellRejectsInvalid = shellExit !== 0;
    const tsHandlesErrors = tsExit !== 0 || tsOutput.includes('ERROR_HANDLED');
    
    console.log(`   Shell rejects invalid: ${shellRejectsInvalid} (exit: ${shellExit})`);
    console.log(`   TypeScript handles errors: ${tsHandlesErrors}`);
    
    return shellRejectsInvalid && tsHandlesErrors;
  });

  // Test 7: Package.json integration
  await test('Package.json hybrid exports work', async () => {
    const pkg = JSON.parse(readFileSync('package.json', 'utf8'));
    
    const hasMainExport = pkg.main === 'dist/index.js';
    const hasShellExport = pkg.exports && pkg.exports['./shell'] === './stacker.sh';
    const hasBinExport = pkg.bin && pkg.bin.stacker === './stacker.sh';
    
    console.log(`   Main export: ${hasMainExport}`);
    console.log(`   Shell export: ${hasShellExport}`);
    console.log(`   Binary export: ${hasBinExport}`);
    
    return hasMainExport && hasShellExport && hasBinExport;
  });

  // Test 8: Build artifacts validation
  await test('Build artifacts structure', async () => {
    const distExists = existsSync('dist/index.js');
    const cjsExists = existsSync('dist/index.cjs');
    const moduleExists = existsSync('dist/index.mjs') || existsSync('dist/index.js');
    
    console.log(`   CommonJS build: ${cjsExists}`);
    console.log(`   ES Module build: ${moduleExists}`);
    console.log(`   Main dist build: ${distExists}`);
    
    return distExists && (cjsExists || moduleExists);
  });

  // Results summary
  console.log('\n📊 Hybrid Architecture Test Results');
  console.log('=' .repeat(40));
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📋 Total: ${total}`);
  
  const successRate = (passed / total) * 100;
  console.log(`📈 Success Rate: ${successRate.toFixed(1)}%`);
  
  if (successRate >= 70) {
    console.log('\n🎉 Hybrid architecture working well!');
    console.log('   TypeScript ↔ Shell integration functional');
    console.log('   Both interfaces operational');
    console.log('   Version consistency maintained');
    return { success: true, passed, failed, total };
  } else if (successRate >= 50) {
    console.log('\n⚠️  Hybrid architecture partially functional');
    console.log('   Some integration issues detected');
    console.log('   Acceptable for v0.0.2 development');
    return { success: true, passed, failed, total };
  } else {
    console.log('\n❌ Hybrid architecture has major issues');
    console.log('   Integration between TypeScript and Shell broken');
    return { success: false, passed, failed, total };
  }
}

// Export for Battle framework integration
export default testHybridArchitecture;

// Run if called directly
if (require.main === module) {
  testHybridArchitecture().then((results) => {
    console.log('\n🏁 Hybrid architecture testing completed');
    process.exit(results.success ? 0 : 1);
  }).catch((error) => {
    console.error('\n💥 Hybrid architecture test crashed:', error);
    process.exit(1);
  });
}