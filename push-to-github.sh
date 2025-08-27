#!/bin/bash
# Script to push @akaoio/manager framework to GitHub

set -e

echo "🚀 Preparing @akaoio/manager for GitHub..."

# Check if we're in the right directory
if [ ! -f "manager.sh" ] || [ ! -f "README.md" ]; then
    echo "❌ Error: Run this from the manager framework directory"
    exit 1
fi

# Check if git is available
if ! command -v git >/dev/null 2>&1; then
    echo "❌ Error: git is not installed"
    exit 1
fi

echo "📋 Repository contents:"
find . -name "*.sh" -o -name "*.md" | sort

echo ""
echo "📦 Repository structure:"
tree -I '.git' 2>/dev/null || find . -type d | sort

echo ""
echo "🔍 Final verification test..."
if ! ./manager.sh --self-status >/dev/null 2>&1; then
    echo "❌ Error: Manager framework not working"
    exit 1
fi
echo "✅ Framework verified working"

echo ""
echo "📝 Ready to push to GitHub!"
echo ""
echo "Run these commands to create and push the repository:"
echo ""
echo "# 1. Initialize git repository"
echo "git init"
echo ""
echo "# 2. Add all files"
echo "git add ."
echo ""
echo "# 3. Create initial commit"
echo 'git commit -m "feat: initial release of @akaoio/manager framework

- Universal POSIX shell framework for system management
- Full XDG Base Directory Specification compliance  
- Self-updating system with rollback capability
- Complete example implementation (simple-daemon)
- Comprehensive POSIX compliance test suite
- Works on all Unix-like systems (Linux, macOS, *BSD)
- 100% POSIX compliant, tested on sh/dash/bash/zsh
- Extractable patterns from Access, Air, and other core technologies"'
echo ""
echo "# 4. Set main branch"
echo "git branch -M main"
echo ""
echo "# 5. Add GitHub remote (REPLACE WITH ACTUAL REPO URL)"
echo "git remote add origin https://github.com/akaoio/manager.git"
echo ""
echo "# 6. Push to GitHub"
echo "git push -u origin main"
echo ""
echo "# 7. Tag first release"
echo 'git tag -a v1.0.0 -m "v1.0.0 - Universal POSIX Shell Framework

Features:
- POSIX compliant (sh, dash, bash, zsh compatible)
- XDG Base Directory Specification compliant
- Self-updating framework with rollback capability
- Service management (systemd + cron)
- Universal installer patterns
- Complete example implementation
- Comprehensive test suite
- Cross-platform compatibility (Linux, macOS, *BSD)

Ready for integration with Access and all AKAO technologies."'
echo ""
echo "# 8. Push tags"
echo "git push origin v1.0.0"
echo ""
echo "🌟 After pushing, the repository will be available at:"
echo "   https://github.com/akaoio/manager"
echo ""
echo "📚 Integration examples:"
echo "   git submodule add https://github.com/akaoio/manager.git manager"
echo "   curl -sSL https://raw.githubusercontent.com/akaoio/manager/main/manager.sh"