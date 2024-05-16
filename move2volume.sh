#! /bin/bash

host_dir=''
volume_name="DBN_DATA"

print_usage() {
  printf "\n\nUsage:\n\n"
  printf "\tParameters:\n\n"
  printf "\t %s\n\n" "[-d]: Specify the source data directory and move to volume." "[-y]: Copy the volume output data to host machine at this directory." "[-c]: Clean the volume directory." "[-p]: List the directory information of the volume." "[-v]: Specify the name of the volume you want to write to or read from (DBN_DATA is default). THIS MUST PRECEED ANY OTHER OPTIONS." "[-h]: Print this menu." 
  exit 1
}

clean_volume() {
     
    docker volume rm ${volume_name} 
}

print_volume() {
    echo ${volume_name}
    docker run --rm -i -v ${volume_name}:/volume busybox find /volume
}

copy_to_volume () {
    docker container create --name move -v ${volume_name}:/root hello-world 
    docker cp $host_dir move:/root 
    docker rm move 
}


copy_to_host () {
    docker container create --name move -v ${volume_name}:/root hello-world 
    docker cp move:/root/ $host_dir 
    docker rm move 
}


while getopts 'puhcd:y:v:' flag; do
  case "${flag}" in
    d) echo $OPTARG 
       host_dir=$OPTARG 
       copy_to_volume ;;
    y) host_dir=$OPTARG 
       copy_to_host ;;
    v) volume_name=$OPTARG ;;
    c) clean_volume ;;
    p) print_volume ;;
    u) print_usage ;;
    h) print_usage ;;
    *) print_usage ;
       exit 1 ;;
  esac
done

