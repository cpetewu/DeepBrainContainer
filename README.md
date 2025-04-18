# DeepBrainContainer
A [docker](https://www.docker.com/) container for [DeepBrainNet](https://github.com/vishnubashyam/DeepBrainNet) (DBN).

This tool additionally includes optional preprocessing using [ROBEX](https://www.nitrc.org/projects/robex) for brain extraction and [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FLIRT) for linear regirstration to the MNI152 target atlas.

## Installation
This package can be downloaded and built on any system with docker. The only requirements are the `neurodebian:buster` and `hello-world` * base images.

To get these images run the following commands:
1. `docker pull hello-world` *
2. `docker pull neurodebian:buster`

Additionally, the DeepBrainNet model is __not__ included in this repository. The default model should be downloaded from [DeepBrainNet](https://github.com/vishnubashyam/DeepBrainNet) and placed within the default models directory:
`./container/DeepBrainNet/Models/DBN_model.h5`

To build this image, download the source code from this repository then run: `docker build container/ -t deepbrain`.
This should gather the required packages and requirements for all software in the image and install it in the image.

*__NOTE__:  Only required if you are going to use the `move2volume.sh` helper script for file IO.

## Usage
### Dealing with file IO

The general workflow for using this docker container is as follows:
1. Create a docker volume to upload your data to (can be done manually or with `move2volume.sh`).
2. Run the docker container with `docker run`.
3. Move the data back to your local directory (can be done manually or with `move2volume.sh`).

Docker requires either the use of file mounts or docker volumes for file IO when interacting with docker containers. This project uses docker volumes as they are abstracted away from host OS requirements and thus are most portable.

The script `move2volume.sh` is a wrapper around some basic docker commands which help the user view, read, and write information to and from docker volumes. This wrapper will only work on some linux environments, though one could use the source code as a guide to interact with docker volumes manually.

For usage use the command `./move2volume.sh -h` in the directory the script is located.
```
$ ./move2volume.sh -h

Usage:

        Parameters:

         [-d]: Specify the source data directory and move to volume.

         [-y]: Copy the volume output data to host machine at this directory. *

         [-c]: Clean the volume directory.

         [-p]: List the directory information of the volume. **

         [-v]: Specify the name of the volume you want to write to or read from (DBN_DATA is default). THIS MUST PRECEED ANY OTHER OPTIONS.

         [-h]: Print this menu.
```
__-v__: When specifying a specific volume this option must be the first option specified. Otherwise the program will use DBN_DATA when executing the other options for any function specified before -v is set.

*__NOTE__: When specifying the directory for this command it is best to navigate into the directory you wish to copy and specify `.` as the directory, otherwise
           some directories might not get copied depending on how the directory is specified.

**__NOTE__: This will list all the directories with `/volume` as the first directory, this is the mount point that a temporary docker contianer is using to list
            out directory information. When considering the actual file structure of the volume disregard `/volume` from the path. 

### Processing

The usage for this container can be found via the command: `docker run deepbrain -h` which will output the following:
```
$ docker run deepbrain -h

Volume not mounted correctly.



Usage:

        Required Parameters:

         Docker must be run with the -v option to mount a volume for user IO.

         Additionally, the mount point in the docker container must always be "/usr/data", i.e. your run command should be of the form "docker run -v <your container name (DBN_DATA default)>:/usr/data deepbrain ..."

         The structure of this volume must be as follows.

         MyDockerVolume
                 +--ImageData/...
                 |
                 +--Output/
                 |
                 +--Models/...(optional)

        Optional Parameters:

         [-m]: Specify Model files to use (.h5).

         [-o]: Specify the name of the output csv.

         [-p]: Run brain extraction and linear registrationon provided images.

         [-t]: Specify the threshold value for registraion flagging. Expects an overlap ratio (0.98 default).


Example: docker run -v DBN_DATA:/usr/data deepbrain -o myOutput.csv -m myModel.h5 -p -t 0.99
```

The above command did not specify any docker volume to mount, so the message "Volume not mounted correctly." is provided. This can be solved by 
specifying the `-v` option when running as specified in the help message.

Additionally, the message also specifies the file structure which must be preserved in the docker volume mounted to the deepbrain container.
This is necessary so the container knows where to look for particular files.

#### Optional Parameters

There are 3 optional parameters the user can specify when running the deepbrain container.
1. `-m` Specifies what DeepBrainNet model to use for brain age prediction inside of `<yourvolume>/Models`.
2. `-o` Specifies the file name of the output csv which will be wrote to `<yourvolume/Output>`.
3. `-p` This is a flag which tells the container if pre-processing should be run on the volumes in `<yourvolume>/ImageData`.
4. `-t` This sets the threshold value to flag registrations for QC. Any overlap ratio above this value will be moved into `<yourvolume>/Preprocessing/Flagged` (default 0.98).

#### Preprocessing
In the case that the `-p` flag is specified the deepbrain container will perform the following:
1. Brain extraction using ROBEX is performed on the scans in `<yourvolume>/ImageData` to generate a brain mask.
2. Two modal dialations, an errosion, and a fillh26 is performed with FSL on the generated brain mask to ensure that the whole brain is captured.
3. The brain mask is combined with the original T1 image to obtain the extracted image.
4. A bias field normalization is performed with FSL fast.
5. Linear registration is performed with FSL flirt.

The result of these operations is saved to a preprocessing folder in `<yourvolume>/Preprocessing/Processed` or  
`<yourvolume>/Preprocessing/Flagged` (created if does not exist) depending on if the linear registration passes your specified threshold value (`-t`). 
Finally, all images found in `Flagged` or `Processed` is then passed to DBN. The original unprocessed scans in `<yourvolume>/ImageData` will remain unchanged.

