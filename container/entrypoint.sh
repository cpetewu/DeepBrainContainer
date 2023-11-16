#! /bin/bash
#Make test script executable.
chmod +x ./DeepBrainNet/Script/test.sh

#Check fsl installation.
echo $FSLDIR
bet --version
which imcp

ROOT_DIR="./DeepBrainNet"
${ROOT_DIR}/Script/test.sh "$@" 
 
