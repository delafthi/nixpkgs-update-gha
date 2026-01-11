# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- **Check flake**: `nix flake check` or `nix flake check --system <system>` (test across all systems in loop)
- **Format check**: `nix build .#checks.x86_64-linux.treefmt`
- **Format code**: `nix fmt`
- **Build flake**: `nix build`
- **Update flake**: `nix flake update`
- **Development shell**: `nix develop` (includes nixd, treefmt tools)

## Workflow Architecture

This project automates nixpkgs package updates using GitHub Actions. The core workflow (`.github/workflows/update-packages.yml`) orchestrates package updates through three main phases:

### Phase 1: Parse Inputs & Prepare Matrix

- **parse-inputs job**: Validates configuration (GH_TOKEN, NIXPKGS_REPO, NIXPKGS_FORK, PACKAGES)
- **prepare-matrix job**: Transforms package list into JSON matrix for parallel execution

### Phase 2: Update Job (Parallel Execution)

Each package update runs through these steps:

1. **PR deduplication**: Check for existing PRs with `package:` prefix in title
1. **Environment setup**: Checkout nixpkgs, install Nix, configure Magic Nix Cache
1. **Update package**: Run `maintainers/scripts/update.nix` which executes the package's `updateScript`
1. **Extract metadata**: Get description, homepage, changelog, maintainers via `nix eval`
1. **Build verification**: Run `nixpkgs-review wip` to build and verify changes
1. **Version verification**: Check for version string in output/filename
1. **Run tests**: Execute `passthru.tests` if available and track pass/fail counts
1. **Create PR**: Push to fork and create PR with r-ryantm-style formatting
1. **Trigger review**: Optionally trigger external nixpkgs-review-gha workflow

### Phase 3: PR Creation

PRs include:

- Package metadata (description, homepage, changelog)
- Updates performed section
- Checks done (build status, version verification, passthru.tests results)
- Rebuild report with workflow run logs link
- nixpkgs-review results
- Maintainer pings

### Workflow Control Flow

Key conditionals and dependencies:

- Jobs run only if previous jobs succeed and outputs are valid
- Each step checks `steps.check-pr.outputs.exists == 'false'` to skip if PR exists
- Steps also check `steps.update.outputs.has-changes == 'true'` to skip if no changes
- Maximum 1 parallel job (controlled by `max-parallel` in strategy) to respect API rate limits

### External Integration

Optional integration with [nixpkgs-review-gha](https://github.com/Defelo/nixpkgs-review-gha) for multi-platform testing:

- Triggered after PR creation if `NIXPKGS_REVIEW_GHA=true`
- Passes PR number to `review.yml` workflow in external repository

## Supporting Workflows

- **check-flake.yml**: Multi-system flake validation (x86_64-linux, aarch64-linux, aarch64-darwin)
- **update-flake.yml**: Daily flake.lock updates with auto-merge label (non-forks only)
- **sync-fork.yml**: Daily fork synchronization with upstream (forks only)
- **auto-merge.yml**: Auto-merge PRs labeled with `auto-merge` after checks pass
- **status-check.yml**: Reusable workflow for validating job results (used by check-flake.yml)

## Code Style

- **Commit messages**: Use `chore:` prefix for automation commits
- **Comments**: Use shell comments in YAML run blocks to explain complex logic
- **Concurrency**: Set `group:` and `cancel-in-progress:` to prevent overlapping runs
- **Conditionals**: Use `if:` with proper expression syntax; prefer `steps.id.outputs.var == 'value'`
- **Env vars**: Define at workflow level when used across multiple steps
- **Error handling**: Always check exit codes; use `::error::`, `::warning::`, and `::notice::` in workflows
- **Formatting**: Use `nixfmt` for Nix files, `yamlfmt` for YAML, `mdformat` for Markdown; `keep-sorted` for lists
- **Indentation**: 2 spaces for YAML, nixfmt defaults for Nix
- **Language**: Nix (flake-based) and GitHub Actions YAML
- **Multi-system**: Support x86_64-linux, aarch64-linux, aarch64-darwin, x86_64-darwin
- **Naming**: kebab-case for workflow files, job names, and step names
- **Permissions**: Explicitly declare minimal required permissions for each job
- **Secrets**: Use `${{ secrets.GH_TOKEN }}` for GitHub operations requiring elevated permissions
- **Sorted lists**: Use `# keep-sorted start/end` comments for sorted lists (flake inputs, etc.)

<!-- keep-sorted end -->

- **Timeout**: Always set `timeout-minutes` on jobs (typically 10-30 minutes)
- **Tools**: Use `gh` CLI for GitHub operations, `jq` for JSON processing

## Key Implementation Patterns

### Version Extraction

Old/new versions are extracted from git diff by searching for `version =` or `pversion =` patterns:

```bash
old_version=$(git diff | grep -E '^\-.*version\s*=\s*"' | head -1 | sed -E 's/.*"([^"]*)".*/\1/' || echo "unknown")
new_version=$(git diff | grep -E '^\+.*version\s*=\s*"' | head -1 | sed -E 's/.*"([^"]*)".*/\1/' || nix eval --raw ".#$package.version" || echo "unknown")
```

### nixpkgs-review Integration

Review directory is located by matching git HEAD hash:

```bash
review_dir=""
for dir in "${HOME}/.cache/nixpkgs-review/rev-${head_hash}"{,-dirty}; do
  if [ -d "$dir" ]; then
    review_dir="$dir"
    break
  fi
done
```

Extract results from `report.md` by taking content after first `---` separator.

### passthru.tests Execution

Tests are discovered, executed individually, and tracked:

```bash
tests=$(nix eval --json ".#$package.passthru.tests" | jq -r 'keys[]')
for test in $tests; do
  if nix build ".#$package.passthru.tests.$test" --no-link; then
    passed_tests="${passed_tests}${test} "
  else
    failed_tests="${failed_tests}${test} "
  fi
done
```

### PR Deduplication

Checks for existing PRs with package name prefix (case-insensitive):

```bash
matches=$(gh pr list --repo "$NIXPKGS_REPO" --state open --json number,title --limit 1000 \
  | jq -c --arg pkg "$package" 'map(select(.title | ascii_downcase | startswith($pkg + ":")))')
```

## Configuration Variables

Required repository variables (Settings → Secrets and variables → Actions → Variables):

- `PACKAGES`: Space-separated list of packages (e.g., `hello neovim firefox`)
- `NIXPKGS_FORK`: Your nixpkgs fork (format: `username/nixpkgs`)
- `NIXPKGS_REPO`: Target repository for PRs (format: `owner/repo`)

Optional:

- `NIXPKGS_REVIEW_GHA`: Enable external review trigger (`true`/`false`)
- `NIXPKGS_REVIEW_GHA_REPO`: External review repository (format: `username/repo`)

Required repository secrets:

- `GH_TOKEN`: GitHub classic token with `public_repo` and `workflow` scopes
