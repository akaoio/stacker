# Stacker Installation Guide v0.0.2

**Universal POSIX Shell Framework - Hybrid Shell + TypeScript Architecture**

## 📦 NPM Installation (Recommended)

### Global Installation

```bash
# Install globally (requires appropriate permissions)
npm install -g @akaoio/stacker

# Use stacker command anywhere
stacker version
stacker help
stacker init my-project
```

### Local Project Installation

```bash
# Install in your project
npm install @akaoio/stacker

# Use from node_modules
./node_modules/.bin/stacker version

# Or with npx
npx stacker version
```

### TypeScript/Node.js Integration

```typescript
// Import the hybrid interface
import { Stacker, stacker, StackerUtils } from '@akaoio/stacker';

// Use singleton instance
const version = await stacker.version();
console.log(version);

// Or create custom instance
const custom = new Stacker();
await custom.init({
  name: 'my-app',
  repository: 'https://github.com/user/my-app.git'
});
```

## 🐚 Manual Shell Installation

### Direct Script Usage

```bash
# Clone repository
git clone https://github.com/akaoio/stacker.git
cd stacker

# Use directly
./stacker.sh version
./stacker.sh help
```

### System Installation

```bash
# Clone and build
git clone https://github.com/akaoio/stacker.git
cd stacker
npm run build

# Self-install globally
./stacker.sh self-install
```

## 🔧 Development Installation

### From Source (Early Development v0.0.2)

```bash
# Clone repository
git clone https://github.com/akaoio/stacker.git
cd stacker

# Install dependencies
npm install

# Build TypeScript interface
npm run build

# Run tests
npm test

# Install globally from source
npm link
```

## 🧪 Testing Installation

### Verify Shell Interface

```bash
# Check version (should show 0.0.2)
stacker version

# Test basic commands
stacker help
stacker config list
stacker search test

# Test package management
stacker add gh:akaoio/air
stacker list
```

### Verify TypeScript Interface

```javascript
// test-stacker.js
import { stacker } from '@akaoio/stacker';

// Test hybrid architecture
const version = await stacker.version();
console.log('Version:', version);

const health = await stacker.health();
console.log('Health:', health);
```

```bash
node test-stacker.js
```

## ⚠️ Known Issues (v0.0.2 Early Development)

### Permission Issues
- Global installation may require `sudo` on some systems
- Use `npm config set prefix ~/.npm-global` for user-space installation
- Add `~/.npm-global/bin` to your `$PATH`

### Compatibility Notes
- Requires Node.js ≥16 for TypeScript interface
- Shell interface works on any POSIX-compliant system
- Some features incomplete in v0.0.2 (honest development versioning)

### Troubleshooting

```bash
# If global command not found
export PATH="$PATH:~/.npm-global/bin"

# If module loading fails
export STACKER_DIR="/path/to/stacker"

# If TypeScript imports fail
npm install @akaoio/stacker --save
```

## 📋 Installation Verification

### Quick Test Script

```bash
#!/bin/sh
# test-installation.sh

echo "🧪 Testing Stacker Installation v0.0.2"

# Test 1: Shell availability
if command -v stacker >/dev/null 2>&1; then
    echo "✅ Stacker shell command available"
    stacker version
else
    echo "❌ Stacker shell command not found"
fi

# Test 2: Node.js availability  
if node -e "import('@akaoio/stacker')" >/dev/null 2>&1; then
    echo "✅ Stacker TypeScript module available"
else
    echo "❌ Stacker TypeScript module not found"
fi

echo "📋 Installation test complete"
```

## 🚀 Quick Start After Installation

```bash
# Initialize new project
stacker init my-service --template=service

# Install as system service
stacker install --systemd --auto-update

# Add packages
stacker add gh:akaoio/air
stacker add gh:akaoio/access

# Check status
stacker status
stacker health --verbose
```

## 📚 Next Steps

After installation:

1. **Read Documentation**: `stacker help`
2. **Run Tests**: `npm test` (if from source)
3. **Initialize Project**: `stacker init`
4. **Check Health**: `stacker health`
5. **Explore Examples**: See `examples/` directory

## 🐛 Reporting Issues

This is **v0.0.2 early development**:

- Expected failures are normal
- Report issues: https://github.com/akaoio/stacker/issues
- Include version: `stacker version`
- Include system: `uname -a`

---

*Installation guide for Stacker v0.0.2 - Honest development versioning*