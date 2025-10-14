# nixpkgs-update-gha

> [!WARNING]
> **This project is currently in testing phase.**
>
> Features may not work as expected and breaking changes may occur without notice. Use at your own risk.

Automatically update and maintain your nixpkgs packages using GitHub Actions and [nixpkgs-update](https://github.com/nix-community/nixpkgs-update).

## Features

- Scheduled package updates (configurable cron)
- Parallel updates for multiple packages
- Automatic PR creation to nixpkgs
- Duplicate PR detection
- Powered by [nixpkgs-update](https://github.com/nix-community/nixpkgs-update) for reliable updates
- Optional nixpkgs-review integration
- Optional CVE vulnerability reporting
- Manual on-demand updates

## Setup

### 1. Fork this repository

[Fork](https://github.com/delafthi/nixpkgs-update-gha/fork) this repository to your GitHub account.

### 2. Enable GitHub Actions

In your fork, go to the [Actions](../../actions) tab and enable GitHub Actions workflows.

### 3. Configure GitHub Token

Create a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) for nixpkgs operations:

1. Go to <https://github.com/settings/tokens> and generate a new **fine-grained** token with `pull_requests:write` and `contents:write` permissions for the target repository (NixOS/nixpkgs or your fork).
2. In your fork, go to "Settings" > "Secrets and variables" > "Actions" and [add a new repository secret](../../settings/secrets/actions/new) with the name `GH_TOKEN` and set its value to the personal access token you generated.

### 4. Configure Packages to Watch

Set the list of packages you want to automatically update:

1. In your fork, go to "Settings" > "Secrets and variables" > "Actions" > "Variables" tab
2. [Create a new repository variable](../../settings/variables/actions/new) with the name `PACKAGES`
3. Set its value to a semicolon-separated list of packages:
   - Simple format: `hello;neovim;firefox` (versions auto-discovered)
   - With explicit versions: `postman 7.20.0 7.21.2;hello`

   **Note:** For packages without GitHub releases or updateScript, you must provide explicit versions.

### 5. Adjust Update Schedule (optional)

The default schedule runs updates on Monday and Friday at 2 AM UTC. To customize this:

1. Edit `.github/workflows/update.yml`
2. Modify the cron expression on line 5:
   ```yaml
   - cron: "0 2 * * 1,5" # Monday and Friday at 2 AM UTC
   ```

Common cron patterns:

- `0 2 * * 1,5` - Monday and Friday at 2 AM UTC
- `0 6 * * *` - Every day at 6 AM UTC
- `0 */12 * * *` - Every 12 hours
- `0 0 * * 0` - Every Sunday at midnight UTC

### 6. Configure Default Behavior (optional)

You can set default values for workflow behavior using repository variables:

1. In your fork, go to "Settings" > "Secrets and variables" > "Actions" > "Variables" tab
2. Create any of the following optional variables:

| Variable            | Default         | Description                                   |
| ------------------- | --------------- | --------------------------------------------- |
| `SKIP_IF_PR_EXISTS` | `true`          | Skip updates if a PR already exists           |
| `NIXPKGS_REVIEW`    | `true`          | Run nixpkgs-review on updates                 |
| `CVE_REPORT`        | `false`         | Generate CVE vulnerability reports            |
| `NIXPKGS_REPO`      | `NixOS/nixpkgs` | Target repository (use your fork for testing) |

**Note:** When manually triggering updates, you can override these variables by providing workflow inputs. If no input is provided for a setting, the corresponding repository variable will be used.

## Usage

### Automatic Updates (Scheduled)

Once configured, the workflow will automatically run on the schedule defined in `.github/workflows/update.yml` (default: Monday and Friday at 2 AM UTC) and update all packages listed in the `PACKAGES` variable.

### Manual Updates (On-Demand)

To manually trigger updates:

1. Go to the [update workflow in the "Actions" tab](../../actions/workflows/update.yml)
2. Click "Run workflow"
3. (Optional) Enter a semicolon-separated list of packages to update (overrides `PACKAGES`)
   - Examples: `hello` or `postman 7.20.0 7.21.2;neovim`
4. (Optional) Override default settings:
   - **Skip if PR exists**: Skip packages that already have open PRs
   - **nixpkgs-review**: Run nixpkgs-review on updates
   - **CVE report**: Generate CVE vulnerability reports
5. Click "Run workflow"

**Note:** All inputs are optional. If not provided, the workflow will use the corresponding repository variables (`PACKAGES`, `SKIP_IF_PR_EXISTS`, `NIXPKGS_REVIEW`, `CVE_REPORT`).

### Viewing Results

After the workflow runs:

1. Check the [Actions](../../actions) tab to see the workflow execution
2. Each package update runs as a separate job in the matrix
3. If PRs were created, you'll find links in the job logs
4. If nixpkgs-review is enabled, the report will be included in the PR body

## How It Works

### Workflow Overview

1. **prepare-matrix** job parses the package list (from workflow input or `PACKAGES` variable)
2. **update** job runs in parallel for each package using a matrix strategy
3. For each package:
   - Check if a PR already exists on the target repository
   - Skip if PR exists (unless `skip-if-pr-exists` is disabled)
   - Clone nixpkgs and setup git environment with upstream remote
   - Discover versions if only package name provided (via GitHub releases or updateScript)
   - Run [nixpkgs-update](https://github.com/nix-community/nixpkgs-update) with `--pr` flag which:
     - Updates version strings and hashes (or runs updateScript if available)
     - Runs package-specific update scripts
     - Builds the package to verify it works
     - Creates a properly formatted commit
     - Pushes to a branch and creates/updates the PR automatically
     - Includes nixpkgs-review report (if enabled)
     - Includes CVE vulnerability report (if enabled)

### PR Format

Pull requests are created directly by nixpkgs-update and follow the nixpkgs standard format:

- Title: `package-name: old-version → new-version`
- Body includes:
  - Detailed update information and checks from nixpkgs-update
  - nixpkgs-review report with build results (if `--nixpkgs-review` enabled)
  - CVE vulnerability report (if `--cve` enabled)
  - Links to successful builds and relevant information

## Configuration Reference

### Repository Variables

| Variable            | Required | Default         | Description                                    | Example                |
| ------------------- | -------- | --------------- | ---------------------------------------------- | ---------------------- |
| `PACKAGES`          | Yes      | -               | Semicolon-separated list of packages to update | `hello;neovim;firefox` |
| `SKIP_IF_PR_EXISTS` | No       | `true`          | Skip updates if a PR already exists            | `true`                 |
| `NIXPKGS_REVIEW`    | No       | `true`          | Run nixpkgs-review on updates                  | `true`                 |
| `CVE_REPORT`        | No       | `false`         | Generate CVE vulnerability reports             | `false`                |
| `NIXPKGS_REPO`      | No       | `NixOS/nixpkgs` | Target repository for PRs                      | `username/nixpkgs`     |

### Repository Secrets

| Secret     | Required | Description                                                                           |
| ---------- | -------- | ------------------------------------------------------------------------------------- |
| `GH_TOKEN` | Yes      | GitHub fine-grained token with `pull_requests:write` and `contents:write` permissions |

### Workflow Inputs (Manual Dispatch)

| Input               | Required | Default                    | Description                                    |
| ------------------- | -------- | -------------------------- | ---------------------------------------------- |
| `packages`          | No       | (uses `PACKAGES`)          | Semicolon-separated list of packages to update |
| `skip-if-pr-exists` | No       | (uses `SKIP_IF_PR_EXISTS`) | Skip packages that already have open PRs       |
| `nixpkgs-review`    | No       | (uses `NIXPKGS_REVIEW`)    | Run nixpkgs-review on updates                  |
| `cve-report`        | No       | (uses `CVE_REPORT`)        | Generate CVE vulnerability reports             |

## Troubleshooting

### Updates not running automatically

- Check that GitHub Actions is enabled in your fork
- Verify the workflow is enabled in Actions tab
- Check that `PACKAGES` variable is set correctly

### PRs not being created

- Ensure `GH_TOKEN` secret is set with correct permissions
- Check workflow logs for error messages
- Verify the package name is correct

### No changes detected

- The package may already be up-to-date
- nixpkgs-update may not have found a new version
- Check the workflow logs for details from nixpkgs-update

### Build failures

- Check the workflow logs for build errors from nixpkgs-update
- The new version may have introduced breaking changes
- Consider running nixpkgs-review locally to investigate

## License

MIT
