# Docker ROS NVIDIA

## Overview

Dockerfiles to build images that have ROS (1 or 2) with NVIDIA support and with GUI support (e.g. Gazebo and RViz).

The `build.bash` and the `run.bash` files are used to automatically build and run the image.


## Preliminaries

Install [Docker Community Edition](https://docs.docker.com/engine/install/ubuntu/) (ex Docker Engine) with post-installation steps for Linux.

Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#setting-up-nvidia-container-toolkit) (nvidia-docker2).

Clone ArduPilot and ArduPilot-Gazebo with
```shell
git clone --recursive https://github.com/ArduPilot/ardupilot.git
git clone --recursive https://github.com/ArduPilot/ardupilot_gazebo.git src/ardupilot_gazebo
```


## Usage

Build the docker image (use the `-r` option to update the underlying images):
```shell
./build.bash [-r]
```

Run the container:
```shell
./run.bash
```

The workspace directory should be the folder containing `run.bash` and `build.bash`. It is mounted in the Docker container on startup.

Build the workspace inside the Docker container with colcon to avoid permission problems. The workspace's `setup.bash` is automatically sourced when the container is opened; thus it will fail the first time the container is run.

To use VSCode with Docker, you can use the Dev Containers extension to attach VSCode to a running container. For having autocomplete, linting, etc. take a look at https://github.com/athackst/vscode_ros2_workspace and in particular to `c_cpp_properties.json` and `settings.json` in `.vscode`.
