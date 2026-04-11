# Operations

Ferry has six user-initiated operations. Each is a pipeline: an ordered sequence of shell commands that Ferry runs for you and reports on live. This guide covers what each operation does, how to run it, the steps you'll see in the activity log, and the things that commonly trip people up.

If a term in this page is unfamiliar, check the concepts guide.

## Pull database

**Pull database** is Ferry's flagship operation. It dumps the remote database over SSH, optionally rewrites URLs with `sed`, and imports the result into your local database.

### When to use it

Any time your local copy has drifted from production (or whatever remote you work against) and you want a fresh snapshot. A typical pattern: pull the DB every Monday morning so your local dev environment tracks real user data.

### How to run it

On the site's Dashboard, find the **Pull database** card in the left-hand **LOCAL** box. At the bottom of the card is a slider with a blue thumb labelled **Slide to pull**. Drag the thumb left. When the hint changes to **Release to confirm**, let go.

### Steps you'll see

Expand the run in the **Activity** section and you'll see:

1. **Prepare temp directory** — creates a scratch folder for the dump file.
2. **Test SSH connection** — confirms Ferry can reach the remote before wasting time on a large dump.
3. **Dump remote database** — runs `mysqldump` on the remote (via SSH), gzips the output, and writes it locally. A per-table progress bar tracks progress.
4. **Dump excluded table schemas** — only appears if you have data-only table exclusions configured. Dumps schema (no rows) for the excluded tables so they still exist in your local DB after import.
5. **Replace hostnames** — only appears if hostname replacement is enabled and both URLs are set. A `sed` pass rewrites the remote hostname to the local hostname in the SQL file.
6. **Import to local database** — gunzips the dump and pipes it to `mysql` on your local machine. Another per-table progress bar.
7. **Run pre-pull hooks** — only if you have pre-pull hooks configured. Runs them locally in the site's Local document root.
8. **Run post-pull hooks** — only if you have post-pull hooks. Same execution model.
9. **Cleanup temp files** — deletes the scratch dump file.

### What to watch for

- If your production database is large, the **Dump** and **Import** steps will dominate the total runtime. Ferry's per-table progress lets you estimate how far along you are.
- If hostname replacement runs but your WordPress site still has the old URL in serialised data, you need a `wp search-replace` post-pull hook — `sed` can't update serialised PHP string lengths. See the hostname replacement section of the Advanced guide.
- If a hook fails, the `Cleanup temp files` step still runs, but the rest of the pipeline halts. Your local DB will already have the imported dump.
- If the SSH test fails up front, nothing after it runs — nothing on your local DB is touched.

## Push database

**Push database** is the mirror of Pull: it dumps your local DB and imports it to the remote. Because this *writes* to a real environment, Ferry is conservative about when it asks for confirmation.

### When to use it

Restoring a staging environment from a known-good local snapshot, seeding a fresh production install, or reverting a misbehaving remote. You should almost never Push to a live production environment that has user data in it without taking a Remote backup first.

### How to run it

Same as Pull, but the card lives in the right-hand environment box (e.g. **PRODUCTION**), and the slider has a coral thumb labelled **Slide to push**. Drag right; release past the **Release to confirm** threshold.

If the site's environment is set to `Production`, Ferry shows a confirmation sheet before the pipeline starts. You have to explicitly confirm.

### Steps you'll see

1. **Prepare temp directory**
2. **Test SSH connection** — only if using SSH mode for the remote DB.
3. **Run pre-push hooks** — local hooks, run in the site's Local document root.
4. **Dump local database** — `mysqldump` on your local machine, piped through `gzip`.
5. **Replace hostnames** — if enabled, rewrites your local URL to the remote URL (reverse of Pull).
6. **Import to remote database** — pipes the dump through SSH into `mysql` on the remote.
7. **Run post-push hooks** — runs on the *remote* via SSH, not locally. Useful for clearing a server-side cache, restarting a queue worker, etc.
8. **Cleanup temp files**

### What to watch for

- If the site is marked as `Production`, **always take a Remote backup first**. Ferry will not do this automatically.
- Post-push hooks need the remote document root set in the **Remote** tab, otherwise Ferry has nowhere to `cd` before running them on the server.
- Post-push hooks only run if SSH mode is active. Direct-DB mode has no way to execute commands on the remote.

