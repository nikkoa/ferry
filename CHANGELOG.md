# Changelog

All notable changes to Ferry are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] — 2026-06-12

Release candidate for 1.0. A full review pass (including independent model reviews) over the operations pipeline, plus the remaining spec features.

### Added

- **Dry run mode (`⌘D`)** — toggle in the dashboard header; any operation triggered with dry run on shows the exact commands it would run (passwords redacted) in a preview sheet instead of executing. Works for all operations including `⌘R` re-run.
- **Preferences window (`⌘,`)** — default SSH key path, backup directory, and retention count. Newly added sites inherit the defaults; existing sites keep their own config.
- **Background notifications** — a system notification fires when an operation finishes while Ferry isn't the active app. Failures get a sound; cancellations stay quiet.
- **Sidebar status dots** — each site shows its last operation result (green/red/orange) with relative time on hover.
- **`⌘1` / `⌘2`** — switch between Dashboard and History for the selected site.
- **Live output in the dashboard** — expanded activity rows now stream the running step's last output line, show per-table progress, and offer per-step detail popovers plus a Full Log sheet (previously only step names were visible; errors required the History view).

### Fixed

- **File push pre-hooks** — pre-push hooks now run for file push (previously silently skipped). Post-push hooks for file sync now execute on the remote in the remote document root, matching DB push semantics.
- **rsync with SSH password auth** — file sync now works with password-based SSH via `sshpass`, same as DB operations. The password travels through the process environment, never the command string. Key auth uses `BatchMode` so a locked key fails fast instead of hanging.
- **Production push safety** — `⌘R` re-run of a production push now requires the same confirmation as triggering it from the card, and the confirmation honors the dry-run toggle at confirm time.
- **Cancelled operations** — cancelling a run now records it as cancelled (orange) instead of failed (red), and no longer posts a "failed" notification.
- **Log streaming integrity** — pipeline output is read as an ordered line stream: rsync's carriage-return progress rewrites display correctly, per-file byte counters are filtered from logs, and the final lines of a step's output (e.g. the error that explains a failure) can no longer be lost or reordered at process exit.
- **Finished runs** — no longer linger as a fake "In progress…" row in the activity list after completing.
- **Preferences edge case** — clearing a Settings field no longer causes new sites to inherit an empty SSH key path or backup directory.

### Changed

- **Version badge** — beta builds show "Beta vX.Y.Z (build) / Expires …"; builds made with `release.sh --no-expiry` (reserved for 1.0+) show a bare version with no beta labelling.
- **release.sh** — refuses to build if the beta-expiry placeholder has been clobbered, preventing an accidentally time-bombed release.

## [0.6.2] — 2026-04-17

### Changed

- **Onboarding screen** — replaced the legacy empty-project screen with the branded home-screen layout: waves background, centered card, FerryLogo, beta version footer, and a pill-shaped "Add Your First Project" button.

## [0.6.1] — 2026-04-12

### Fixed

- **File sync nested directory bug** — rsync remote source paths were missing a trailing slash, causing files to sync into a nested subdirectory (e.g. `product/product/`) instead of syncing the contents directly. Local paths already had the trailing slash; remote paths now match.

### Changed

- **DMG tooling** — switched from create-dmg to dmgbuild with a branded retina background image.
- **Bundle identifier** — renamed to `dev.getferry` and centralized the constant.

## [0.6.0-beta.1] — 2026-04-11

First public beta. Ferry is a native macOS utility that syncs databases and files between your local development environment and a remote server, with stack-specific presets for WordPress, Craft CMS, Laravel, Statamic, and SilverStripe.

### Added

- **Core operations** — Pull database, Push database, Pull files, Push files, Local backup, Remote backup, Full Sync. Every operation runs as an observable pipeline with live per-step output streaming, cancellation (`⌘.`), and a searchable run history.
- **Project auto-detection** — drop a folder and Ferry identifies the stack, reads DB credentials from `.env` or `wp-config.php`, and pre-fills the site configuration.
- **Stack presets** — WordPress, Craft CMS, Laravel, Statamic, SilverStripe, and Custom. Each ships with sensible defaults for file sync paths, post-pull hooks, and the admin panel URL.
- **Hostname replacement** — rewrites remote URLs to local URLs (and vice versa) inside the SQL dump via `sed`. Handles both plain URLs and the backslash-escaped form that mysqldump produces for URLs stored inside JSON columns. A live preview in the Advanced tab shows the exact substitution before you run the operation.
- **Table exclusions** — skip tables entirely (for session/cache tables) or dump schema-only (for large log tables). Interactive table picker with remote schema introspection.
- **Custom hooks** — pre-pull, post-pull, pre-push, and post-push shell commands per site. Local hooks run from the site's local document root; post-push hooks run on the remote via SSH.
- **MySQL binary override** — point at a specific `mysql` binary per site for MAMP, Valet, Herd, or multi-version Homebrew setups.
- **History view** — filter by All / Syncs / Backups, expand rows to see per-step output and duration, jump directly to backup files in Finder.
- **Backup retention** — configurable count per site, filename-prefix-matched so retention only touches Ferry-created backups for the specific site and target (never other files).
- **Beta expiry** — builds stamp a 90-day expiry at build time to encourage upgrading to the latest beta.
- **End-user documentation** — getting started, concepts, operations, advanced features, and an FAQ covering known limitations.

### Security

- **Passwords stored in the macOS Keychain** — database and SSH passwords live in Keychain Services (`SecItemAdd`/`Update`/`CopyMatching`/`Delete`) under the bundle identifier namespace. Never written to Ferry's own database, never in config files, never in environment variables.
- **Credentials redacted from operation logs** — database passwords are filtered out of step commands before they're persisted. SSH passwords are passed via `Process.environment` rather than inline in the shell command string, so they never appear in the log or in `ps` output.
- **SSH host key verification** — Ferry uses `StrictHostKeyChecking=accept-new`, which trusts a host key on first connect and verifies it on subsequent connects. For stricter verification, SSH to the host manually first so the key is already in `~/.ssh/known_hosts`.
- **Signed and notarized** — Ferry is built with a Developer ID Application certificate, hardened runtime, and stapled Apple notarization. Gatekeeper verifies it without a network connection.

### Known limitations

- **File sync requires SSH key auth** — rsync invokes the system `ssh` binary directly, bypassing the `sshpass` layer Ferry uses for database operations. Password-only SSH won't work for file sync; set up a key.
- **WordPress serialized data** — byte-level `sed` can't update PHP-serialized string length prefixes. For WordPress sites with serialized data, add a `wp search-replace` post-pull hook in the Advanced tab.
- **Pre-push hooks for file sync** — pre-push hooks run for Push database but not yet for Push files alone.
- **Beta expiry** — builds stop launching after 90 days. Download the latest beta from the Releases page to continue.

[Unreleased]: https://github.com/nikkoa/ferry/compare/v0.6.0-beta.1...HEAD
[0.6.0-beta.1]: https://github.com/nikkoa/ferry/releases/tag/v0.6.0-beta.1
