# Project conventions

Operational conventions for this repo. The root [`CLAUDE.md`](../CLAUDE.md) covers general coding behavior; this file covers the project-specific rules. Read it when a task touches PRs, commits, branches, dependencies, testing, or the commands below.

## Nested CLAUDE.md files
Add additional `CLAUDE.md` files in subdirectories when they contain domain-specific logic, unique conventions, or distinct tooling. This is especially useful in mono-repos, but applies anywhere a directory has context that doesn't belong in the root file.

Examples:
- `packages/api/CLAUDE.md` — API-specific patterns, endpoint conventions, auth handling
- `packages/web/CLAUDE.md` — frontend component patterns, state management, styling approach
- `scripts/CLAUDE.md` — scripting conventions, which scripts are safe to run

Keep nested files focused; they supplement the root file, not replace it. Root file owns cross-cutting concerns (git, PRs, safety, general style). Nested files own domain-specific patterns, local commands, and package-specific gotchas.

## Pull requests
- Conventions for titles, body format, and PR sizing live in the `pr-writer` agent (`.claude/agents/pr-writer.md`). Use that agent when drafting a PR.
- Always invoke the `pr-writer` agent to draft *and* open PRs. Don't call `gh pr create` or the GitHub MCP `create_pull_request` tool directly.
- Open PRs ready for review, not as drafts.

## Commits
- Write concise commit messages focused on *why*, not *what*.
- Create new commits rather than amending, unless explicitly asked.
- Never use `--no-verify` or skip hooks.
- Keep commits atomic (one logical change per commit).

## Git
- Don't force push.
- Don't modify git config or hooks.

## Branches
**Prefixes:**
- `feat/` — new feature
- `fix/` — bug fix
- `refactor/` — code restructuring without behavior change
- `docs/` — documentation only
- `chore/` — maintenance, deps, configs
- `test/` — adding or updating tests
- `style/` — formatting, no logic change
- `perf/` — performance improvements
- `wip/` — work in progress (use sparingly)
- `experiment/` — exploratory branches you might throw away

**Formatting rules:**
- Lowercase only
- Use hyphens for spaces (`audio-synthesis`, not `audio_synthesis` or `audioSynthesis`)
- Keep it short but descriptive (3–5 words max)
- No special characters except `/` and `-`

## Code structure
- Prefer editing existing files over creating new ones.
- Stay DRY, but follow the rule of three: don't abstract on the first duplicate. Wrong abstractions are costlier than repetition.
- Keep new files focused on one responsibility. If a file you're already editing has drifted into multiple concerns, flag it rather than splitting it mid-task.
- Build UI with a design-system mindset: presentational components stay dumb (props in, markup out), and business logic lives in hooks, services, or containers. Apply the same rule-of-three trigger for extracting shared components — consolidate once a pattern repeats, not before.

## Dependencies
- Prefer LTS or current stable releases for languages and runtimes; only move off LTS when a specific feature or fix requires it, and note why in the PR.
- Pin or constrain versions in line with the ecosystem's conventions (lockfiles, version ranges).
- Dependabot is enabled by default (see `.github/dependabot.yml`); keep minor/patch updates grouped to limit PR noise.

## Testing
- Add tests for new functionality; bug fixes should include a regression test.
- Prefer integration tests for user-facing flows, unit tests for pure logic.
- Tests should be deterministic—no flaky tests, no reliance on external services without mocking.

## Naming conventions
- Follow the established conventions for the stack (e.g., camelCase for JS/TS, snake_case for Python/Ruby).
- Be consistent with what already exists in the codebase.
- Use descriptive names; avoid abbreviations unless they're ubiquitous (e.g., `id`, `url`).

## Safety
- Never commit secrets, API keys, or credentials.
- Don't delete or overwrite files without reading them first.
- Ask before making destructive changes (dropping tables, force pushing, etc.).

## Commands
<!-- Fill these in per-project -->
- Install: `<package-manager> install`
- Test: `<test-command>`
- Lint / typecheck: `<lint-command>`
- Dev server: `<dev-command>`

## Gotchas
<!-- Anything non-obvious: unusual build steps, framework quirks, files not to touch, etc. -->
