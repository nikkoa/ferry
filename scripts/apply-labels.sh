#!/bin/zsh
# One-time setup: apply Ferry's issue labels to this GitHub repository.
# Requires: the `gh` CLI authenticated against github.com/nikkoa/ferry.
#
# Usage: bash scripts/apply-labels.sh
#
# Safe to re-run — `gh label create --force` updates existing labels with
# the same name instead of erroring.

set -euo pipefail

label() {
    local name="$1" color="$2" desc="$3"
    gh label create "$name" --color "$color" --description "$desc" --force >/dev/null
    echo "  $name"
}

echo "==> Applying Ferry issue labels"

# Triage / state
label "bug"            "d73a4a" "Something is broken"
label "enhancement"    "a2eeef" "New feature or improvement"
label "documentation"  "0075ca" "Docs or copy changes"
label "question"       "d876e3" "Further information is requested"
label "needs-triage"   "fbca04" "Untriaged — waiting on a first look"
label "needs-info"     "ffae42" "More information needed from the reporter"
label "good first issue" "7057ff" "Good entry point for new contributors"
label "help wanted"    "008672" "Extra attention is welcome"
label "duplicate"      "cfd3d7" "Already reported elsewhere"
label "wontfix"        "ffffff" "This will not be worked on"
label "regression"     "b60205" "Worked in a previous build"

# Stack-specific
label "stack:wordpress"    "21759b" "Affects WordPress sites"
label "stack:craft"        "e5422b" "Affects Craft CMS sites"
label "stack:laravel"      "ff2d20" "Affects Laravel sites"
label "stack:statamic"     "ff269e" "Affects Statamic sites"
label "stack:silverstripe" "0071c5" "Affects SilverStripe sites"
label "stack:custom"       "cfd3d7" "Affects Custom-stack sites"

# Area
label "area:database"      "5319e7" "Database Pull / Push / Backup"
label "area:files"         "0e8a16" "File Pull / Push (rsync)"
label "area:ssh"           "1d76db" "SSH connectivity, keys, hosts"
label "area:ui"            "c5def5" "SwiftUI views and layout"
label "area:config"        "bfe5bf" "Site configuration forms"
label "area:hooks"         "c2e0c6" "Pre/post hooks"
label "area:history"       "fef2c0" "History view and logs"

echo ""
echo "✅ Labels applied"
