# Ferry Concepts

This page explains the handful of ideas Ferry is built around. If you understand these seven concepts, the rest of the documentation will make sense without effort. Read it once; come back only if something in another guide feels out of context.

## Sites

A **site** is one website project you manage in Ferry. Each site has:

- A **local** half — your development copy, its database credentials, and the path to the project on disk.
- A **remote** half — the server it lives on, the SSH connection to reach it, and the remote database credentials.
- A set of **file sync paths** — pairs of directories Ferry will rsync between the two halves.
- Optional **hooks** — shell commands that run around each operation.
- Optional **hostname replacement** — URL substitution for database dumps.

Sites live in the Ferry sidebar. Each row shows the site's name, stack icon, and a colour accent. Click a site to open its **Dashboard**. Click the gear icon on the dashboard header to open the 5-tab config form.

Everything about a site is stored locally on your mac. Ferry does not sync sites between machines or upload anything to a cloud service.

## Environments

Each site has an **environment name** that describes its remote half — `Production`, `Staging`, `Development`, or anything you type. The environment is just a label, but Ferry uses it in several places:

- The dashboard's right-hand column header shows it in uppercase (`PRODUCTION`).
- Direction labels on operation cards read `Local ← PRODUCTION` (pull) or `Local → PRODUCTION` (push).
- Pushing to a site whose environment is marked as production triggers a confirmation sheet. This is the only guardrail against accidentally writing to prod.
- You can pick a colour for the environment so production sites stand out visually in the sidebar.

## Pull versus Push

Ferry's direction language is always relative to *your local machine*:

- **Pull** means the remote → your local.
- **Push** means your local → the remote.

Ferry uses arrows everywhere to keep this unambiguous. `Local ← Production` is a pull. `Local → Production` is a push. We avoid "download" and "upload" because they're ambiguous: is uploading a database file going to production, or are you uploading to S3? Ferry just says what's moving where.

Each of the four primary operations has a direction:

| Operation | Direction | What moves |
|---|---|---|
| Pull database | ← | Remote DB → local DB |
| Push database | → | Local DB → remote DB |
| Pull files | ← | Remote files → local files |
| Push files | → | Local files → remote files |

Backups stand outside this — they save a dump to a file and don't write to any database.

## Operations and runs

An **operation** is a user-triggered action like `Pull database` or `Push files`. Internally, each operation is a **pipeline** of **steps**.

A step is one shell command. A pipeline for `Pull database`, for example, has steps like `Prepare temp directory`, `Test SSH connection`, `Dump remote database`, `Import to local database`, and `Cleanup temp files`. Ferry runs them in order, streaming each step's output live to the `Activity` section on the dashboard.

A **run** is one execution of a pipeline. You can watch it happen; you can cancel it with `⌘.` mid-flight; when it finishes it moves into the activity history where you can expand it and see every step's output and duration. Rerun the last operation with `⌘R`.

If a step fails, the pipeline halts and the remaining steps are marked as skipped. Ferry does not try to "finish what it can" — a failed pull means your local database is in whatever state the failing step left it in, which is important to know for troubleshooting.

## Where your credentials live

All passwords — database and SSH — are stored in the **macOS Keychain**. Not in Ferry's own database file, not in a config file, not in an environment variable. The Keychain entry is keyed per site and per role (`local`, `remote`, `ssh`).

SSH keys are never copied into Ferry; only the *path* to the key file is stored. Ferry invokes `ssh` and lets it read the key from disk the same way any terminal SSH would.

Passwords are also redacted from every operation's step log before it's persisted — you can safely share an exported log without leaking credentials. SSH passwords, where used, are passed to `sshpass` via the process environment so they never appear in the shell command that gets logged.

## Hooks

**Hooks** are shell commands Ferry runs around each operation. There are four hook slots per site:

- **Pre-pull** — runs locally before a `Pull database` or `Pull files`.
- **Post-pull** — runs locally after a pull completes.
- **Pre-push** — runs locally before a `Push database`.
- **Post-push** — runs on the *remote* (via SSH) after a push.

Local hooks execute from the site's **Local document root**, so you can write `php artisan cache:clear` and trust that it runs in the right directory. If no local document root is configured, Ferry skips local hooks entirely and shows a warning in the Advanced tab.

Each line in a hook field is a shell command. Ferry pipes them through `zsh`, so anything your shell understands (pipes, environment variables, `&&` chains) works. Hooks run with your user permissions — don't paste shell you don't trust.

Each stack ships with sensible hook defaults. Click **Restore Defaults** in the Advanced tab to bring them back after editing. A few current examples: Craft CMS runs `php craft clear-caches/all` as a post-pull; SilverStripe runs `vendor/bin/sake dev/build flush=1`; Statamic runs `php artisan cache:clear` and `php artisan config:clear`. WordPress and Laravel currently ship with no default hooks — set what you need.

## Supported stacks

Ferry recognises six stack types. For auto-detection from a project folder, it looks for these markers:

- **WordPress** — `wp-config.php` file or a `wp-content/` directory. Credentials come from `wp-config.php` `define()` lines or a `.env` file. Default file sync path is `wp-content/uploads/`. Default admin path is `wp-admin`. Hostname replacement is enabled by default.
- **Craft CMS** — a `craft` binary in the project root or `craftcms/cms` in `composer.json`. Credentials come from `.env` (either the newer `CRAFT_DB_*` keys or legacy `DB_*`). Default file sync paths are `web/assets/` and `storage/`. Default admin path is `admin`.
- **Laravel** — an `artisan` file in the project root. Credentials come from `.env` (`DB_*`). Default file sync path is `storage/app/public/`.
- **Statamic** — `artisan` plus a `content/` directory, or `statamic/cms` in `composer.json`. Same `.env` format as Laravel. Default file sync paths include `storage/app/public/`, `content/`, and `users/`. Default admin path is `cp`.
- **SilverStripe** — a `vendor/silverstripe/` directory or `app/_config.php`. Credentials come from `.env` (`SS_DATABASE_*` keys) or legacy `_ss_environment.php`. Default file sync path is `public/assets/`. Default admin path is `admin`.
- **Custom** — fallback for anything Ferry doesn't recognise. You fill in everything manually and set your own file sync paths and hooks.

Whatever stack you pick, you can always edit the defaults for your project. The presets are a starting point, not a straitjacket.
