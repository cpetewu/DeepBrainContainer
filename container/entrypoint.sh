#! /bin/bash
#Make test script executable.
chmod +x ./DeepBrainNet/Script/test.sh

ROOT_DIR="./DeepBrainNet"
${ROOT_DIR}/Script/test.sh "$@" 
 
