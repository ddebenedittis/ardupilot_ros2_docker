# Change ROS version in build.sh, not here!
ARG BASE_IMAGE=osrf/ros
ARG BASE_TAG=humble-desktop

FROM ${BASE_IMAGE}:${BASE_TAG}

# ================================== Nvidia ================================== #

# Use the NVIDIA graphics card.
ENV NVARCH x86_64

ENV NVIDIA_REQUIRE_CUDA "cuda>=12.1 brand=tesla,driver>=450,driver<451 brand=tesla,driver>=470,driver<471 brand=unknown,driver>=470,driver<471 brand=nvidia,driver>=470,driver<471 brand=nvidiartx,driver>=470,driver<471 brand=geforce,driver>=470,driver<471 brand=geforcertx,driver>=470,driver<471 brand=quadro,driver>=470,driver<471 brand=quadrortx,driver>=470,driver<471 brand=titan,driver>=470,driver<471 brand=titanrtx,driver>=470,driver<471 brand=tesla,driver>=510,driver<511 brand=unknown,driver>=510,driver<511 brand=nvidia,driver>=510,driver<511 brand=nvidiartx,driver>=510,driver<511 brand=geforce,driver>=510,driver<511 brand=geforcertx,driver>=510,driver<511 brand=quadro,driver>=510,driver<511 brand=quadrortx,driver>=510,driver<511 brand=titan,driver>=510,driver<511 brand=titanrtx,driver>=510,driver<511 brand=tesla,driver>=515,driver<516 brand=unknown,driver>=515,driver<516 brand=nvidia,driver>=515,driver<516 brand=nvidiartx,driver>=515,driver<516 brand=geforce,driver>=515,driver<516 brand=geforcertx,driver>=515,driver<516 brand=quadro,driver>=515,driver<516 brand=quadrortx,driver>=515,driver<516 brand=titan,driver>=515,driver<516 brand=titanrtx,driver>=515,driver<516 brand=tesla,driver>=525,driver<526 brand=unknown,driver>=525,driver<526 brand=nvidia,driver>=525,driver<526 brand=nvidiartx,driver>=525,driver<526 brand=geforce,driver>=525,driver<526 brand=geforcertx,driver>=525,driver<526 brand=quadro,driver>=525,driver<526 brand=quadrortx,driver>=525,driver<526 brand=titan,driver>=525,driver<526 brand=titanrtx,driver>=525,driver<526"
ENV NV_CUDA_CUDART_VERSION 12.1.105-1
ENV NV_CUDA_COMPAT_PACKAGE cuda-compat-12-1

LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/${NVARCH}/3bf863cc.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/${NVARCH} /" > /etc/apt/sources.list.d/cuda.list && \
    apt-get purge --autoremove -y curl \
    && rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 12.1.1

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-12-1=${NV_CUDA_CUDART_VERSION} \
    ${NV_CUDA_COMPAT_PACKAGE} \
    && rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf \
    && echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,graphics,utility

# ==================================== ROS =================================== #

# Prevent bash to ask for user input which may break the building process
ENV DEBIAN_FRONTEND=noninteractive

# Install sudo, and some essential packages.
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt --mount=type=cache,sharing=locked,target=/var/lib/apt \
    apt-get update && apt-get install --no-install-recommends -qqy \
    bash-completion \
    build-essential \
    git \
    gnupg \
    lsb-release \
    python3-dev python3-opencv python3-wxgtk4.0 python3-pip python3-matplotlib python3-lxml python3-pygame \
    sudo \
    tzdata \
    wget

# Install Gazebo Garden
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt --mount=type=cache,sharing=locked,target=/var/lib/apt \
    wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null \
 && apt-get update && apt-get install --no-install-recommends -qqy \
    gz-garden \
    libgz-sim7-dev \
    rapidjson-dev \
    ros-${ROS_DISTRO}-ros-gz

RUN pip3 install PyYAML mavproxy --user

