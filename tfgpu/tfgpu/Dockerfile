# source: https://gitlab.com/nvidia/cuda/blob/ubuntu18.04/9.2/base/Dockerfile
# ---------------------------------------------------------------------------
FROM ubuntu:18.04
LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

# CUDA 9.2 is not officially supported on ubuntu 18.04 yet, we use the ubuntu 17.10 repository for CUDA instead.
RUN apt-get update && apt-get install -y --no-install-recommends gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1710/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1710/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
    rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 9.2.148

ENV CUDA_PKG_VERSION 9-2=$CUDA_VERSION-1
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-$CUDA_PKG_VERSION && \
    ln -s cuda-9.2 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# nvidia-docker 1.0
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=9.2"
# ---------------------------------------------------------------------------

LABEL maintainer "bayu ir  <bayu.irian@gmail.com>"

RUN apt-get update && apt-get install -y --no-install-recommends bzip2 curl git sudo locales jq moreutils \
    && rm -rf /var/lib/apt/lists/*

# Configure environment
ENV CONDA_DIR /opt/conda
ENV SHELL /bin/bash
ENV CONTAINER_USER ubuntu
ENV CONTAINER_UID 1000
ENV CONTAINER_GID 100
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8

ENV PATH=$CONDA_DIR/bin:$PATH
ENV HOME=/home/$CONTAINER_USER

# Create user with UID=1000 and in the 'users' group
RUN groupadd wheel -g 11 \
    && echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su \
    && groupadd supervisor \
    && useradd -m -s /bin/bash -g $CONTAINER_GID -u $CONTAINER_UID $CONTAINER_USER \
    && usermod -a -G sudo $CONTAINER_USER \
    && usermod -a -G supervisor $CONTAINER_USER \
    && echo "$CONTAINER_USER ALL=NOPASSWD: ALL" >> /etc/sudoers \
    && mkdir -p $CONDA_DIR \
    && chown $CONTAINER_USER:$CONTAINER_GID $CONDA_DIR \
    && chmod g+w /etc/passwd \
    && mkdir -p /etc/uwsgi/vassals /var/log/uwsgi /var/log/jupyter /var/log/supervisord \
    && chown -R root:supervisor /etc/uwsgi /var/log/uwsgi /var/log/jupyter /var/log/supervisord \
    && chmod 775 /var/log/uwsgi /var/log/jupyter /var/log/supervisord /var/run

# Configure Miniconda
ENV MINICONDA_VER 4.5.11
ENV MINICONDA Miniconda3-$MINICONDA_VER-Linux-x86_64.sh
ENV MINICONDA_URL https://repo.continuum.io/miniconda/$MINICONDA
ENV MINICONDA_MD5_SUM e1045ee415162f944b6aebfe560b8fee

USER $CONTAINER_USER

# Install conda
RUN cd /tmp \
    && mkdir -p $HOME/webapp \
    && mkdir -p $CONDA_DIR \
    && curl -L $MINICONDA_URL -o miniconda.sh \
    && echo "$MINICONDA_MD5_SUM  miniconda.sh" | md5sum -c - \
    && /bin/bash miniconda.sh -f -b -p $CONDA_DIR \
    && rm miniconda.sh \
    && $CONDA_DIR/bin/conda config --add channels conda-forge \
    && $CONDA_DIR/bin/conda install --yes \
    conda==$MINICONDA_VER \
    python==3.6.6 \
    jupyter uwsgi \
    && $CONDA_DIR/bin/conda update --all --quiet --yes \
    && $CONDA_DIR/bin/conda clean --all -y \
    && rm -rf /home/$CONTAINER_USER/.cache/yarn \
    && $CONDA_DIR/bin/conda create -p $CONDA_DIR/envs/appenv \
    && sudo ln -s $CONDA_DIR/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && sudo mkdir -p /run/uwsgi \
    && sudo chown -R ${CONTAINER_USER}:users /run/uwsgi \
    && sudo chown -R ${CONTAINER_USER}:users $CONDA_DIR/envs/appenv \
    && cp -R $CONDA_DIR/share/jupyter/kernels/python3 $CONDA_DIR/share/jupyter/kernels/appenv \
    && jq '.argv[0]="/opt/conda/envs/appenv/bin/python" | .display_name="Python 3 (appenv)"' $CONDA_DIR/share/jupyter/kernels/appenv/kernel.json | sponge $CONDA_DIR/share/jupyter/kernels/appenv/kernel.json \
    && rm -rf /home/$CONTAINER_USER/.cache \
    && echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> $HOME/.bashrc \
    && yes | $CONDA_DIR/bin/pip install --no-cache-dir --upgrade pip \
    && yes | $CONDA_DIR/bin/pip install --no-cache-dir pillow \
    && cd $HOME \
    && git clone https://github.com/Supervisor/supervisor.git \
    && cd supervisor \
    && $CONDA_DIR/bin/python setup.py build \
    && sudo $CONDA_DIR/bin/python setup.py install \
    && cd $HOME \
    && sudo rm -rf supervisor \
    # && mkdir -p $HOME/.local \
    # && bash -c "source $HOME/.bashrc && source activate $CONDA_DIR/envs/appenv \
    # && python -m ipykernel install --user --name appenv --display-name 'Python (appenv)'" \
    && echo

ENV SV_PASSWORD "tiger"
ENV GEN_CERT 1

EXPOSE 9001 8888 5001-5009
WORKDIR $HOME

USER root

#ENTRYPOINT ["sudo", "-E"]
CMD ["/opt/conda/bin/supervisord", "-c", "/etc/supervisord.conf"]

COPY supervisord.conf /etc/supervisord.conf
COPY uwsgi.ini /etc/uwsgi/uwsgi.ini
COPY jupyter_notebook_config.py /etc/jupyter/
COPY gpu_test.py $HOME
