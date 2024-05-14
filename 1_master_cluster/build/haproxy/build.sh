#!/bin/bash
set -euo pipefail

export DOCKER=docker

$DOCKER build -t haproxy-dap:latest .