# =================================== User =================================== #

# Create the same user as the host itself. (By default Docker creates the container as root, which is not recommended.)
ARG UID=1000
ARG GID=1000
ARG USER=ros
ARG PWDR=/
RUN addgroup --gid ${GID} ${USER} \
 && adduser --gecos "ROS User" --disabled-password --uid ${UID} --gid ${GID} ${USER} \
 && usermod -a -G dialout ${USER} \
 && echo ${USER}" ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/99_aptget \
 && chmod 0440 /etc/sudoers.d/99_aptget && chown root:root /etc/sudoers.d/99_aptget

# Choose to run as user
ENV USER ${USER}
USER ${USER}

# ============================= Finish Ardupilot ============================= #

ARG SKIP_AP_EXT_ENV=1
ARG SKIP_AP_GRAPHIC_ENV=1
ARG SKIP_AP_COV_ENV=1
ARG SKIP_AP_GIT_CHECK=1

COPY ardupilot/Tools/environment_install/install-prereqs-ubuntu.sh /ardupilot/Tools/environment_install/
COPY ardupilot/Tools/completion /ardupilot/Tools/completion/

ENV SKIP_AP_EXT_ENV=$SKIP_AP_EXT_ENV SKIP_AP_GRAPHIC_ENV=$SKIP_AP_GRAPHIC_ENV SKIP_AP_COV_ENV=$SKIP_AP_COV_ENV SKIP_AP_GIT_CHECK=$SKIP_AP_GIT_CHECK
RUN ardupilot/Tools/environment_install/install-prereqs-ubuntu.sh -y

# # add waf alias to ardupilot waf to .ardupilot_env
RUN echo "alias waf=\"/${USER_NAME}/waf\"" >> ~/.ardupilot_env

# Check that local/bin are in PATH for pip --user installed package
RUN echo "if [ -d \"\$HOME/.local/bin\" ] ; then\nPATH=\"\$HOME/.local/bin:\$PATH\"\nfi" >> ~/.ardupilot_env

# Change HOME environment variable
ENV HOME /home/${USER}

# Set the buildlogs directory into /tmp as other directory aren't accessible
ENV BUILDLOGS=/tmp/buildlogs

ENV CCACHE_MAXSIZE=1G

# ================================ Final Steps =============================== #

# Set up environment
COPY config/update_bashrc /sbin/update_bashrc

RUN sudo chmod +x /sbin/update_bashrc ; sudo chown ${USER} /sbin/update_bashrc \
    && echo 'echo "source '${PWDR}'/install/setup.bash" >> ~/.bashrc' >> /sbin/update_bashrc \
    && echo 'echo "export GZ_SIM_SYSTEM_PLUGIN_PATH='${PWDR}'/src/ardupilot_gazebo/build:${GZ_SIM_SYSTEM_PLUGIN_PATH}" >> ~/.bashrc' >> /sbin/update_bashrc \
    && echo 'echo "export GZ_SIM_RESOURCE_PATH='${PWDR}'/src/ardupilot_gazebo/models:'${PWDR}'/src/ardupilot_gazebo/worlds:${GZ_SIM_RESOURCE_PATH}" >> ~/.bashrc' >> /sbin/update_bashrc \
    && echo 'export PATH="$PATH:$HOME/.local/bin"" >> ~/.bashrc' >> /sbin/update_bashrc \
    && cat /sbin/update_bashrc \
    && sync ; /bin/bash -c /sbin/update_bashrc ; sudo rm /sbin/update_bashrc

# Change entrypoint to source ~/.bashrc and start in ~
COPY config/entrypoint.sh /ros_entrypoint.sh
RUN sudo chmod +x /ros_entrypoint.sh ; sudo chown ${USER} /ros_entrypoint.sh \
 && echo "cd "${PWDR} >> /ros_entrypoint.sh \
 && echo 'exec bash -i -c $@' >> /ros_entrypoint.sh \
 && cat /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]