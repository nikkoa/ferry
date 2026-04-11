# Advanced Features

Past the basics, Ferry has a handful of features for when your setup doesn't quite match the defaults. Nothing here is required — you can run Ferry happily without touching any of it — but each of these solves a specific real-world problem.

## Hostname replacement

Your local dev site is almost certainly on a different domain than production. Maybe production is `www.example.com` and local is `example.test` or `localhost:8080`. When you Pull the production database, all those absolute URLs come with it: hard-coded in content, in settings, in serialised option values. Hostname replacement rewrites them during the pull so your local site renders correctly.

### How to enable it

1. Open the site's **General** tab and fill in the **Local URL** (e.g. `https://example.test`) and **Remote URL** (e.g. `https://www.example.com`) fields. Both are required.
2. Open the **Advanced** tab and toggle **Replace hostnames in SQL dumps** on. The toggle is disabled until both URLs are set — Ferry won't let you enable a broken config.
3. With the toggle on, a preview box appears in the Advanced tab showing the exact substitutions Ferry will perform for Pull and Push. It looks something like:

   ```
   REPLACEMENTS
   Pull   www.example.com  →  example.test
   Push   example.test     →  www.example.com
   ```

   Use the preview to verify the substitution before your first sync.

### How it works

During `Pull database`, after the remote dump completes and before import, Ferry runs a `sed` pass over the dump file. It handles two forms of URL that can appear in a dump:

- **Plain text** — the URL as it lives in regular VARCHAR/TEXT fields, e.g. `https://www.example.com`. This catches post content, option values, meta fields, and most places URLs appear.
- **Backslash-escaped in JSON blobs** — PHP's `json_encode` escapes slashes to `\/` when serialising URLs into JSON. Stored in a TEXT column, that sequence is two characters (backslash + slash). When `mysqldump` writes that value into the dump file it doubles every literal backslash for SQL string-literal escaping, so the dump file contains `https:\\/\\/www.example.com` (two backslashes + slash per original slash). Ferry rewrites this form too, so URLs inside ACF fields, Gutenberg block attributes, plugin settings, and anything else stored as JSON are handled.

Ferry replaces the **full URL** (scheme + host + optional path), not just the hostname. That means if your local uses `http://` and remote uses `https://`, the scheme gets swapped along with the host. The preview box in the Advanced tab shows the exact Pull and Push substitutions Ferry will perform — verify it matches your intent before running a sync.

During `Push database` the substitution runs in reverse (local URL → remote URL), both forms.

### The WordPress serialised-data caveat

WordPress stores many things — plugin options, widget settings, theme mods — as PHP-serialised strings. A serialised string records its own length as part of the data: `s:14:"www.example.com"`. If you use `sed` to rewrite `www.example.com` to `example.test`, the string is now 12 characters but still claims to be 14, and WordPress will silently fail to unserialise it.

Ferry's hostname replacement is byte-level `sed` — it **does not** update PHP-serialised string lengths. For WordPress sites with serialised data (most of them), add a post-pull hook that runs `wp search-replace`, which knows about PHP serialisation:

```
wp search-replace 'https://www.example.com' 'https://example.test' --all-tables
```

With this hook in place, you can leave the Ferry-level hostname replacement off or on — either is fine, since `wp search-replace` will fix up anything `sed` missed. The Advanced tab shows a warning pointing to this caveat when you enable hostname replacement on a WordPress site.

## Table exclusions

Large tables — session stores, search indexes, error logs, cache tables — can multiply the size of your database dump by 10x without giving you any data you actually need on your local copy. Table exclusions let you leave those tables out.

There are two exclusion modes:

- **Full** — the table is omitted from the dump entirely. Your local database won't have the table at all (or will keep whatever was there before the pull). Use this for session tables and other things you genuinely don't care about having locally.
- **Data only** — the table's schema is dumped but its rows are not. The local version of the table gets emptied on import. Use this for large-but-structurally-important tables where you need the table to exist but don't need its current contents — typical examples are cache tables, log tables, and search index tables.

### How to configure

In the **Advanced** tab, find the **Table Exclusions** section. Click **Configure** to open the table picker. If Ferry can reach your remote database, it will fetch the actual table list so you can check the tables you want to exclude. Pick each one's mode (Full or Data only) and save.

You can configure table exclusions manually without a remote connection — just type table names into the picker.

### What you'll see at runtime

