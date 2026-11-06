#!/usr/bin/env bash
#
# herdr-space-numbers: give every space its current number as the $num token.
# Numbers shift when spaces close or move, so this rewrites all of them.

set -euo pipefail

herdr workspace list \
    | jq -r '.result.workspaces[] | "\(.workspace_id) \(.number)"' \
    | while read -r id number; do
        herdr workspace report-metadata "$id" --source space-numbers --token "num=$number" >/dev/null
    done