## Pull files

**Pull files** uses `rsync` over SSH to bring remote files to your local machine.

### When to use it

When you need the actual uploaded media — user-uploaded images, generated thumbnails, user avatars — on your local copy so the site doesn't render with broken image placeholders.

### How to run it

Below **Pull database** on the dashboard is a **Pull files** card with the same slider pattern.

### Steps you'll see

1. **Test SSH connection**
2. **Run pre-pull hooks** — if configured. Skipped if the local document root isn't set.
3. **Pull files: <remote path>** — one step per file sync path pair configured in the **File Paths** tab. Each step is a separate `rsync` invocation with the per-path exclude list applied.
4. **Run post-pull hooks** — if configured.

### What to watch for

- Ferry passes the `-avz --progress` flags to rsync so you get per-file progress in the step's streaming output. Large wp-content directories can take a while — don't assume it's stuck unless there's been no output for several minutes.
- **File sync currently requires SSH key auth.** Rsync invokes the system `ssh` binary directly, bypassing the `sshpass` layer Ferry uses for DB operations. If your SSH is password-only, file sync will fail — set up a key instead.
- The `excludes` list on each file sync path pair is passed through as `--exclude=...` to rsync. Ferry ships with `.DS_Store` excluded by default.

## Push files

**Push files** is the reverse — `rsync` from local to remote. Same slider, same step structure, with a production confirmation sheet when pushing to a production-tagged environment.

Watch out: pushing over an existing remote directory will overwrite remote files with the local versions. Rsync does not delete remote files that don't exist locally unless you explicitly add `--delete` to the flags (Ferry currently does not).

## Local backup and Remote backup

Backups dump a database to a file on your local machine without importing it anywhere. There are two backup cards on the dashboard: **Local backup** (dumps your local DB) and **Remote backup** (dumps the remote DB, via SSH if SSH mode is configured).

### When to use it

- **Before any push to production.** A Remote backup gives you an instant rollback point if the push corrupts something.
- **Snapshots of local dev state** before running a risky migration locally.
- **Routine archives** — set a retention count and let Ferry handle cleanup.

### How to run it

Backups don't use the slide-to-run gesture. Click the **Run backup** button on the card. If you have "Ask each time" enabled, Ferry shows a dialog asking where to save the file; otherwise it uses the backup directory and filename pattern configured in the **General** tab.

### Steps you'll see

1. **Create backup directory** — ensures the save directory exists.
2. **Dump local database** or **Dump remote database** (or **Dump remote database via SSH**) — runs `mysqldump` and pipes through the configured compression (`none`, `gzip`, or `zip`).
3. **Verify backup file** — checks that the output file exists and is non-empty.

### What to watch for

- **Retention** only touches backups for *this specific site and target*. Ferry matches against a filename prefix derived from your site name + environment, so if site A and site B share the same backup directory, retention for A won't delete B's backups. Files unrelated to Ferry are never touched.
- Backup files are named with a timestamp suffix, so you can keep a history as deep as your retention count. The default retention is 10.
- If you pick `zip` compression, Ferry writes an `.sql` temp file first, then zips it — so you'll briefly see a larger file on disk before it's compressed.
- Backups are pure exports — they don't import into another database. To restore, you'll `gunzip` / `unzip` and pipe the SQL into `mysql` manually.

## Full Sync

**Full Sync** is a combined pipeline: a `Pull database` followed by a `Pull files` in one run. The SSH test and pre-pull hooks run once at the start rather than being duplicated.

### When to use it

Bootstrapping a fresh local copy of a site you haven't worked on in a while. One click, full reset.

### When NOT to use it

If you just want fresh data, Pull database alone is faster. If you just want fresh images, Pull files alone skips the whole database transfer. Full Sync is heavier; only reach for it when you want both.

### Steps you'll see

The same steps as Pull database, followed by the `Pull files: ...` steps for each configured path pair. The pre/post-pull hooks run once, not twice — Ferry is smart enough to dedupe them between the two sub-pipelines.

## Cancelling and retrying

Any running operation can be cancelled with `⌘.` (Command-period). Ferry terminates the current step's process and marks the remaining steps as skipped.

To rerun the last operation on the same site without reconfiguring anything, press `⌘R`. Ferry uses exactly the same config it used last time.
