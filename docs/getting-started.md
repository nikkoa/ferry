# Getting Started with Ferry

Ferry is a native macOS app that syncs databases and files between your local and remote web development environments. You register a site once — local credentials, remote SSH, file paths — and from then on a one-click Pull or Push runs the whole pipeline for you. No custom scripts per project.

This guide walks you from installing Ferry to running your first successful `Pull database`.

## What you'll need

- macOS 14 (Sonoma) or later
- SSH access to your remote server (key auth recommended)
- A handful of command-line tools on your `$PATH`: `mysql`, `mysqldump`, `ssh`, `rsync`, `gzip`

If you don't have them, one Homebrew command covers the basics:

```bash
brew install mysql-client rsync
```

On Apple Silicon macs, Homebrew puts `mysql` under `/opt/homebrew/bin`, which Ferry picks up automatically. If you use MAMP, DBngin, or a non-default MySQL install, see the **Using a custom MySQL binary** section in the Advanced guide — Ferry lets you point at any `mysql` binary per site.

If you plan to use SSH *password* auth (instead of keys), also install:

```bash
brew install hudochenkov/sshpass/sshpass
```

Key auth works out of the box with no extra install.

## Installing Ferry

1. Download the latest Ferry `.dmg` from the Ferry website.
2. Open the DMG and drag **Ferry** into your `Applications` folder.
3. Launch Ferry from Spotlight or the Applications folder.

## Adding your first site

Ferry gives you two paths: auto-detect from a project folder, or add everything manually. Auto-detect is faster if your project is a supported stack.

### Option A — from a project folder (recommended)

1. In the left sidebar, click **Add from Project**. Or use `⌘⇧O` from anywhere in the app.
2. Pick your project's root directory in the file picker — for example `~/Sites/my-blog`.
3. Ferry scans the folder, detects the stack (WordPress, Craft CMS, Laravel, Statamic, SilverStripe, or Custom), and reads credentials from your `.env` or `wp-config.php`.
4. A preview sheet shows what Ferry found: stack type, database host/user/name, site URL. Confirm to create the site.
5. The new site appears in the sidebar. The **Local** tab is pre-filled. You still need to fill in the **Remote** tab manually — Ferry can't guess your production SSH host.

Ferry reads these keys out of common config files:

| Stack | Reads from | Keys |
|---|---|---|
| Laravel, Statamic | `.env` | `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DB_DATABASE` |
| Craft CMS | `.env` | `CRAFT_DB_SERVER`, `CRAFT_DB_PORT`, `CRAFT_DB_USER`, `CRAFT_DB_PASSWORD`, `CRAFT_DB_DATABASE` (falls back to `DB_*`) |
| WordPress | `wp-config.php` | `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` |
| SilverStripe | `.env` or `_ss_environment.php` | `SS_DATABASE_SERVER`, `SS_DATABASE_USERNAME`, `SS_DATABASE_PASSWORD`, `SS_DATABASE_NAME` |

### Option B — manually

1. Click **New Site** in the sidebar, or press `⌘N`.
2. The new site opens with its config form. Fill in each tab:
   - **General** — name, stack type, environment name (e.g. `Production`), optional notes, optional colour, local and remote URLs for hostname replacement.
   - **Local** — your local database host, port, user, password, database name, and the site's local document root (e.g. `/Users/you/Sites/my-blog`).
   - **Remote** — SSH host, port, user, and either an SSH key path or an SSH password. Then the remote database credentials (host `127.0.0.1` if the DB is on the same server as SSH), and the remote document root.
   - **File Paths** — one or more pairs of local/remote subpaths. Ferry ships sensible defaults per stack (for example `wp-content/uploads/` for WordPress). Each pair has an exclude list.
   - **Advanced** — optional hooks, admin panel path, hostname replacement settings, table exclusions.

### Pasting from `.env`

Both the **Local** and **Remote** tabs have a **Paste .env** button. Copy the relevant `.env` or `define()` lines from your project, click the button, and Ferry parses out the database credentials into the form fields. Quoted values, comments, and `host:port` forms are all handled.

## Testing your connections

Before running any real operation, verify your config.

1. Open the **Local** tab. At the bottom of the DB section, click **Test Connection**. Ferry runs `mysql` against your local database and reports the result.
2. Open the **Remote** tab. Click **Test Connection** next to the SSH section first — this verifies that Ferry can reach the remote host with the key or password you configured. Then click **Test Connection** in the remote DB section — if you chose SSH tunnel mode, Ferry runs the DB test *through* the SSH session.

You'll see one of these results:

- **Connection successful** — you're good.
- **Authentication failed** — check your password, SSH key path, or that the remote user actually has DB access.
- **Connection refused** — the host is reachable but nothing is listening on that port.
- **Connection timed out** — the host isn't reachable at all. Check the hostname, VPN, firewall.
- **Host not found** — the hostname doesn't resolve. Typo or DNS issue.

Fix any failures here before running an operation — Ferry won't magically succeed later if the connection test fails now.

## Running your first Pull database

With a working site configured and connections green, you're ready.

1. Click the site in the sidebar to open its **Dashboard**.
2. The dashboard shows two columns: **LOCAL** on the left and your remote environment (e.g. **PRODUCTION**) on the right. Under **LOCAL** you'll see operation cards including **Pull database** and **Pull files**.
3. Find the **Pull database** card. At the bottom of the card is a slider that says **Slide to pull** with a blue circular thumb. Press and drag the thumb to the left. As it passes the three-quarter mark, the hint changes to **Release to confirm**.
4. Release. Ferry starts the pipeline.
5. Scroll down to the **Activity** section. The current run appears at the top. Click it to expand. You'll see each step light up in sequence:
   - **Prepare temp directory**
   - **Test SSH connection**
   - **Dump remote database** (with a per-table progress bar)
   - **Replace hostnames** (if you enabled hostname replacement)
   - **Import to local database** (with a per-table progress bar)
   - **Run post-pull hooks** (if you configured any)
   - **Cleanup temp files**
6. Each step streams its output live. A successful step turns green with a checkmark. A failed step turns red and halts the pipeline.
7. When the pipeline finishes, the card briefly shows **Pull database complete** in green before returning to idle.

To cancel a run mid-flight, press `⌘.` — Ferry terminates the current step and marks the rest as skipped.

To repeat the last operation on the same site, press `⌘R`.

## Where to go next

- **concepts.md** — the mental model behind sites, environments, pipelines, and hooks.
- **operations.md** — every operation in detail: Push, backups, file sync, Full Sync.
- **advanced.md** — hostname replacement, table exclusions, hooks, MySQL binary override.
- **faq.md** — answers to common questions and troubleshooting for the sharp edges.
