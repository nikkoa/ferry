# Frequently Asked Questions

Short answers to common questions about using Ferry. If you're hitting a specific error, check the Troubleshooting group near the bottom.

## About Ferry

### What is Ferry?

Ferry is a native macOS app that syncs databases and files between your local development environment and a remote server. You register a site once and it stores everything — DB credentials, SSH config, file paths, hooks, hostname replacement — in one place. After that, every Pull, Push, or Backup is a one-click operation. It's built for web developers managing multiple sites across stacks like WordPress, Craft CMS, Laravel, Statamic, and SilverStripe.

### Who is Ferry for?

Developers and small teams who regularly move database dumps and uploaded files between local and remote environments, and who have grown tired of writing bash scripts for every new project. If you've ever copy-pasted a mysqldump command out of your notes, Ferry is for you.

### Does Ferry send any data to Anthropic or anyone else?

No. Ferry makes no network calls except SSH to the hosts you configure. No analytics, no telemetry, no phone-home. Everything runs locally on your mac.

### Which macOS versions does Ferry support?

macOS 14 (Sonoma) and later. Ferry uses SwiftData and the modern Observation framework, which need the Sonoma SDK.

### Is there a Windows or Linux version?

No. Ferry is a native macOS-only app — it's built on SwiftUI, AppKit, and macOS-specific APIs like Keychain Services. A cross-platform port would be a ground-up rewrite, which isn't on the roadmap.

## Setup and prerequisites

### Which command-line tools does Ferry need?

Ferry shells out to system binaries for all its real work. You need `mysql`, `mysqldump`, `ssh`, `rsync`, `gzip`, `gunzip`, and `sed` on your `$PATH`. All seven come standard on macOS or are one `brew install` away (`mysql-client`, `rsync` via Homebrew). If you use SSH password auth, also install `sshpass` (`brew install hudochenkov/sshpass/sshpass`).

### Does Ferry work with MAMP, Valet, Herd, DDEV, or Local?

Yes — Ferry doesn't care where your local DB comes from as long as there's a `mysql` binary it can use. For MAMP and similar bundled MySQL installs, override the MySQL binary path in the Advanced tab to point at the bundled binary (`/Applications/MAMP/Library/bin/mysql` for MAMP, for example). For Valet and Herd, the system Homebrew MySQL works out of the box.

### Do I need SSH keys, or can I use a password?

Keys work out of the box for everything. Passwords work for database operations (via `sshpass`) but **not** for file sync — rsync invokes `ssh` directly and bypasses the `sshpass` layer. If you want to use file sync, set up a key.

### My project isn't WordPress/Craft/Laravel/Statamic/SilverStripe — can I still use Ferry?

Yes. Pick the **Custom** stack type when creating the site. Custom has no auto-detection, no default hooks, and no default file sync paths — you configure everything manually. Ferry still handles the execution, Keychain storage, logging, and so on.

### How do I connect through a bastion or jump host?

Ferry invokes the system `ssh` binary with your configured host, so anything your `~/.ssh/config` understands just works. Add a `ProxyJump` or `ProxyCommand` entry for your target host in `~/.ssh/config`, then configure Ferry with the target host as if it were directly accessible.

### Can Ferry read credentials from my `.env` file?

Yes. The **Local** and **Remote** config tabs both have a **Paste .env** button — paste your `.env` contents (or the relevant `define()` lines from `wp-config.php`) and Ferry parses out the database fields. It handles quoted values, comments, and the `host:port` form for WordPress.

## Credentials and security

### Where does Ferry store my passwords?

Database and SSH passwords are stored in the **macOS Keychain** via the system Security framework. Each site has separate Keychain entries for its local DB, remote DB, and SSH password. Nothing is written to Ferry's own database file, no config file on disk, and no environment variable.

### Can Ferry leak my password into the operation log?

No. Ferry redacts every known password from the command string before persisting it to the operation log. Database passwords are matched against a known list for each operation and replaced with `***`. SSH passwords are never placed in the command string at all — they're passed via the process environment so `sshpass` can read them without them appearing in `ps` output or log captures.

### What does "StrictHostKeyChecking=accept-new" mean?

When Ferry connects to a new SSH host for the first time, it automatically trusts the host key and adds it to your `~/.ssh/known_hosts`. Subsequent connections verify against that stored key. It's one step stricter than blind trust (a key change later *will* be flagged) but one step less strict than manual fingerprint verification before first connect. For high-security use cases, SSH into the host manually from the terminal first so the key is already in `known_hosts` when Ferry gets there.

### What if I'm on an untrusted network?

Don't Push to production from a network you don't trust. For Pulls, SSH protects the channel itself — your DB dump travels encrypted. The host key caveat above is the only meaningful risk: if someone is running a man-in-the-middle on first connect and you haven't seen that host before, you could accept a spoofed key. Do the first connect from a trusted network, then subsequent connects verify automatically.

### Does Ferry store anything in iCloud or sync across devices?

No. Sites, operation history, and backups all live in `~/Library/Application Support/dev.getferry` (for the database) or wherever you configure the backup directory. None of it touches iCloud. If you want cross-device sync, you'd have to manage it yourself.

## Operations

### What's the difference between Pull and Push?

Pull moves data from the remote to your local machine. Push moves it from your local machine to the remote. Ferry's direction language is always relative to local. We use arrow labels (`Local ← Production` and `Local → Production`) on every operation card so the direction is never ambiguous.

### How do I cancel a running operation?

