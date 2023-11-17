#! /bin/bash
DBN="./DeepBrainNet"
DBN_SCRIPTS=${DBN}"/Script"
DBN_MODELS=${DBN}"/Models"
HOSTPATH=''
MODEL=${DBN_MODELS}"/DBN_model.h5"
OUTPATH="${DATAMOUNT}/Output/Prediction.csv"
DATADIR=$DATAMOUNT/ImageData/

print_usage() {
  printf "\n\nUsage:\n\n"
  printf "\tRequired Parameters:\n\n"
  printf "\t %s\n\n"  "Docker must be run with the -v option to mount a volume for user IO." "The structure of this volume must be as follows."
  printf "\t %s\n" "MyDockerVolume"
  printf "\t\t %s\n" "+--ImageData/..." "|" "+--Output/" "|" "+--Models/...(optional)" 
  printf "\n\tOptional Parameters:\n\n"
  printf "\t %s\n\n" "[-m]: Specify Model files to use (.h5)." "[-o]: Specify the name of the output csv." "[-p]: Run brain extraction and linear registrationon provided images." 
  
  printf "\nExample: docker run -it -v DBN_DATA:/usr/data DeepBrain -o myOutput.csv -m myModel.h5\n\n"
  exit 1
}

brain_extraction() {
    
    #Check to see if the volume mounted correctly.
    if [ ! -d $DATAMOUNT/Preprocessing ]; then 
        printf "Preprocessing directory not found. Creating it now.\n"
        mkdir $DATAMOUNT/Preprocessing 
    fi
    
    #Set the correct image data path.
    DATADIR="${DATAMOUNT}/Preprocessing/"
    
    $DBN_SCRIPTS/extract_images.sh 
}

#Check to see if the volume mounted correctly.
if [ ! -d $DATAMOUNT/ImageData ]; then 
    
    printf "\n\nVolume not mounted correctly.\n\n" 
    print_usage 
    exit 1 
fi

#Check to see if the volume mounted correctly.
if [ ! -d $DATAMOUNT/Output ]; then 
    
    printf "Output folder not found in volume, creating it...\n" 
    mkdir $DATAMOUNT/Output
fi

while getopts 'uho:m:pd:' flag; do
  case "${flag}" in
    u) print_usage ;;
    h) print_usage ;;
    o) OUTPATH="${DATAMOUNT}/Output/${OPTARG}" ;;
    d) HOSTPATH=$OPTARG ;;
    m) MODEL="${DATAMOUNT}/Models/${OPTARG}" ;;
    p) brain_extraction ;;
    *) print_usage
       exit 1 ;;
  esac
done

rm -r ../tmp/
mkdir ../tmp/
mkdir ../tmp/Test/

python3 ${DBN_SCRIPTS}/Slicer.py ${DATADIR} ../tmp/
python3 ${DBN_SCRIPTS}/Model_Test.py ../tmp/ ${OUTPATH} ${MODEL}

