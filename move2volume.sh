#! /bin/bash

host_dir=''

print_usage() {
  printf "\n\nUsage:\n\n"
  printf "\tParameters:\n\n"
  printf "\t %s\n\n" "[-d]: Specify the source data directory and move to volume." "[-y]: Copy the volume output data to host machine at this directory." "[-c]: Clean the volume directory." "[-p]: List the directory information of the volume." "[-h]: Print this menu." 
  exit 1
}

clean_volume() {
     
    docker volume rm DBN_DATA 
}

print_volume() {
    docker run --rm -i -v=DBN_DATA:/volume busybox find /volume
}

copy_to_volume () {
    docker container create --name move -v DBN_DATA:/root hello-world ;
    docker cp $host_dir move:/root ;
    docker rm move ;
}


copy_to_host () {
    docker container create --name move -v DBN_DATA:/root hello-world ;
    docker cp move:/root/Output/ $host_dir ;
    docker rm move ;
}


while getopts 'puhcd:y:' flag; do
  case "${flag}" in
    d) echo $OPTARG ;
       host_dir=$OPTARG ; 
       copy_to_volume ;;
    y) host_dir=$OPTARG ;
       copy_to_host ;;
    c) clean_volume ;;
    p) print_volume ;;
    u) print_usage ;;
    h) print_usage ;;
    *) print_usage ;
       exit 1 ;;
  esac
done

