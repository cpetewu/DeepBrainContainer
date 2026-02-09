#!/bin/bash
set -e

echo "ARGS RECEIVED: $@"

ROOT_DIR="./DeepBrainNet"
exec ${ROOT_DIR}/Script/test.sh "$@"
