#!/usr/bin/env bash

set -euo pipefail

VERB="${1:-push}"

find values -name "*.yaml" -or -name "*.yml" | while read TEMPLATE_FILE
do
    TEMPLATE_NAME="$(basename $TEMPLATE_FILE | sed -E 's/\.ya?ml$//')"

    coder templates "$VERB" --yes -d . "$TEMPLATE_NAME" --variables-file "$TEMPLATE_FILE"
done
