/**
 * @akaoio/stacker Test Suite using @akaoio/battle
 * Shell framework testing with PTY emulation
 */
import { Battle } from "@akaoio/battle"

async function runTests() {
  console.log('🚀 @akaoio/stacker Test Suite (Powered by @akaoio/battle)\n')

  const tests = [
    // Shell CLI Tests
    {
      name: 'Shell: Version Command',
      command: 'bash',
      args: ['stacker.sh', 'version'],
      expect: ['Stacker', 'v0.0.2']
    },
    {
      name: 'Shell: Help Command', 
      command: 'bash',
      args: ['stacker.sh', 'help'],
      expect: ['Usage:', 'stacker']
    },
    {
      name: 'Shell: POSIX Compliance',
      command: '/bin/sh',
      args: ['stacker.sh', 'version'],  
      expect: ['Stacker']
    },
    // TypeScript API Tests
    {
      name: 'API: TypeScript Import',
      command: 'node',
      args: ['--input-type=module', '-e', `import { Stacker } from './dist/index.js'; console.log('Stacker API loaded');`],
      expect: ['Stacker API loaded']
    }
  ]

  let passed = 0
  let failed = 0

  for (const test of tests) {
    process.stdout.write(`Testing: ${test.name}... `)
    
    const battle = new Battle({
      timeout: 15000
    })

    try {
      const result = await battle.run(async (b) => {
        b.spawn(test.command, test.args || [])
        
        for (const pattern of test.expect) {
          await b.expect(pattern, 10000)
        }
      })

      if (result.success) {
        console.log('✅ PASSED')
        passed++
      } else {
        console.log('❌ FAILED')
        console.log(`  ${result.error}`)
        failed++
      }
    } catch (error) {
      console.log('❌ FAILED')
      console.log(`  ${error}`)
      failed++
    }
  }

  console.log('\n==================================================')
  console.log(`📊 Results: ${passed} passed, ${failed} failed`)
  console.log('==================================================')

  if (failed > 0) {
    console.log(`\n❌ Some tests failed. @akaoio/stacker needs fixes.`)
    process.exit(1)
  } else {
    console.log('\n✅ All tests passed! @akaoio/stacker is battle-tested.')
  }
}

// Run tests
runTests().catch(error => {
  console.error('💥 Test runner failed:', error)
  process.exit(1)
})