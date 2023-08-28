#!/usr/bin/env bash

set -euo pipefail

VERB="${1:-push}"
REPO_ROOT="$(git rev-parse --show-toplevel)"

find "$REPO_ROOT/values" -name "*.yaml" -or -name "*.yml" | while read TEMPLATE_FILE
do
    TEMPLATE_NAME="$(basename $TEMPLATE_FILE | sed -E 's/\.ya?ml$//')"

    coder templates "$VERB" --yes -d "$REPO_ROOT" --variables-file "$TEMPLATE_FILE" "$TEMPLATE_NAME"
done
