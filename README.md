# nixpkgs-update-gha

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-blue.svg)](https://github.com/features/actions)

> [!WARNING]
> **This project is currently in testing phase.**
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
- Benefit from **immediate maintainer attention** on updates

**Examples**: Actively developed CLI tools, IDE plugins, fast-moving frameworks, or packages you personally depend on for daily development.

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
   - Fork [nixpkgs](https://github.com/NixOS/nixpkgs) and note your fork name (e.g., `username/nixpkgs`)
   - Fork [this repository](https://github.com/delafthi/nixpkgs-update-gha/fork)

2. **Create GitHub token**
   - Generate a [fine-grained token](https://github.com/settings/tokens) with `pull_requests:write` and `contents:write`
   - Add it as secret `GH_TOKEN` in your fork's [Settings → Secrets and variables → Actions](../../settings/secrets/actions/new)

3. **Configure variables**
   - Go to [Settings → Secrets and variables → Actions → Variables](../../settings/variables/actions)
   - Add `PACKAGES` (e.g., `hello neovim firefox`)
   - Add `NIXPKGS_FORK` (e.g., `username/nixpkgs`)
   - Add `NIXPKGS_REPO` (e.g., `NixOS/nixpkgs`)

4. **Enable workflows**
   - Go to the [Actions tab](../../actions) and enable GitHub Actions

5. **Test manually**
   - Navigate to [Actions → Update packages](../../actions/workflows/update.yml)
   - Click **Run workflow** to trigger your first update

For detailed configuration and troubleshooting, see the [Setup](#setup) section below.

## Features

- **Automated updates** with configurable schedules
- **Parallel processing** of multiple packages
- **Smart PR management** with duplicate detection
- **Package-specific updates** using each package's `updateScript`
- **Quality checks** via [nixpkgs-review](https://github.com/Mic92/nixpkgs-review)
- **Manual control** for on-demand updates

## Prerequisites

- **GitHub account** with permissions to:
  - Create and manage repositories
  - Generate personal access tokens
  - Enable GitHub Actions workflows
- **nixpkgs fork** for pushing update branches ([create fork](https://github.com/NixOS/nixpkgs/fork))
- **Basic knowledge** of:
  - GitHub Actions workflow basics
  - nixpkgs package structure and contribution process
  - Nix package management (helpful but not required)

## Setup

### 1. Fork nixpkgs

Fork nixpkgs to have a repository where update branches will be pushed:

1. Navigate to <https://github.com/NixOS/nixpkgs> and click **Fork**
2. Note your fork's repository name (format: `username/nixpkgs`)

### 2. Fork this repository

[Fork](https://github.com/delafthi/nixpkgs-update-gha/fork) this repository to your GitHub account.

### 3. Enable GitHub Actions

In your fork, go to the [Actions](../../actions) tab and enable GitHub Actions workflows.

### 4. Configure GitHub Token

Create a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) for nixpkgs operations:

1. Navigate to <https://github.com/settings/tokens> and generate a new **fine-grained** token
2. Grant the following permissions:
   - `pull_requests:write` - Create and update pull requests
   - `contents:write` - Push branches to your nixpkgs fork
3. In your fork of nixpkgs-update-gha, navigate to **Settings** → **Secrets and variables** → **Actions**
4. [Add a new repository secret](../../settings/secrets/actions/new):
   - Name: `GH_TOKEN`
   - Value: Your generated personal access token

### 5. Configure Required Variables

Set the required variables for the workflow:

1. In your fork of nixpkgs-update-gha, navigate to **Settings** → **Secrets and variables** → **Actions** → **Variables** tab
2. [Create the following repository variables](../../settings/variables/actions/new):

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
   - Use `NixOS/nixpkgs` for upstream pull requests
   - Use your fork (e.g., `username/nixpkgs`) for testing
   - **Required**: No default value to prevent accidental PRs to upstream

### 6. Customize Update Schedule (optional)

Default: Tuesday and Friday at 3:00 AM UTC. Edit the cron expression on line 5 in `.github/workflows/update.yml`:

```yaml
- cron: "0 3 * * 2,5" # Tuesday and Friday at 3 AM UTC
```

Use [crontab.guru](https://crontab.guru/) to create custom schedules.

### 7. Configure Default Behavior (optional)

Add `SKIP_IF_PR_EXISTS=false` to update packages even when PRs exist (default: `true`). Manual runs can override this.

### 8. Configure External nixpkgs-review-gha (optional)

To integrate [nixpkgs-review-gha](https://github.com/Defelo/nixpkgs-review-gha):

1. Fork and configure nixpkgs-review-gha per its documentation
2. Add variables: `NIXPKGS_REVIEW_GHA=true` and `NIXPKGS_REVIEW_GHA_REPO=username/nixpkgs-review-gha`

This triggers external reviews after PR creation.

## Usage

### Scheduled Updates (Automatic)

Once configured, the workflow runs automatically based on the schedule in `.github/workflows/update.yml` (default: Tuesday and Friday at 3:00 AM UTC).

### Manual Updates (On-Demand)

Trigger updates manually:

1. Go to [Actions tab](../../actions/workflows/update.yml) → **Run workflow**
2. Configure inputs (optional - falls back to repository variables):
   - **Packages**: Override `PACKAGES` variable
   - **Skip if PR exists**: Override `SKIP_IF_PR_EXISTS`
   - **Trigger nixpkgs-review-gha**: Override `NIXPKGS_REVIEW_GHA`

### Viewing Results

View workflow runs in the [Actions tab](../../actions). Each package runs as a separate job, and successful updates create PRs on nixpkgs with build results and logs.

## How It Works

### Workflow Architecture

#### 1. Prepare Matrix Job

Parses package list, validates configuration, and creates matrix for parallel processing.

#### 2. Update Job (Parallel Execution)

Each package update:

1. **Check for existing PRs** - Skip if one exists (configurable)
2. **Setup environment** - Clone nixpkgs, install Nix, configure git
3. **Update package** - Run `maintainers/scripts/update.nix` which executes the package's `updateScript` to:
   - Discover latest version from upstream sources
   - Update version strings and recalculate hashes
   - Create properly formatted commit
4. **Build and verify** - Build the updated package and capture:
   - Build logs for debugging and transparency
   - Store path information
   - Build success/failure status
5. **Create PR** - Push to fork and create PR with:
   - Build verification results
   - Collapsible build logs section
   - Store path details
   - Metadata (commit hash, comparison link, workflow run)

### PR Format

PRs use nixpkgs standard format with title `package-name: old-version → new-version` and include:
- Build verification status with platform information
- Collapsible build logs section showing the last 100 lines of output
- Store path of the built package
- Commit metadata and workflow links for traceability
- Optional comprehensive review status if nixpkgs-review-gha is enabled

### Concurrency Control

Workflows prevent duplicate PRs through concurrency controls at both workflow and package levels. Maximum 3 parallel jobs to respect API rate limits.

## Configuration Reference

### Repository Variables

| Variable                  | Required | Description                       | Example           |
| ------------------------- | -------- | --------------------------------- | ----------------- |
| `PACKAGES`                | Yes      | Space-separated list of packages  | `hello neovim`    |
| `NIXPKGS_FORK`            | Yes      | Your nixpkgs fork                 | `user/nixpkgs`    |
| `NIXPKGS_REPO`            | Yes      | Target repository for PRs         | `NixOS/nixpkgs`   |
| `SKIP_IF_PR_EXISTS`       | No       | Skip if PR exists (default: true) | `true`            |
| `NIXPKGS_REVIEW_GHA`      | No       | Trigger external review           | `false`           |
| `NIXPKGS_REVIEW_GHA_REPO` | No       | Your nixpkgs-review-gha fork      | `user/review-gha` |

### Repository Secrets

| Secret     | Required | Description                            |
| ---------- | -------- | -------------------------------------- |
| `GH_TOKEN` | Yes      | GitHub token with PR/write permissions |

See [Setup](#setup) for detailed configuration instructions.

## Troubleshooting

### Workflow fails with "variable is required"

**Solution**: Configure all required variables in [Setup](#setup) section (step 5).

### Package update is skipped

**Cause**: Open PR exists and `SKIP_IF_PR_EXISTS` is `true`.

**Solution**: Disable `skip-if-pr-exists` when manually triggering, or close the existing PR.

### Package update fails

**Solution**: Verify package exists (`nix search nixpkgs#packagename`) and has an `updateScript` (`nix eval nixpkgs#packagename.updateScript`). Check workflow logs for details.

### PR creation fails with authentication error

**Solution**: Regenerate `GH_TOKEN` with `pull_requests:write` and `contents:write` permissions, and update the secret.

### nixpkgs-review build fails

**Solution**: Review workflow logs and fix build errors manually. PR is still created despite build failures.

### Workflow times out

**Solution**: Adjust `timeout-minutes` in `.github/workflows/update-package.yml` (line 46).

### Transient API failures

**Solution**: Re-run the workflow manually. Check [GitHub status](https://www.githubstatus.com/) if issues persist.

## Contributing

Contributions are welcome! Here are some ways to contribute:

- **Report issues**: Found a bug or have a feature request? [Open an issue](../../issues/new)
- **Submit PRs**: Improvements to workflows, documentation, or code are appreciated
- **Share feedback**: Let us know how you're using nixpkgs-update-gha

Before contributing, please:

- Check existing [issues](../../issues) and [pull requests](../../pulls)
- Follow the existing code style (see [AGENTS.md](AGENTS.md) for guidelines)
- Test your changes with `nix flake check` and `nix fmt`

## License

This project is licensed under the [MIT License](LICENSE).
