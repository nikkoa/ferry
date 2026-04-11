# Ferry

Native macOS utility for one-click database and file sync between local and remote web dev environments. Built for developers managing multiple sites across **WordPress**, **Craft CMS**, **Laravel**, **Statamic**, and **SilverStripe**.

**Website**: [getferry.dev](https://getferry.dev)
<br>
**Status**: Public beta — expect rough edges and feedback welcome

---

## Download

Grab the latest beta from the [Releases page](https://github.com/nikkoa/ferry/releases/latest). Ferry ships as a signed, notarized, universal `.dmg`. Drag the app into your `Applications` folder and you're done.

**Requirements**:
- macOS 14 (Sonoma) or later
- Command-line tools on your `$PATH`: `mysql`, `mysqldump`, `ssh`, `rsync`. Most come standard; the MySQL client is one Homebrew command away:

```bash
brew install mysql-client rsync
```

Full setup instructions in [Getting Started](docs/getting-started.md).

---

## What Ferry does

Stop copy-pasting the same `mysqldump` → `rsync` → `wp search-replace` dance into every project. Register a site once and Ferry handles the whole pipeline, one click at a time:

- **Pull database** — dump remote, rewrite hostnames, import locally, run post-pull hooks
- **Push database** — reverse direction, with a production confirmation dialog
- **Pull files / Push files** — rsync-based media sync with per-path include/exclude lists
- **Local backup / Remote backup** — DB snapshots with configurable retention
- **Full Sync** — combined DB + files pull in one pipeline

Every operation runs as an observable pipeline: live step-by-step output, cancellation, and a searchable history of every run.

### Out of the box

- Auto-detects your project's stack from a folder drop
- Reads DB credentials from `.env` / `wp-config.php`
- Stack-specific presets for file sync paths, hooks, and admin panel URLs
- Passwords live in the macOS Keychain — never in Ferry's database, never in operation logs
- Hostname replacement (with WordPress serialized-data caveat — see [advanced docs](docs/advanced.md))
- Table exclusions (full or data-only) for large cache/log tables
- Custom pre/post hooks per operation
- Override the MySQL binary per site (MAMP, Valet, Herd, custom Homebrew)

---

## Documentation

- **[Getting Started](docs/getting-started.md)** — install, add your first site, run your first sync
- **[Concepts](docs/concepts.md)** — sites, environments, operations, hooks, supported stacks
- **[Operations](docs/operations.md)** — every operation in detail with step-by-step walkthroughs
- **[Advanced](docs/advanced.md)** — hostname replacement, table exclusions, custom hooks, MySQL binary override, `.env` import
- **[FAQ](docs/faq.md)** — common questions, troubleshooting, known limitations

---

## Filing issues

Found a bug or want to request a feature? **[Open an issue →](https://github.com/nikkoa/ferry/issues/new/choose)**

Before filing:
- Check existing issues to avoid duplicates
- Pick the right template (Bug report or Feature request)
- For bugs, include: Ferry version, macOS version, the failing operation's step output from the History view (expand the failed run), and whether the equivalent command runs manually from the terminal. **Redact passwords.**

Issues with incomplete info will get a `needs-info` label and a friendly reply asking for the missing details.

---

## Release notes

See [CHANGELOG.md](CHANGELOG.md) for the full version history, or the [Releases page](https://github.com/nikkoa/ferry/releases) for downloadable builds.

---

## About this repository

This is Ferry's **public face** — issues, release notes, documentation, and DMG downloads during the beta period. The app's source code lives in a private repository. Once Ferry reaches a stable release, DMG hosting may move off GitHub to [getferry.dev](https://getferry.dev) directly.
