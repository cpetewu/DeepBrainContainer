#! /bin/bash
#Make test script executable.
chmod +x ./DeepBrainNet/Script/test.sh
. ${FSLDIR}/etc/fslconf/fsl.sh

#Activate conda for fsl.
conda activate base

ROOT_DIR="./DeepBrainNet"
${ROOT_DIR}/Script/test.sh "$@" 
 
