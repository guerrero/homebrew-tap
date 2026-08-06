# gitia: Homebrew formula + manual release process

Date: 2026-08-06 · Status: approved

## Context

- `guerrero/homebrew-tap` is a fresh tap with one boilerplate formula
  (`Formula/whjvenyl-fasd.rb` from `brew tap-new`), standard test-bot/pr-pull
  CI, and no README specifics.
- `guerrero/gitia` (private repo) is a Go CLI. It already ships a goreleaser
  config (`.goreleaser.yaml`, version 2) whose `brews:` section targets
  `guerrero/homebrew-tap` — goreleaser is designed to generate and push
  `Formula/gitia.rb` on every release.
- There is **no published release** for gitia: the local tag `v0.1.0` was never
  pushed, `git ls-remote --tags origin` is empty, and no GitHub Release exists.
  The tag points 7 commits behind `HEAD`.
- gitia has **no CI**: `main` ends with "ci: remove GitHub Actions workflows"
  (deliberate).
- gitia has a manual `CHANGELOG.md` (Keep a Changelog) and a `release-dry`
  Makefile target, but no `release` target.

## Decisions (approved with the user)

1. **Formula maintenance**: goreleaser generates and pushes `Formula/gitia.rb`
   to the tap on each release. No hand-maintained sha256.
2. **First release is v0.2.0**: the unpublished tag `v0.1.0` is deleted, its
   CHANGELOG entry is merged into `[0.2.0]`, and the first real release
   includes the 7 pending commits plus the release process itself.
3. **Release process is manual and documented** (no CI reintroduced in gitia):
   a `make release` target, a "Releasing" checklist in `CONTRIBUTING.md`, and a
   short "Release" section in `AGENTS.md`.
4. **The gitia repo is now public** (2026-08-06). Discovered during
   implementation: brew 6.0.15 cannot attach credentials to formula downloads
   (`HOMEBREW_GITHUB_API_TOKEN` is only used for Homebrew's own API calls), and
   this GitHub does not serve `releases/download/<tag>/<asset>` URLs for
   private repos under any authentication. Making the repo public restores the
   goreleaser binary formula as an anonymous, frictionless download. The tap
   repo stays public as it already was.

## Goals

- `brew install gitia` works from `guerrero/tap` with no setup (public repos,
  anonymous downloads).
- Future releases publish assets and update the tap formula automatically.
- The release process is executable by one person from documented commands.

## Non-goals

- CI in gitia (workflows were deliberately removed).
- Changelog automation tools (git-cliff, changie): the manual Keep a Changelog
  file works; goreleaser already derives per-release notes from commits.
- `livecheck` in the formula (fails on private repos without a token; goreleaser
  does not emit one).
- Windows builds, publishing to other channels.

## Part 1 — Tap changes (this repo)

1. **Formula**: after the first release run, goreleaser pushes
   `Formula/gitia.rb` to `main`. Verify it matches the `brews:` config: desc,
   homepage, Unlicense, `depends_on "git"` + `depends_on "ollama" => :optional`,
   `bin.install "gitia"` + `man1.install "man/gitia.1"`, test
   `system "#{bin}/gitia", "--version"`, per-OS/arch URL+sha256 blocks from the
   release assets.
2. **Validate locally** (no token needed — public repo):
   - `brew audit --formula gitia.rb` — audit-clean: gitia's release
     automation strips the redundant `version` line after every release, so
     the audit exits 0
   - `brew install guerrero/tap/gitia`
   - `gitia --version` prints `gitia 0.2.0` (goreleaser's `{{ .Version }}`
     strips the `v`); `man gitia` resolves.
3. **Remove** `Formula/whjvenyl-fasd.rb` (tap-new boilerplate). Removing it also
   makes the root-level `gitia.rb` visible to brew: brew's tap `formula_dir`
   prefers the `Formula/` subdirectory when present.
4. **README**: installation instructions
   (`brew tap guerrero/tap` → `brew install gitia`). No token note — the
   source repo is public.
5. **CI**: `tests.yml` runs `brew test-bot --only-formulae` on PRs. No audit
   flags needed — the strip automation keeps the formula audit-clean. No
   secrets needed.

## Part 2 — gitia release process (manual, documented)

1. **`Makefile`**: add a `release` target —
   - guard: fail with a clear message if `git tag --points-at HEAD` is empty;
   - then `goreleaser release --clean`.
   - `release-dry` stays as the snapshot smoke test.
2. **`CONTRIBUTING.md`**: new "Releasing" section, checklist:
   1. `make test lint man` (man page is committed and goes stale).
   2. Move `[Unreleased]` → `[x.y.z] - <date>` in `CHANGELOG.md`, update the
      compare links at the bottom.
   3. Commit (dogfooding: use gitia itself) and `git push origin main`.
   4. `git tag vX.Y.Z && git push origin vX.Y.Z`.
   5. `GITHUB_TOKEN=$(gh auth token) make release` — goreleaser builds the 4
      archives, creates the GitHub Release (notes from commits), and pushes
      `Formula/gitia.rb` to `guerrero/homebrew-tap`.
   6. Post-release: `brew update && brew upgrade gitia` to verify the formula.
   - Version policy: semver; pre-1.0 Conventional Commits — `feat` → minor,
     `fix` → patch, breaking → minor.
3. **`AGENTS.md`**: short "Release" section — semver, manual Keep a Changelog,
   releases via `make release` after tagging, pointer to the CONTRIBUTING
   checklist. (gitia reads this file when generating commits, so release
   conventions stay in context.)
4. **`CHANGELOG.md`**: merge the `[0.1.0]` entry into `[0.2.0]` (dated
   2026-08-06), delete the `[0.1.0]` section and its compare link, repoint
   `[Unreleased]` link at `v0.2.0...HEAD`.
5. **Delete the unpublished local tag** `v0.1.0`.

## Part 3 — First release execution

1. Commit Parts 2 items in gitia (one commit), push `main`, tag `v0.2.0`,
   push the tag.
2. `GITHUB_TOKEN=$(gh auth token) make release` from `HEAD` of `main`.
3. goreleaser creates the GitHub Release with assets and pushes
   `Formula/gitia.rb` to `guerrero/homebrew-tap@main`.
4. In this worktree: pull/rebase to include goreleaser's formula commit, apply
   Part 1 items (README, formula removal, tests.yml env), commit, push.
5. Merge the tap branch to `main`.

## Risks and error handling

- **goreleaser tap push needs write access**: `gh auth token` has `repo` scope
  on both repos. If the tap push fails, the formula still lands in
  `dist/gitia.rb` — copy it manually.
- **`releases/download` requires a public repo**: this GitHub serves those
  URLs only for public repositories (private repos 404 even with a valid
  token). gitia is public; if it is ever made private again, brew installs
  break — keep it public or rework the formula.
- **Tap CI on PRs**: if the strip automation fails or is skipped, the next
  goreleaser push reintroduces the redundant `version` line and the tap-syntax
  CI goes red — the fix is re-running the strip, not hand-editing the formula.
- **Formula drift**: the committed formula must match goreleaser's template;
  never hand-edit it beyond what goreleaser produces.

## Success criteria

- `brew install guerrero/tap/gitia` succeeds on this machine with no
  environment setup; `gitia --version` first line is `gitia 0.2.0`.
- GitHub Release `v0.2.0` exists with 4 assets + checksums.
- `make release` fails fast when `HEAD` is untagged.
- Tap repo: formula only, no boilerplate, README documents install (no token
  note).
