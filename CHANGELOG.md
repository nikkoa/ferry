# Changelog

All notable changes to Ferry are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
