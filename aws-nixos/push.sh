#!/usr/bin/env bash

tar -cvh . | coder templates push -d - aws-nixos
