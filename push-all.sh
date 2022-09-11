#!/usr/bin/env bash

git ls-files '*/main.tf' \
    | xargs dirname \
    | xargs -P4 -I {} coder templates push -y {} -d {}
