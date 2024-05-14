#!/bin/bash
set -euo pipefail

$DOCKER build -t haproxy-dap:latest .
