# Pre-commit Setup Documentation

This document explains the pre-commit configuration for both Unreal Engine repositories: `coop-game-fleep` and `simplefpstemplate_filfreire`.

## Overview

Pre-commit hooks help maintain code quality by automatically checking your code before each commit. The configuration ensures consistency across:
- C++ source code formatting
- Shell script quality
- YAML file validation
- General file hygiene

## Files Created

### Configuration Files
- `.pre-commit-config.yaml` - Main pre-commit configuration
- `.clang-format` - C++ code formatting rules (Unreal Engine style)
- `.yamllint.yaml` - YAML linting configuration

### Setup Scripts
- `scripts/setup-precommit.sh` - Bash setup script for macOS/Linux
- `scripts/setup-precommit.ps1` - PowerShell setup script for Windows

### GitHub Actions
- `.github/workflows/pre-commit.yml` - CI/CD workflow for automated checking

## What Gets Checked

### General File Checks
- Trailing whitespace removal
- Consistent file endings
- YAML syntax validation
- JSON syntax validation
- Merge conflict detection
- Large file detection (>10MB)
- Mixed line ending fixes

### C++ Code Quality
- **Formatting**: Uses clang-format with Unreal Engine coding standards
- **Style**: Allman brace style, 4-space indentation with tabs
- **Line Length**: 120 character limit
- **Consistency**: No tabs in code, consistent line endings

### Shell Scripts
- **Linting**: Uses shellcheck for best practices
- **Syntax**: Validates shell script syntax

### Unreal Engine Specific
- **Project Files**: Validates `.uproject` files are valid JSON
- **Line Endings**: Ensures consistent line endings in C++ files
- **Code Style**: Prevents tabs in C++ source files

## Setup Instructions

### Automatic Setup

#### For macOS/Linux:
```bash
cd /path/to/repository
./scripts/setup-precommit.sh
```

#### For Windows (PowerShell):
```powershell
cd C:\path\to\repository
.\scripts\setup-precommit.ps1
```

### Manual Setup

1. **Install Python and pip** (if not already installed)

2. **Install pre-commit**:
   ```bash
   pip install pre-commit
   ```

3. **Install hooks** (run from repository root):
   ```bash
   pre-commit install
   ```

4. **Test the setup** (optional but recommended):
   ```bash
   pre-commit run --all-files
   ```

## Daily Usage

### Automatic Execution
Pre-commit hooks run automatically on `git commit`. If any checks fail, the commit is blocked until issues are fixed.

### Manual Execution
```bash
# Run on staged files only
pre-commit run

# Run on all files
pre-commit run --all-files

# Run specific hook
pre-commit run clang-format

# Skip hooks for urgent commits (not recommended)
git commit --no-verify
```

### Updating Hooks
```bash
# Update all hooks to latest versions
pre-commit autoupdate
```

## GitHub Actions Integration

The repositories include a GitHub Actions workflow (`.github/workflows/pre-commit.yml`) that:
- Runs on every push and pull request
- Uses Ubuntu with Python 3.11
- Installs system dependencies (clang-format, shellcheck)
- Caches pre-commit hooks for faster execution
- Uploads results artifacts on failure

### Workflow Triggers
- Push to `master`, `main`, or `develop` branches
- Pull requests targeting those branches
- Manual workflow dispatch

## Troubleshooting

### Common Issues

1. **Pre-commit not found**:
   - Ensure Python and pip are installed
   - Install pre-commit: `pip install pre-commit`

2. **Hooks not running**:
   - Install hooks: `pre-commit install`
   - Check hooks are enabled: `ls -la .git/hooks/`

3. **Formatting failures**:
   - Let clang-format auto-fix: `pre-commit run clang-format --all-files`
   - Manually review and fix remaining issues

4. **Shell script issues**:
   - Use shellcheck suggestions to fix script problems
   - Common issues: unquoted variables, missing error handling

### Skipping Hooks (Emergency Only)
```bash
# Skip all pre-commit hooks (not recommended)
git commit --no-verify

# Skip specific files (add to .gitignore if permanent)
git commit --no-verify -m "Emergency fix"
```

## Customization

### Adding New Hooks
Edit `.pre-commit-config.yaml` to add new repositories or hooks. Example:
```yaml
- repo: https://github.com/pre-commit/mirrors-eslint
  rev: v8.44.0
  hooks:
    - id: eslint
      files: \.js$
```

### Modifying C++ Style
Edit `.clang-format` to adjust formatting rules. Key settings:
- `IndentWidth`: Number of spaces for indentation
- `ColumnLimit`: Maximum line length
- `BreakBeforeBraces`: Brace style (Allman, Linux, etc.)

### Adjusting YAML Rules
Edit `.yamllint.yaml` to modify YAML validation rules:
- `line-length.max`: Maximum line length
- `indentation.spaces`: Required indentation
- `trailing-spaces`: Trailing space handling

## Best Practices

1. **Run on all files initially**: `pre-commit run --all-files`
2. **Fix issues incrementally**: Don't try to fix everything at once
3. **Commit formatting changes separately**: Keep style fixes separate from logic changes
4. **Update hooks regularly**: `pre-commit autoupdate`
5. **Document exceptions**: If you need to skip hooks, document why

## Support

For issues or questions:
1. Check the [pre-commit documentation](https://pre-commit.com/)
2. Review specific tool documentation (clang-format, shellcheck, etc.)
3. Check GitHub Actions logs for CI failures
4. Create an issue in the repository for project-specific problems
