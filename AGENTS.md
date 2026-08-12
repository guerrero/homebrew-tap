# AGENTS.md

Conventions for this repository. `guerrero/homebrew-tap` is a personal
Homebrew tap with hand-maintained formulae at the **tap root** (`gitia.rb`,
`gtdo.rb`). Do not add a `Formula/` directory: brew's tap `formula_dir`
prefers `Formula/` when present and would shadow the root formulae.

Homebrew 6 requires trusting third-party taps before installing from them
(one-time, documented in README.md): `brew trust guerrero/tap`. The tap is
registered on this machine as `guerrero/tap` (remote:
`https://github.com/guerrero/homebrew-tap`).

## Testing a formula (required before pushing)

`brew audit [path ...]` is **disabled** in modern Homebrew: auditing a raw
`.rb` file cannot resolve tap context (full names, tap metadata, git history),
so the command errors out and tells you to audit by name. Always audit by
formula name against the registered tap:

- `brew audit --strict --online guerrero/tap/<formula>` — audit gate for
  updates to existing formulae. A clean audit prints nothing and exits 0.
- `brew audit --new guerrero/tap/<formula>` — for brand-new formulae;
  `--new` implies `--strict` and `--online`.
- `ruby -c <formula>.rb` — quick syntax check before committing.
- `brew test guerrero/tap/<formula>` — runs the formula's `test do` block.
- `brew install guerrero/tap/<formula>` — end-to-end check; verify the
  installed binary reports the expected version.
- CI: `.github/workflows/tests.yml` runs Homebrew's test-bot (tap syntax on
  push to main, formulae audit on PRs); `.github/workflows/publish.yml` is
  the `pr-pull` bottle flow. CI is a backstop, not a substitute for the local
  audit gate.

### Testing an un-pushed formula from a local checkout

Register the checkout under a name that is not already taken (registering an
existing tap name with a different remote fails with "remote mismatch"), e.g.:

```bash
brew tap guerrero/local /path/to/tap-checkout
brew audit --strict --online guerrero/local/<formula>
brew untap guerrero/local
```

### Refreshing the registered tap after pushing

The registered tap fetches on the next brew auto-update. Confirm it points at
the intended commit with `brew tap-info guerrero/tap` (shows HEAD) before
auditing.

## Updating a formula (gtdo example)

`gtdo.rb` tracks releases of `guerrero/gtdo-cli` (tag `vX.Y.Z`, goreleaser
publishes platform tarballs plus `checksums.txt`):

- Bump the four `url`/`sha256` pairs (darwin/linux × amd64/arm64) to the new
  version's assets.
- Take the sha256 values from the release's `checksums.txt` and verify them
  against the downloaded tarballs (`shasum -a 256 file.tar.gz`).
- Homebrew derives the version from the URL: never add a `version` line
  (goreleaser-generated version lines fail `brew audit`; keep the formula
  audit-clean by hand).
- Keep the formula structure untouched: binary name, `bin.install "gtdo"`,
  and the `test do` block (`system bin/"gtdo", "-V"`) are part of the
  contract.

## Commit conventions

Conventional Commits v1.0.0, same style as the gtdo/gitia repos: imperative
lower-case subject, no trailing period, header within 72 characters. No scope.
Types in use here: `feat`, `docs`, `chore`, `ci`. Formula version bumps are
`chore: bump <formula> formula to vX.Y.Z`; documentation changes are `docs:`.

## Scope

- Only these two formulae exist; anything else is out of scope.
- No changelog file: the tap is not versioned, release notes live in the
  source repos' changelogs.