Press `⌘.` (Command-period). Ferry terminates the current step and marks the rest as skipped. The already-completed steps stay in the operation log so you can see what ran.

### What happens if an operation fails halfway — is my local database safe?

Ferry does not have automatic rollback. If a Pull database fails during the **Import to local database** step, your local DB is in whatever partial state the import reached. Usually that's recoverable by fixing the cause and re-running the Pull, but in extreme cases you may want to take a local backup before a risky operation and restore from it if things go sideways. For Pushes to production, always take a Remote backup first.

### How do I prevent accidentally pushing to production?

Mark the site's environment as `Production` in the **General** tab. Any Push to a production-environment site triggers a confirmation sheet that you have to explicitly acknowledge before the pipeline starts.

### Why does file sync fail when I use an SSH password?

Rsync invokes the system `ssh` binary directly and doesn't go through the `sshpass` layer Ferry uses for database operations. The result is that file sync silently hangs or fails when the only auth method is an SSH password. The fix is to set up an SSH key for that host — it's a one-time setup and then everything works.

### How do I exclude a single huge table from a Pull database?

Open the site's **Advanced** tab and click **Configure** next to **Table Exclusions**. If Ferry can reach your remote database, it fetches the table list so you can check the one you want to exclude. Pick the mode: **Full** (the table is left out entirely) or **Data only** (schema dumped, rows skipped). Data-only is usually what you want for cache and log tables.

### How do I pull only the database, not the files?

Use the **Pull database** operation card, not **Full Sync**. Full Sync combines a database pull and a file pull; Pull database alone is just the database. Ditto for Pull files — it only touches files.

### How do I restore from a backup Ferry created?

Ferry's backups are straight `mysqldump` output, optionally gzipped or zipped. Ferry does not yet have a built-in "restore from backup" UI. To restore manually, find the file in your backup directory, decompress it, and pipe it into `mysql`:

```bash
gunzip -c mysite-prod-db-2026-04-11.sql.gz | mysql -u root -p mydatabase
```

Alternatively, you can restore a remote backup by copying it to the server and running the same command against the remote DB.

## Troubleshooting

### Test Connection says "Host not found" — what's wrong?

The hostname doesn't resolve. Either it's a typo, DNS isn't working for you, or the host is on a network you can't reach (VPN required, etc.). Try `ping <hostname>` from the terminal to confirm — if that fails too, it's a network-level issue, not a Ferry one.

### Test Connection says "Authentication failed" — what's wrong?

For SSH tests, check the username, key path, and key passphrase (if any) in the **Remote** tab. For database tests, verify the DB username, password, and that the user has access to the database from the host Ferry is connecting from (common gotcha with remote MySQL: a user may have `@localhost` access only). Running the same `mysql` command manually from the terminal usually surfaces a clearer error.

### My hostname replacement doesn't work for WordPress — why?

WordPress stores many URLs inside PHP-serialised data, and byte-level `sed` can't update the string lengths serialised strings embed. Ferry's hostname replacement uses `sed`, so it misses serialised URLs. The fix is to add a post-pull hook that runs `wp search-replace` — which understands PHP serialisation — and either leave Ferry's hostname replacement on or off. See the hostname replacement section of the Advanced guide for the exact command.

### Post-pull hooks run but `wp` / `php` / `sake` isn't found — why?

Hooks run through `zsh -l` (a login shell), which sources your `~/.zprofile` and `~/.zshrc`. If those files set up your `$PATH` correctly, everything works. If not — for example, if you rely on a tool like `direnv` or a project-specific PATH modification — the binary won't be found. Either use the full path in the hook (`/opt/homebrew/bin/wp search-replace ...`) or make sure the binary is on your shell's base `$PATH`.

### My hooks seem to run from the wrong directory — why?

Local hooks run from the site's **Local document root**, set in the **Local** tab. If that field is empty, Ferry skips local hooks entirely and shows a warning banner in the Advanced tab. If it's set but wrong — for example, pointing at your parent projects folder instead of the specific project root — then relative-path hooks will fail. Double-check the **Local document root** field.

### Ferry won't open — it says the database couldn't be loaded.

Ferry's own database (where it stores your sites, not any site data) has been corrupted or its schema has moved. On launch, Ferry shows a recovery view with the error and two buttons: **Quit** and **Wipe Store and Quit**. Wiping resets Ferry's internal database — you'll lose your configured sites and operation history, but **backups already on disk are not affected**. You'll need to re-add your sites after restart.

### How do I wipe all of Ferry's local data and start fresh?

Quit Ferry and delete `~/Library/Application Support/dev.getferry/`. This removes the site list and operation history. To also remove stored credentials, open Keychain Access and delete entries for the service `dev.getferry`. Backup files in your configured backup directory are separate and unaffected.

## Beta specifics

### What happens when the beta expires?

Beta builds are stamped with a 90-day expiry at build time. After the expiry date, the app shows a blocking "Beta Expired" screen on launch and won't run. Download and install a fresh beta build to continue.

### How do I upgrade to a newer beta build?

Quit Ferry, drag the new `.app` from the DMG into `/Applications`, replacing the old one. Your Keychain entries, operation history, and site configs persist across upgrades — they live separately from the app bundle.

### Where do I report bugs?

Include these in your report so it's actionable: the Ferry build date, your macOS version, the stack type of the affected site, the operation that failed, and the step-by-step output from the History view (expand the failed run and copy the step detail). Redact anything sensitive. If the same operation runs fine from the terminal but fails in Ferry, mention that too — it's usually a clue about environment or path differences.
