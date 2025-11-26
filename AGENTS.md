# Agent Guidelines for nixpkgs-update-gha

## Commands

- **Check flake**: `nix flake check` or `nix flake check --system <system>` (test across all systems in loop)
- **Format check**: `nix build .#checks.x86_64-linux.treefmt`
- **Format code**: `nix fmt`
- **Build flake**: `nix build`
- **Update flake**: `nix flake update`

## Code Style

- **Commit messages**: Use `chore:` prefix for automation commits
- **Comments**: Use shell comments in YAML run blocks to explain complex logic
- **Concurrency**: Set `group:` and `cancel-in-progress:` to prevent overlapping runs
- **Conditionals**: Use `if:` with proper expression syntax; prefer `steps.id.outputs.var == 'value'`
- **Env vars**: Define at workflow level when used across multiple steps
- **Error handling**: Always check exit codes; use `::error::`, `::warning::`, and `::notice::` in workflows
- **Formatting**: Use `nixfmt` for Nix files, `prettier` for YAML/Markdown; `keep-sorted` for lists
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
