# gitia Formula + Manual Release Process — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `brew install gitia` work from `guerrero/tap` and give gitia a documented manual release process (`make release`) that publishes binaries and auto-updates the tap formula.

**Architecture:** Two repos cooperate. goreleaser (already configured in gitia's `.goreleaser.yaml` with a `brews:` section) generates `Formula/gitia.rb` and pushes it to `guerrero/homebrew-tap` on every release; we cut the first real release (`v0.2.0`) to create the formula. In parallel, gitia gains a guarded `make release` target plus release documentation (CONTRIBUTING.md checklist, AGENTS.md conventions, CHANGELOG merge). The tap is then cleaned up (README, CI token, remove boilerplate formula) and the branch merged.

**Tech Stack:** Homebrew formulae/ruby, goreleaser v2, Go (gitia), GitHub Actions (tap CI), gh CLI.

**Start by reading** `docs/superpowers/specs/2026-08-06-gitia-formula-release-design.md` in the tap worktree — this plan implements it.

## Global Constraints

- Two repos, both private, both owned by `guerrero`:
  - Tap (this repo, worktree): `/Users/alex/.paseo/worktrees/0vv4q0vo/adoring-dugong`, branch `gitia-homebrew-formula`.
  - gitia (regular clone): `/Users/alex/Proyectos/Personales/gitia`, branch `main`.
- gitia commit convention (from gitia `AGENTS.md`): Conventional Commits, imperative lower-case subject, no trailing period, header ≤ 72 chars, no scope for repo-wide changes.
- Changelog: Keep a Changelog. The unpublished `[0.1.0]` entry merges into `[0.2.0]` dated `2026-08-06`; the local tag `v0.1.0` is deleted (never pushed).
- Version policy (pre-1.0): `feat` → minor, `fix` → patch, breaking → minor.
- **No CI in gitia** — releases are manual, documented in CONTRIBUTING.md.
- **Never hand-edit `gitia.rb`** — goreleaser writes it to the **tap root** (its default directory for `homebrew-tap` repos; only `homebrew-core` uses `Formula/`); we inspect and verify. The boilerplate `Formula/whjvenyl-fasd.rb` is unrelated and removed in Task 4.
- Private-repo downloads need a GitHub token: use `HOMEBREW_GITHUB_API_TOKEN=$(gh auth token)` (scopes include `repo`; `gh` is authenticated as `guerrero`).
- Tooling facts: `goreleaser` and `golangci-lint` are NOT installed (install via brew in Task 1); `brew` 6.0.15 and `gh` are available.

---

### Task 1: gitia — add the release process (make target, docs, changelog)

**Files:**
- Modify: `/Users/alex/Proyectos/Personales/gitia/Makefile`
- Modify: `/Users/alex/Proyectos/Personales/gitia/CONTRIBUTING.md`
- Modify: `/Users/alex/Proyectos/Personales/gitia/AGENTS.md`
- Modify: `/Users/alex/Proyectos/Personales/gitia/CHANGELOG.md`

**Interfaces:**
- Consumes: nothing (starts the gitia side).
- Produces: gitia `main` (local) with the release process committed; `HEAD` untagged; no `v0.1.0` tag. Task 2 relies on `make release` existing and on the clean changelog.

- [ ] **Step 1: Install tooling**

```bash
command -v goreleaser || brew install goreleaser
command -v golangci-lint || brew install golangci-lint
```

Expected: both binaries on PATH (`goreleaser --version` prints v2.x).

- [ ] **Step 2: Add the `release` target to the Makefile**

In `/Users/alex/Proyectos/Personales/gitia/Makefile`, change the `.PHONY` line to include `release` and append the target after `release-dry`:

```makefile
.PHONY: build test lint man install release release-dry clean
```

```makefile
release:
	@tag=$$(git tag --points-at HEAD); \
	if [ -z "$$tag" ]; then \
		echo "error: HEAD has no tag; tag a release first (see CONTRIBUTING.md)" >&2; \
		exit 1; \
	fi; \
	echo "releasing $$tag"; \
	goreleaser release --clean
```

- [ ] **Step 3: Verify the guard fails on untagged HEAD**

Run: `cd /Users/alex/Proyectos/Personales/gitia && make release`
Expected: prints `error: HEAD has no tag; tag a release first (see CONTRIBUTING.md)` and exits non-zero, **before** invoking goreleaser.

- [ ] **Step 4: Verify `make release-dry` still works**

Run: `cd /Users/alex/Proyectos/Personales/gitia && make release-dry`
Expected: goreleaser snapshot build succeeds (exit 0); `dist/` contains `gitia_darwin_amd64` and `gitia_linux_arm64` binaries.

- [ ] **Step 5: Add the "Releasing" section to CONTRIBUTING.md**

Append at the end of `/Users/alex/Proyectos/Personales/gitia/CONTRIBUTING.md` (after the "Commit messages" section):

```markdown
## Releasing

Releases are manual and documented here; there is no CI. A release publishes
binary assets to a GitHub Release and updates the Homebrew formula in
`guerrero/homebrew-tap` automatically via goreleaser.

Versioning follows Semantic Versioning. Until 1.0: `feat` bumps the minor
version, `fix` bumps the patch version, breaking changes bump the minor
version.

Checklist:

1. `make test lint man` — the suite is green and `man/gitia.1` is current.
2. Move the `[Unreleased]` section in `CHANGELOG.md` to `[x.y.z] - YYYY-MM-DD`
   and update the compare links at the bottom.
3. Commit (use gitia itself) and push: `git push origin main`.
4. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`.
5. `GITHUB_TOKEN=$(gh auth token) make release` — goreleaser builds the
   darwin/linux archives, creates the GitHub Release with notes from the
   commits since the last tag, and pushes `Formula/gitia.rb` to
   `guerrero/homebrew-tap`. The token needs `repo` scope (write access to
   both repositories).
6. Verify: `brew update && brew upgrade gitia` installs the new version.
```

- [ ] **Step 6: Add the "Release" section to AGENTS.md**

Append at the end of `/Users/alex/Proyectos/Personales/gitia/AGENTS.md`:

```markdown
## Release

Releases are manual; the checklist lives in CONTRIBUTING.md. Version numbers
follow Semantic Versioning (pre-1.0: `feat` → minor, `fix` → patch). The
changelog is curated by hand in Keep a Changelog format: every release moves
the `[Unreleased]` section to a dated version heading. Tag `vX.Y.Z` on `main`,
then `GITHUB_TOKEN=$(gh auth token) make release` publishes assets and updates
the Homebrew tap formula.
```

- [ ] **Step 7: Merge the changelog entries**

In `/Users/alex/Proyectos/Personales/gitia/CHANGELOG.md`, replace everything from `## [Unreleased]` down (the `[0.1.0]` section and both bottom links) with:

```markdown
## [Unreleased]

## [0.2.0] - 2026-08-06

### Added

- `gitia commit` generates a Conventional Commits message from the staged diff
  using a model running locally under Ollama. Nothing leaves the machine.
- Structured output: the JSON schema sent to Ollama is derived from the resolved
  rules, so the constrained decode cannot produce an illegal commit type.
- Rule precedence across Conventional Commits defaults, `~/.config/gitia/config.toml`,
  `AGENTS.md`/`CLAUDE.md`/`GEMINI.md`, and CLI flags.
- commitlint as a hard validity gate, resolved through
  `commitlint --print-config json` and cached on the config and lockfile mtimes.
- Diff budgeting: excluded paths drop to stat-only first, then the largest
  remaining files, while every changed path stays listed.
- `gitia doctor` with ten checks and a `--json` mode.
- A confirmation menu with commit, edit, regenerate, and abort.
- `man gitia` and bash, zsh, and fish completions.
- `make release`: a guarded release target that publishes assets and updates
  the Homebrew tap formula. The checklist lives in CONTRIBUTING.md.

### Changed

- Polished `gitia doctor` output, the editor flow, prompt handling, and commit
  feedback.

### Fixed

- Usage errors exit with status 2.
- Prompts abort when the command context is canceled.
- Reroll keeps its context when a validation retry is needed.

### Removed

- GitHub Actions workflows; releases are manual now.

[Unreleased]: https://github.com/guerrero/gitia/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/guerrero/gitia/releases/tag/v0.2.0
```

Verify: no remaining `0.1.0` references in the file (`grep -n 0.1.0 CHANGELOG.md` prints nothing).

- [ ] **Step 8: Delete the unpublished local tag**

Run: `cd /Users/alex/Proyectos/Personales/gitia && git tag -d v0.1.0 && git tag -l`
Expected: `Deleted tag 'v0.1.0'`; `git tag -l` is empty.

- [ ] **Step 9: Run the suite and regenerate the man page**

```bash
cd /Users/alex/Proyectos/Personales/gitia
make test
make lint
make man
git status --short
```

Expected: all tests pass, lint clean; `make man` may touch `man/gitia.1` — if so, include it in the commit.

- [ ] **Step 10: Commit**

```bash
cd /Users/alex/Proyectos/Personales/gitia
git add Makefile CONTRIBUTING.md AGENTS.md CHANGELOG.md man/gitia.1
git commit -m "build: add release process and docs"
```

Verify: `git log --oneline -1` shows the new commit on `main`; `git status --short` clean.

---

### Task 2: gitia — cut the first release v0.2.0

**Files:** none (network/publish task).

**Interfaces:**
- Consumes: Task 1's commit on local `main`; `make release` target.
- Produces: `origin/main` updated; GitHub Release `v0.2.0` with 5 assets; a goreleaser commit adding `Formula/gitia.rb` on `guerrero/homebrew-tap@main` (consumed by Task 3).

- [ ] **Step 1: Push main**

Run: `cd /Users/alex/Proyectos/Personales/gitia && git push origin main`
Expected: Task 1's commit lands on `origin/main`.

- [ ] **Step 2: Tag and push**

```bash
cd /Users/alex/Proyectos/Personales/gitia
git tag v0.2.0
git push origin v0.2.0
```

Expected: `git ls-remote --tags origin` shows `v0.2.0` (and only that tag).

- [ ] **Step 3: Run the release**

Run: `cd /Users/alex/Proyectos/Personales/gitia && GITHUB_TOKEN=$(gh auth token) make release`
Expected: exits 0; builds the 4 archives (`gitia_0.2.0_{darwin,linux}_{amd64,arm64}.tar.gz`), creates the GitHub Release with auto-generated notes, and pushes the formula to the tap.

- [ ] **Step 4: Verify the release and its assets**

Run: `gh release view v0.2.0 --repo guerrero/gitia --json assets --jq '.assets[].name'`
Expected: exactly `checksums.txt` plus `gitia_0.2.0_darwin_amd64.tar.gz`, `gitia_0.2.0_darwin_arm64.tar.gz`, `gitia_0.2.0_linux_amd64.tar.gz`, `gitia_0.2.0_linux_arm64.tar.gz`.

- [ ] **Step 5: Verify the formula landed in the tap**

```bash
cd /Users/alex/.paseo/worktrees/0vv4q0vo/adoring-dugong
git fetch origin
git log --oneline origin/main -3
```

Expected: `origin/main` has a goreleaser commit (e.g. "Brew formula update for gitia version v0.2.0") that adds `gitia.rb` at the **tap root** (confirmed: commit `1fb0378`). If it is missing, goreleaser left the formula at `/Users/alex/Proyectos/Personales/gitia/dist/gitia.rb` — copy it to the tap root manually, commit as `chore: add gitia formula generated by goreleaser`, and report the deviation.

---

### Task 3: tap — rebase and verify the generated formula

**Files:** (verify only — do NOT edit `Formula/gitia.rb`)

**Interfaces:**
- Consumes: `Formula/gitia.rb` on `origin/main` (from Task 2), branch `gitia-homebrew-formula` with the spec commit.
- Produces: rebased branch containing the formula; verified formula install on this machine.

- [ ] **Step 1: Rebase the worktree branch onto origin/main**

```bash
cd /Users/alex/.paseo/worktrees/0vv4q0vo/adoring-dugong
git rebase origin/main
```

Expected: clean rebase; `git status --short` clean; `ls` shows `gitia.rb` at the tap root (the `Formula/` dir still holds only the boilerplate).

- [ ] **Step 2: Inspect the formula against the expected shape**

Run: `cat Formula/gitia.rb`
Expected fields (from `.goreleaser.yaml` `brews:`): `desc "Generate Conventional Commits from the staged diff with a local model"`, `homepage "https://github.com/guerrero/gitia"`, `license "Unlicense"`, `version "0.2.0"`, `depends_on "git"` and `depends_on "ollama" => :optional`, install defined as `bin.install "gitia"` + `man1.install "man/gitia.1"` (goreleaser v2 emits `define_method(:install)` blocks inside the `on_macos`/`on_linux` + CPU sections), test `system "#{bin}/gitia", "--version"`, and per-arch `url`/`sha256` pointing at `releases/download/v0.2.0/gitia_0.2.0_<os>_<arch>.tar.gz`. If the shape differs, keep goreleaser's output (it is authoritative) and note the difference in the final summary.

- [ ] **Step 3: Audit the formula**

Run: `cd /Users/alex/.paseo/worktrees/0vv4q0vo/adoring-dugong && brew audit --formula gitia.rb`
Expected: no errors (warnings acceptable).

- [ ] **Step 4: Install and test the formula from the local file**

```bash
cd /Users/alex/.paseo/worktrees/0vv4q0vo/adoring-dugong
HOMEBREW_GITHUB_API_TOKEN=$(gh auth token) brew install --formula gitia.rb
gitia --version | head -1
ls "$(brew --prefix gitia)/share/man/man1/gitia.1"
```

Expected: install succeeds; `gitia --version` first line is `gitia v0.2.0`; the man page file exists. If the download 404s, the token env is the fix — re-run with it set.

- [ ] **Step 5: Run the formula's test block and clean up**

```bash
HOMEBREW_GITHUB_API_TOKEN=$(gh auth token) brew test --formula gitia.rb
brew uninstall gitia
```

Expected: `brew test` passes (runs `gitia --version`); uninstall leaves no `gitia` binary on PATH (`command -v gitia` empty).

---

### Task 4: tap — README, CI token, remove boilerplate

**Files:**
- Delete: `Formula/whjvenyl-fasd.rb` (tap-new boilerplate)
- Rewrite: `README.md`
- Modify: `.github/workflows/tests.yml`

**Interfaces:**
- Consumes: Task 3's rebased branch.
- Produces: one commit on `gitia-homebrew-formula` ready to push.

- [ ] **Step 1: Remove the boilerplate formula**

Run: `cd /Users/alex/.paseo/worktrees/0vv4q0vo/adoring-dugong && git rm Formula/whjvenyl-fasd.rb`

- [ ] **Step 2: Rewrite the README**

Replace the whole `README.md` with:

```markdown
# Personal Homebrew Tap

Formulae for tools by [@guerrero](https://github.com/guerrero).

## gitia

Generate Conventional Commits from the staged diff with a local model.

```bash
brew tap guerrero/tap
brew install gitia
```

The source repository is private, so Homebrew needs a GitHub token with
`repo` scope to download the binaries:

```bash
export HOMEBREW_GITHUB_API_TOKEN=ghp_...
brew install gitia
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
```

(Note the nested fenced block in the README: the outer fences are ```` ```markdown ```` … ```` ``` ```` — write the file with a text editor, not by nesting literals.)

- [ ] **Step 3: Add the token to test-bot CI**

In `.github/workflows/tests.yml`, add an `env` block to the `test-bot` job (right after `runs-on`):

```yaml
    env:
      HOMEBREW_GITHUB_API_TOKEN: ${{ secrets.HOMEBREW_GITHUB_API_TOKEN }}
```

- [ ] **Step 4: Commit**

```bash
cd /Users/alex/.paseo/worktrees/0vv4q0vo/adoring-dugong
git add -A
git commit -m "chore: document gitia install, pass token to CI, drop boilerplate"
```

Verify: `git log --oneline -3` shows (top to bottom) this commit, the spec commit, the goreleaser formula commit.

---

### Task 5: tap — push, merge, end-to-end install

**Files:** none (network/merge task).

**Interfaces:**
- Consumes: Task 4's branch.
- Produces: merged `origin/main`; `brew install gitia` working end-to-end.

- [ ] **Step 1: Push the branch**

Run: `cd /Users/alex/.paseo/worktrees/0vv4q0vo/adoring-dugong && git push -u origin gitia-homebrew-formula`
Expected: push succeeds.

- [ ] **Step 2: Open a PR and tell the user about the CI secret**

```bash
gh pr create --repo guerrero/homebrew-tap --title "Add gitia formula docs, CI token, and cleanup" --body "Generated by goreleaser; adds README install docs, passes HOMEBREW_GITHUB_API_TOKEN to test-bot, removes tap-new boilerplate."
```

Then tell the user (do not merge yet): the PR's `brew test-bot --only-formulae` job installs gitia from the private repo, so the repo needs an Actions secret `HOMEBREW_GITHUB_API_TOKEN` (a PAT with `repo` scope) at `https://github.com/guerrero/homebrew-tap/settings/secrets/actions`. Ask them to add it (or to confirm they prefer pushing to `main` directly, which only runs tap-syntax checks).

- [ ] **Step 3: Merge after the user confirms**

Per the user's choice: merge the PR (`gh pr merge --repo guerrero/homebrew-tap --merge --delete-branch`) **or** push directly to main:

```bash
git push origin gitia-homebrew-formula:main
```

Expected: `origin/main` contains the formula, README, and workflow changes.

- [ ] **Step 4: End-to-end install from the tap**

```bash
HOMEBREW_GITHUB_API_TOKEN=$(gh auth token) brew tap guerrero/tap
HOMEBREW_GITHUB_API_TOKEN=$(gh auth token) brew install gitia
gitia --version | head -1
```

Expected: install succeeds from the real tap; `gitia v0.2.0` printed. Leave gitia installed (it is the user's daily tool).

- [ ] **Step 5: Final verification**

```bash
brew list --formula | grep gitia
git tag -C /Users/alex/Proyectos/Personales/gitia -l
gh release view v0.2.0 --repo guerrero/gitia --json tagName,assets --jq '.tagName, (.assets | length)'
```

Expected: gitia listed in brew; no local tags left in gitia; release `v0.2.0` with 5 assets. Then summarize: formula shape verification notes, whether the goreleaser tap push worked directly, and the user's remaining action (CI secret).
