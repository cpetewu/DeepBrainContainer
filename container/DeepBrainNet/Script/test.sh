#! /bin/bash
DBN="./DeepBrainNet"
DBN_SCRIPTS=${DBN}"/Script"
DBN_MODELS=${DBN}"/Models"
HOSTPATH=''
MODEL=${DBN_MODELS}"/DBN_model.h5"
OUTPATH="${DATAMOUNT}/Output/Prediction.csv"
DATADIR=$DATAMOUNT/ImageData/
THRESHOLD=0.98

print_usage() {
  printf "\n\nUsage:\n\n"
  printf "\tRequired Parameters:\n\n"
  printf "\t %s\n\n"  "Docker must be run with the -v option to mount a volume for user IO." "Additionally, the mount point in the docker container must always be \"/usr/data\"," "i.e. your run command should be of the form \"docker run -v <your volume name (DBN_DATA default)>:/usr/data deepbrain ...\"" "The structure of this volume must be as follows."
  printf "\t %s\n" "MyDockerVolume"
  printf "\t\t %s\n" "+--ImageData/..." "|" "+--Output/" "|" "+--Models/...(optional)" 
  printf "\n\tOptional Parameters:\n\n"
  printf "\t %s\n\n" "[-m]: Specify Model files to use (.h5)." "[-o]: Specify the name of the output csv." "[-p]: Run brain extraction and linear registrationon provided images." "[-t]: Specify the threshold value for registraion flagging. Expects an overlap ratio (0.98 default)." 
  
  printf "\nExample: docker run -v DBN_DATA:/usr/data deepbrain -o myOutput.csv -m myModel.h5 -p -t 0.99\n\n"
  exit 1
}

brain_extraction() {
    
    #Check to see if the volume mounted correctly.
    if [ ! -d $DATAMOUNT/Preprocessing ]; then 
        printf "Preprocessing directory not found. Creating it now.\n"
        mkdir $DATAMOUNT/Preprocessing 

        #Check if the processed,overlay,flagged subdirectories exist.
        if [ ! -d $DATAMOUNT/Preprocessing/Processed ]; then
            printf "Creating Processed directory...\n "
            mkdir $DATAMOUNT/Preprocessing/Processed
        fi
        
        if [ ! -d $DATAMOUNT/Preprocessing/Flagged ]; then 
            printf "Creating Flagged directory...\n "
            mkdir $DATAMOUNT/Preprocessing/Flagged
        fi
    fi
    
    #Set the correct image data path.
    DATADIR="${DATAMOUNT}/Preprocessing/"
    
    $DBN_SCRIPTS/extract_images.sh ${THRESHOLD}
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


while getopts 'uho:m:pd:t:' flag; do
  case "${flag}" in
    u) print_usage ;;
    h) print_usage ;;
    o) OUTPATH="${DATAMOUNT}/Output/${OPTARG}" ;;
    d) HOSTPATH=$OPTARG ;;
    m) MODEL="${DATAMOUNT}/Models/${OPTARG}" ;;
    t) THRESHOLD=${OPTARG} ;;
    p) brain_extraction ;;
    *) print_usage
       exit 1 ;;
  esac
done

rm -r $DATAMOUNT/tmp/
mkdir $DATAMOUNT/tmp/

python3 ${DBN_SCRIPTS}/Slicer.py ${DATADIR} ${DATAMOUNT}/tmp/
python3 ${DBN_SCRIPTS}/Model_Test.py ${DATAMOUNT}/tmp/ ${OUTPATH} ${MODEL}

rm -r $DATAMOUNT/tmp/
