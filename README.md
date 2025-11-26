# nixpkgs-update-gha

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-blue.svg)](https://github.com/features/actions)

> [!WARNING]
> **This project is currently in a testing state.**
>
> Features may not work as expected and breaking changes may occur without notice. Use at your own risk.

Automate nixpkgs package maintenance with GitHub Actions. Keep your packages up-to-date with scheduled updates, automatic PR creation, and built-in quality checks using each package's defined `updateScript` and [nixpkgs-review](https://github.com/Mic92/nixpkgs-review).

## When to Use This

**This tool is designed for maintainers of fast-moving packages** that receive updates more frequently than the standard nixpkgs automation can handle.

### Standard nixpkgs Update Tools

For most packages, the **recommended approach** is to rely on the nixpkgs ecosystem's standard automated update infrastructure:

- **[nixpkgs-update](https://github.com/nix-community/nixpkgs-update)**: The official, comprehensive update bot that handles thousands of packages
- **[r-ryantm bot](https://github.com/ryantm/nixpkgs-update)**: The GitHub account that submits automatic update PRs

These tools provide thorough, well-tested updates for the entire nixpkgs ecosystem.

### When nixpkgs-update-gha Makes Sense

Use **nixpkgs-update-gha** if you maintain packages that:

- Release **multiple times per week** (e.g., development tools, browsers, editors)
- Require **same-day updates** for security patches or critical bug fixes
- Need **custom update schedules** aligned with upstream release cycles

**Examples**: Actively developed CLI tools, fast-moving frameworks, or packages you personally depend on for daily development.

> [!NOTE]
> This tool **complements** rather than replaces nixpkgs-update. It gives package maintainers direct control over update timing for their specific packages while the broader ecosystem continues to benefit from the standard automation.

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Quick Start

**Essential steps to get started:**

1. **Fork repositories**

   - Fork [this repository](https://github.com/delafthi/nixpkgs-update-gha/fork)

1. **Create GitHub token**

   - Generate a [classic token](https://github.com/settings/tokens) with `public_repo` and `workflow` scopes
   - Add it as secret `GH_TOKEN` in your fork's [Settings → Secrets and variables → Actions](../../settings/secrets/actions/new)

1. **Configure variables**

   - Go to [Settings → Secrets and variables → Actions → Variables](../../settings/variables/actions)
   - Add `PACKAGES` (e.g., `hello neovim firefox`)
   - Add `NIXPKGS_FORK` (e.g., `username/nixpkgs`)
   - Add `NIXPKGS_REPO` (e.g., `username/nixpkgs` for testing, `NixOS/nixpkgs` for production)

1. **Enable workflows**

   - Go to the [Actions tab](../../actions) and enable GitHub Actions

1. **Test manually**

   - Navigate to [Actions → Update packages](../../actions/workflows/update-packages.yml)
   - Click **Run workflow** to trigger your first update

For detailed configuration and troubleshooting, see the [Setup](#setup) section below.

## Features

- **Automated package updates** with configurable schedules
- **Parallel processing** of multiple packages (max 3 concurrent)
- **Smart PR management** with duplicate detection
- **Package-specific updates** using each package's `updateScript`
- **Quality checks** via [nixpkgs-review](https://github.com/Mic92/nixpkgs-review)
- **Automatic test execution** for packages with `passthru.tests`
- **Detailed PR reports** with build logs, version verification, and test results
- **Manual control** for on-demand updates

## Setup

### 1. Fork nixpkgs

Fork nixpkgs to have a repository where update branches will be pushed:

1. Navigate to <https://github.com/NixOS/nixpkgs> and click **Fork**
1. Note your fork's repository name (format: `username/nixpkgs`)

### 2. Fork this repository

[Fork](https://github.com/delafthi/nixpkgs-update-gha/fork) this repository to your GitHub account.

### 3. Enable GitHub Actions

In your fork of nixpkgs-update-gha, go to the [Actions](../../actions) tab and enable GitHub Actions workflows.

### 4. Configure GitHub Token

Create a [personal access token (classic)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#personal-access-tokens-classic) for nixpkgs operations:

1. Navigate to <https://github.com/settings/tokens> and click **Generate new token (classic)**
1. Set a descriptive note (e.g., "nixpkgs-update-gha")
1. Select the following scopes:
   - `public_repo` (to create PRs to public repositories like NixOS/nixpkgs)
   - `workflow` (if using nixpkgs-review-gha integration)
1. Click **Generate token** and copy the token value
1. In your fork of nixpkgs-update-gha, navigate to **Settings** → **Secrets and variables** → **Actions**
1. [Add a new repository secret](../../settings/secrets/actions/new):
   - Name: `GH_TOKEN`
   - Value: Your generated personal access token

> **Important**: You must use a **classic** personal access token, not a fine-grained token. Fine-grained tokens cannot create PRs to repositories you don't own (like NixOS/nixpkgs).

### 5. Configure Required Variables

Set the required variables for the workflow:

1. In your fork of nixpkgs-update-gha, navigate to **Settings** → **Secrets and variables** → **Actions** → **Variables** tab

1. [Create the following repository variables](../../settings/variables/actions/new):

   **`PACKAGES`** (required)

   - Space-separated list of packages to update
   - Example: `hello neovim firefox`
   - Packages are updated using their defined `updateScript` via `maintainers/scripts/update.nix`

   **`NIXPKGS_FORK`** (required)

   - Your nixpkgs fork repository
   - Format: `username/nixpkgs`
   - Example: `octocat/nixpkgs`

   **`NIXPKGS_REPO`** (required)

   - Target repository where PRs will be created
   - Format: `owner/repository`
   - **Testing**: Set to your fork (e.g., `username/nixpkgs`) to test workflow without creating PRs on upstream
   - **Production**: Set to `NixOS/nixpkgs` for upstream pull requests
   - **Required**: No default value to prevent accidental PRs to upstream

### 6. Customize Update Schedule (optional)

Default: Tuesday and Friday at 3:00 AM UTC. Edit the cron expression in `.github/workflows/update-packages.yml`:

```yaml
- cron: "0 3 * * 2,5" # Tuesday and Friday at 3 AM UTC
```

Use [crontab.guru](https://crontab.guru/) to create custom schedules.

### 7. Configure External nixpkgs-review-gha (optional)

To integrate [nixpkgs-review-gha](https://github.com/Defelo/nixpkgs-review-gha):

1. Fork and configure nixpkgs-review-gha per its documentation
1. Add repository variables:
   - `NIXPKGS_REVIEW_GHA=true`
   - `NIXPKGS_REVIEW_GHA_REPO=username/nixpkgs-review-gha`

This triggers the `review.yml` workflow in your nixpkgs-review-gha repository after PR creation, passing the PR number for automated review.

## Usage

### Scheduled Updates (Automatic)

Once configured, the workflow runs automatically on Tuesday and Friday at 3:00 AM UTC.

### Manual Updates (On-Demand)

Trigger package updates manually:

1. Go to [Actions → Update packages](../../actions/workflows/update-packages.yml)
1. Click **Run workflow**
1. Configure inputs (optional - falls back to repository variables):
   - **Packages**: Override `PACKAGES` variable
   - **Trigger external nixpkgs-review-gha workflow**: Override `NIXPKGS_REVIEW_GHA`
   - **Repository containing nixpkgs-review-gha workflow**: Override `NIXPKGS_REVIEW_GHA_REPO`

### Viewing Results

View workflow runs in the [Actions tab](../../actions). Each package runs as a separate job, and successful updates create PRs with build results and logs.

## How It Works

### Workflow Architecture

The update workflow (`.github/workflows/update-packages.yml`) runs on schedule (Tuesday/Friday at 3 AM UTC) or manually.

**Parse Inputs Job:**

- Validates `GH_TOKEN` secret and required variables
- Validates repository and package name formats
- Prepares configuration for update jobs

**Prepare Matrix Job:**

- Transforms package list into JSON matrix for parallel execution
- Validates matrix is not empty

**Update Job (Parallel Execution):**

Each package update:

1. **Check for existing PRs** - Skip if a PR with title `package: ...` exists
1. **Setup environment** - Checkout nixpkgs, install Nix, setup Magic Nix Cache
1. **Update package** - Run `maintainers/scripts/update.nix` which executes the package's `updateScript`:
   - Discover latest version from upstream sources
   - Update version strings and recalculate hashes
   - Derive current and new version from the changes
1. **Get package metadata** - Extract description, homepage, and changelog
1. **Run nixpkgs-review wip** - Build and verify the changes
1. **Run passthru.tests** (if available) - Execute package tests and track pass/fail results
1. **Create PR** - Push branch to fork and create PR on upstream using `gh pr create` with r-ryantm-style formatting
1. **Trigger external review** (optional) - If configured, trigger `review.yml` workflow in nixpkgs-review-gha repository

### PR Format

PRs use r-ryantm-style format with title `package-name: old-version -> new-version` and include:

- Package metadata (description, homepage, changelog)
- Updates performed section
- To inspect upstream changes links
- Checks done:
  - Build status on NixOS
  - Version verification (in output and filename)
  - passthru.tests results (if available) with pass/fail counts
- Rebuild report with direct link to workflow run logs
- nixpkgs-review results with system and build status

### Concurrency Control

Workflows prevent duplicate PRs by checking for existing PRs with matching package names. Maximum 3 parallel jobs to respect API rate limits.

## Configuration Reference

### Repository Variables

| Variable | Required | Description | Example |
| ------------------------- | -------- | -------------------------------- | ----------------- |
| `PACKAGES` | Yes | Space-separated list of packages | `hello neovim` |
| `NIXPKGS_FORK` | Yes | Your nixpkgs fork | `user/nixpkgs` |
| `NIXPKGS_REPO` | Yes | Target repository for PRs | `NixOS/nixpkgs` |
| `NIXPKGS_REVIEW_GHA` | No | Trigger external review | `false` |
| `NIXPKGS_REVIEW_GHA_REPO` | No | Your nixpkgs-review-gha fork | `user/review-gha` |

### Repository Secrets

| Secret | Required | Description |
| ---------- | -------- | -------------------------------------- |
| `GH_TOKEN` | Yes | GitHub token with PR/write permissions |

### Workflow Schedule

The update-packages workflow runs on Tuesday and Friday at 3:00 AM UTC. This can be customized by editing the cron expression in `.github/workflows/update-packages.yml`.

See [Setup](#setup) for detailed configuration instructions.

## Troubleshooting

### Workflow fails with "variable is required"

**Solution**: Configure all required variables in [Setup](#setup) section (step 5).

### Package update is skipped

**Cause**: Open PR with title `package: ...` already exists.

**Solution**: Close or merge the existing PR before running the update workflow again.

### Package update fails

**Solution**: Verify package exists (`nix search nixpkgs#packagename`) and has an `updateScript` (`nix eval nixpkgs#packagename.updateScript`). Check workflow logs for details.

### PR creation fails with authentication error

**Common errors**:

- `GraphQL: Resource not accessible by personal access token (createPullRequest)`
- `pull request create failed`

**Solution**:

1. Ensure you're using a **classic** personal access token (not fine-grained)
1. Token must have `public_repo` scope (for creating PRs to public repositories)
1. Token must have `workflow` scope (if using nixpkgs-review-gha integration)
1. Regenerate token at <https://github.com/settings/tokens> and update the `GH_TOKEN` secret

### nixpkgs-review build fails

**Solution**: Review workflow logs and fix build errors manually. PR is still created despite build failures.

### passthru.tests fail

**Solution**: Review test failure details in workflow logs. PR is still created with test results included. Failed tests are reported in the PR body for reviewer visibility.

### Workflow times out

**Solution**: Adjust `timeout-minutes` in `.github/workflows/update-packages.yml` (line 146).

### Transient API failures

**Solution**: Re-run the workflow manually. Check [GitHub status](https://www.githubstatus.com/) if issues persist.

## Contributing

Contributions are welcome! Here are some ways to contribute:

- **Report issues**: Found a bug or have a feature request? [Open an issue](../../issues/new)
- **Submit PRs**: Improvements to workflows, documentation, or code are appreciated
- **Share feedback**: Let us know how you're using nixpkgs-update-gha

Before contributing, please:

1. Check existing [issues](../../issues) and [pull requests](../../pulls)
1. Follow the existing code style (see [AGENTS.md](AGENTS.md) for guidelines)
1. Test your changes:
   - **Format**: `nix fmt` (runs nixfmt, prettier, keep-sorted)
   - **Validate**: `nix flake check` (checks all supported systems)
   - **Test workflows**: Use [act](https://github.com/nektos/act) or manual workflow runs
1. Update documentation if you change workflow behavior

## License

This project is licensed under the [MIT License](LICENSE).
