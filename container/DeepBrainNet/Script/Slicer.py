from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import Normalizer
import nibabel as nib
# from nilearn import plotting
import re
import numpy as np
import pandas as pd
import os
from os import listdir, fsencode
import math
from PIL import Image
import sys
import os
import fnmatch

myDirectory = str(sys.argv[1])
Destination = str(sys.argv[2])

#directory = os.fsencode(myDirectory)

#Collect all the .nii.gz files into one list by finding them recursively
matches = []
for root, dirnames, filenames in os.walk(myDirectory):
    for filename in fnmatch.filter(filenames, '*.nii.gz'):
            matches.append(os.path.join(root, filename))

for index,file in enumerate(matches):
    myFile = os.fsencode(file)
    myFile = myFile.decode('utf-8')
    myNifti = nib.load((myFile))
    
    data = myNifti.get_data()
    data = data*(185.0/np.percentile(data, 97))

    scaler = StandardScaler()
   
    #Create a directory for the images.
    #Remove the .nii and .gz extensions.

    myFile = os.path.basename(myFile).replace('.gz','').replace('.nii','')

    slice_dest = os.path.join(Destination, myFile).replace('_processed','')
    os.mkdir(slice_dest) #Remove processed from the file name.
    
    for sl in range(0,80):
        x = sl

        clipped = data[:,:,(45+x)]

        image_data = Image.fromarray(clipped).convert('RGB')
        image_data.save(os.path.join(slice_dest, myFile[:-7] + '-'+str(x)+'.jpg'))
