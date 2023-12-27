#! /bin/bash

threshold_percent=$(bc -l <<< "${1}")

PREPROCESSING=$DATAMOUNT/Preprocessing
total_files=$(find "$DATAMOUNT/ImageData" -maxdepth 1 -type f | wc -l)
current_file=0
total_voxels=($(fsl5.0-fslstats ./MNI152_T1_1mm_brain.nii.gz -V))
registered_out=$PREPROCESSING/Processed
flagged_out=$PREPROCESSING/Flagged


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
    fsl5.0-fslmaths ${out_dir}/${mask_name} -dilD -dilD -ero -fillh26 ${out_dir}/${mask_name}  

    #Create the final image.
    fsl5.0-fslmaths $brainimage -mul ${out_dir}/${mask_name} ${out_dir}/${base_name}_extracted.nii.gz 

    #Now register the image.
    
    #Do bias feild correction.
    printf "Performing bias feild correction on %s (%d/%d)...\n" ${base_name} $current_file $total_files
    fsl5.0-fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -b -B ${out_dir}/${base_name}_extracted.nii.gz

    #Linear registration.
    printf "Performing linear registration on %s (%d/%d)...\n" ${base_name} $current_file $total_files
    fsl5.0-flirt -searchcost corratio -cost corratio -in ${out_dir}/${base_name}_extracted.nii.gz -ref ./MNI152_T1_1mm_brain.nii.gz -out ${registered_out}/${base_name}_processed.nii.gz
    
    #Now Lets see how well the linear registration worked.
    #Create a binaray mask for the registrated scan. 
    fsl5.0-fslmaths ${registered_out}/${base_name}_processed.nii.gz -bin ${out_dir}/${base_name}_processed_mask.nii.gz
    
    #Now lets calculate the overlay mask.
    fsl5.0-fslmaths ${out_dir}/${base_name}_processed_mask.nii.gz -mul ./MNI152_T1_1mm_brain_mask.nii.gz ${out_dir}/${base_name}_processed_mask_overlay.nii.gz
    
    overlay_voxels=($(fsl5.0-fslstats ${out_dir}/${base_name}_processed_mask_overlay.nii.gz -V))
    overlay_percent=$(bc -l <<< "${overlay_voxels}/${total_voxels}")


    if [ $(bc -l <<< "(${overlay_percent})<${threshold_percent}") -eq 1 ]; then
        printf "Auto QC detects a mask overlap of %f which is less than the set threshold value of %f, flagging for QC.\n\n" ${overlay_percent} ${threshold_percent}
        #Move scan to the Flagged folder.
        mv ${registered_out}/${base_name}_processed.nii.gz ${flagged_out}/${base_name}_processed.nii.gz
    else
        printf "Auto QC detects a mask overlap of %f which is greater than the set threshold value of %f.\n\n" ${overlay_percent} ${threshold_percent}
    fi
    #Clean up. 
    rm -r $out_dir

done
