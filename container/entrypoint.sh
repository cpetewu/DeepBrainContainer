#! /bin/bash
#Make test script executable.
chmod +x ./DeepBrainNet/Script/test.sh
. ${FSLDIR}/etc/fslconf/fsl.sh

ROOT_DIR="./DeepBrainNet"
${ROOT_DIR}/Script/test.sh "$@" 
 
