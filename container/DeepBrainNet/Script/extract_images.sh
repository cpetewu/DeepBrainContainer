#! /bin/bash

PREPROCESSING=$DATAMOUNT/Preprocessing

total_files=$(find "$DATAMOUNT/ImageData" -maxdepth 1 -type f | wc -l)
current_file=0
#Calculate the brain masks.
for brainimage in $DATAMOUNT/ImageData/*;
do
    ((current_file++))
    base_name=$(basename ${brainimage})
    base_name=${base_name%.nii.gz}
    mask_name=${base_name}_mask.nii.gz
    
    out_dir=$PREPROCESSING/$base_name
    mkdir $out_dir 

    printf "Performing brain extraction on %s (%d/%d)...\n" ${base_name} $current_file $total_files

    #Using Nick and Kalen's Brain Extraction technique.
    ./ROBEX/runROBEX.sh $brainimage "${out_dir}/${base_name}_temp.nii.gz" "${out_dir}/${mask_name}" 
    
    #Remove the temp image because we are using the mask anyways.
    rm ${out_dir}/${base_name}_temp.nii.gz

    #Ensure we have really captured the whole brain.
    fslmaths ${out_dir}/${mask_name} -dilD -dilD -ero -fillh26 ${out_dir}/${mask_name}  

    #Create the final image.
    fslmaths $brainimage -mul ${out_dir}/${mask_name} ${out_dir}/${base_name}_extracted.nii.gz 

    #Now register the image.
    
    #Do bias feild correction.
    printf "Performing bias feild correction on %s (%d/%d)...\n" ${base_name} $current_file $total_files
    fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -b -B ${out_dir}/${base_name}_extracted.nii.gz

    #Linear registration.
    printf "Performing linear registration on %s (%d/%d)...\n" ${base_name} $current_file $total_files
    flirt -v -searchcost mutualinfo -cost mutualinfo -in ${out_dir}/${base_name}_extracted.nii.gz -ref ./MNI152_T1_1mm_brain_LPS_filled.nii.gz -out ${PREPROCESSING}/${base_name}_processed.nii.gz

    #Clean up. 
    rm -r $out_dir

done
