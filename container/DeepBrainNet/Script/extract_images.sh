#! /bin/bash

PREPROCESSING="${DATAMOUNT}/Preprocessing"
DEBUG="${DATAMOUNT}/debug"

mkdir -p $DEBUG

total_files=$(find "$DATAMOUNT/ImageData" -maxdepth 1 -type f | wc -l)
current_file=0

#Calculate the brain masks.
for brainimage in $DATAMOUNT/ImageData/*;
do
    ((current_file++))
    base_name=$(basename ${brainimage})
    base_name=${base_name%.nii.gz}
    mask_name=${base_name}_mask.nii.gz    

    out_dir=$DEBUG/$base_name
    mkdir $out_dir 

    printf "re-orienting to standard orientation %s (%d/%d)...\n" ${base_name} $current_file $total_files
    
    reoriented="${out_dir}/${base_name}_reoriented.nii.gz"
    fsl5.0-fslreorient2std "${brainimage}" "${reoriented}"

    printf "Performing brain extraction on %s (%d/%d)...\n" ${base_name} $current_file $total_files
    
    brain_mask="${out_dir}/${mask_name}"
    #Using Nick and Kalen's Brain Extraction technique.
    ./ROBEX/runROBEX.sh "${reoriented}" "${out_dir}/${base_name}_temp.nii.gz" "${brain_mask}" 
    #Remove the temp image because we are using the mask anyways.
    rm ${out_dir}/${base_name}_temp.nii.gz

    #Ensure we have really captured the whole brain.
    fsl5.0-fslmaths "${brain_mask}" -dilD -dilD -ero -fillh26 "${brain_mask}"  

    #Create the final image.
    extracted_brain="${out_dir}/${base_name}_extracted.nii.gz"
    fsl5.0-fslmaths "${brainimage}" -mul "${brain_mask}" "${extracted_brain}" 

    #Do bias feild correction.
    printf "Performing bias feild correction on %s (%d/%d)...\n" ${base_name} ${current_file} ${total_files}
    fsl5.0-fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -b -B "${extracted_brain}"
    
    bias_corrected="${out_dir}/${base_name}_extracted_restore.nii.gz"
    #Linear registration.
    printf "Performing linear registration on %s (%d/%d)...\n" ${base_name} $current_file $total_files
    fsl5.0-flirt -searchcost corratio -cost corratio -in "${bias_corrected}" -ref ./MNI152_T1_1mm_brain.nii.gz -out "${PREPROCESSING}/${base_name}_processed.nii.gz"

done
