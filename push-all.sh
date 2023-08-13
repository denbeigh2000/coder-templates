#!/usr/bin/env bash

set -euo pipefail

coder templates push --yes -d . aws-nixos               --variable arch=x86_64  --variable is_spot=false
coder templates push --yes -d . aws-spot-nixos          --variable arch=x86_64  --variable is_spot=true
coder templates push --yes -d . aws-spot-nixos-graviton --variable arch=aarch64 --variable is_spot=true
