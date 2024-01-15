#!/bin/bash

BASE_IMAGE=osrf/ros
BASE_TAG=humble-desktop
IMAGE_NAME=ardupilot_ros_gazebo

# =============================== Preliminaries ============================== #

mkdir -p build log install
mkdir -p ./cache/.gz
mkdir -p ~/.vscode ~/.vscode-server ~/.config/Code

touch ardupilot/COLCON_IGNORE

rm ardupilot/Tools/environment_install/install-prereqs-ubuntu.sh
cp ./config/install-prereqs-ubuntu.sh ardupilot/Tools/environment_install/install-prereqs-ubuntu.sh

# =============================== Help Function ============================== #

helpFunction()
{
    echo ""
    echo "Usage: $0 [-r]"
    echo -e "\t-h   --help          Print the help."
    echo -e "\t-r   --rebuild   Rebuild the image."
    exit 1 # Exit script after printing help
}

# =============================== Build Options ============================== #

# Initialie the build options
REBUILD=0

# Auxiliary functions
die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }
no_arg() { if [ -n "$OPTARG" ]; then die "No arg allowed for --$OPT option"; fi; }

# Get the script options. This accepts both single dash (e.g. -a) and double dash options (e.g. --all)
while getopts hr-: OPT; do
    # support long options: https://stackoverflow.com/a/28466267/519360
    if [ "$OPT" = "-" ]; then     # long option: reformulate OPT and OPTARG
        OPT="${OPTARG%%=*}"       # extract long option name
        OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
        OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
    fi
    case "$OPT" in
        h | help )      no_arg; helpFunction ;;
        r | rebuild )   no_arg; REBUILD=1 ;;
        ??* )           die "Illegal option --$OPT" ;;  # bad long option
        ? )             exit 2 ;;  # bad short option (error reported via getopts)
    esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

# ========================= Pull And Build The Image ========================= #

docker pull $BASE_IMAGE:$BASE_TAG

MYUID="$(id -u $USER)"
MYGID="$(id -g $USER)"

if [ "$REBUILD" -eq 1 ]; then
    cache="--no-cache"
else
    cache=""
fi

docker build \
    ${cache} \
    --build-arg BASE_IMAGE=$BASE_IMAGE \
    --build-arg BASE_TAG=$BASE_TAG \
    --build-arg MYUID=${UID} \
    --build-arg MYGID=${GID} \
    --build-arg USER=${USER} \
    --build-arg "PWDR=$PWD" \
    -t $IMAGE_NAME .