When you run a Pull database with exclusions configured, the `mysqldump` command gets `--ignore-table=<db.table>` flags for each excluded table. Data-only exclusions trigger an extra step in the pipeline — **Dump excluded table schemas** — which runs a second `mysqldump --no-data` against just those tables and appends the output to the main dump.

## Writing custom hooks

Hooks give you an escape hatch. Anything you'd normally run from the terminal after a DB pull — clearing caches, regenerating search indexes, restarting workers — put it in a hook and it runs automatically.

### Where hooks run

- **Pre-pull**, **Post-pull**, and **Pre-push** hooks run on your *local* machine. Ferry `cd`s into the site's **Local document root** before running them, so relative paths and stack-specific commands (like `php artisan`) work.
- **Post-push** hooks run on the *remote* via SSH. Ferry `cd`s into the site's **Remote document root** on the server before running them.

If you try to configure pre-pull, post-pull, or pre-push hooks without a Local document root set, the Advanced tab shows a warning and Ferry skips those hook steps at runtime. Set the local document root in the **Local** tab to unblock them.

### The shell warning

Every line in a hook field is executed as a shell command through `zsh`. Pipes, variable expansion, `&&` chains, subshells — all work. The Advanced tab has a warning caption spelling this out. The takeaway: **don't paste hook content you don't understand**. A malicious hook line can do anything your user account can do.

### Practical examples

```bash
# Clear Craft CMS caches after a pull
php craft clear-caches/all

# Regenerate WordPress search-replace for serialised URLs
wp search-replace 'https://www.example.com' 'https://example.test' --all-tables

# Touch a sentinel file after a sync completes
touch storage/.last-sync

# Chain cleanup + cache clear
rm -rf storage/cache/* && php artisan cache:clear
```

### Restoring defaults

Each hook field has a **Restore Default** button that reverts to the stack's default for that slot. A separate **Restore Defaults** button at the top of the Advanced tab restores all four hook fields at once.

## Using a custom MySQL binary

Ferry calls `mysql` and `mysqldump` from your `$PATH` by default. On most setups this works, but sometimes you need a specific binary:

- **Homebrew on Apple Silicon** — puts MySQL under `/opt/homebrew/bin/mysql`. Ferry should find it automatically, but if it doesn't, override explicitly.
- **MAMP / AMPPS / XAMPP** — bundled MySQL lives somewhere like `/Applications/MAMP/Library/bin/mysql`.
- **Multiple MySQL versions** — if you have both MySQL 5.7 and 8.0 installed, you may want a specific site to always use one version.
- **MariaDB vs MySQL** — point at `mariadb` (which still works for most dumps).

### How to override

In the **Advanced** tab, scroll to **MySQL Client Binary** and toggle **Override path** on. Enter the absolute path to the `mysql` binary, or click the folder icon to browse for it. Ferry uses that path for `mysql` directly, and derives `mysqldump`'s path from the same directory (so you need both binaries in the same folder).

The override is per-site, so you can have one site using Homebrew's MySQL and another using MAMP's without interfering.

## Importing credentials from `.env`

Typing database credentials into config forms is tedious and error-prone. If you already have them in a `.env` file (or `wp-config.php`), use **Paste .env**:

1. Open the **Local** tab (or **Remote** tab — the button is on both).
2. Click **Paste .env**.
3. A sheet opens with a text area. Paste the relevant lines from your `.env` or `wp-config.php`.
4. Click Import. Ferry parses the lines and fills in whichever database fields it can match.

### Recognised keys

| Variant | Keys |
|---|---|
| Laravel / generic | `DB_HOST`, `DB_PORT`, `DB_USERNAME` / `DB_USER`, `DB_PASSWORD`, `DB_DATABASE` / `DB_NAME`, `DB_SOCKET` |
| Craft CMS (4/5) | `CRAFT_DB_SERVER`, `CRAFT_DB_PORT`, `CRAFT_DB_USER`, `CRAFT_DB_PASSWORD`, `CRAFT_DB_DATABASE` |
| WordPress (`wp-config.php`) | `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` (in `define()` form) |
| SilverStripe (4+) | `SS_DATABASE_SERVER`, `SS_DATABASE_PORT`, `SS_DATABASE_USERNAME`, `SS_DATABASE_PASSWORD`, `SS_DATABASE_NAME` |

Quoted values, inline comments, and `host:port` / `host:/path/to/socket` forms for WordPress `DB_HOST` are all handled. You can paste a whole `.env` file — Ferry will ignore unrelated lines and only pick out the keys it knows.
