# Docker tensorflow-gpu Miniconda

Dockerfile with:
- Ubuntu 18.04
- NVIDIA Cuda 9.2
- Miniconda 4.5.11
- Tensorflow 1.11
- Jupyter
- UWSGI

service managed by supervisord

A special user is create with uid 1000 and can be use with any public user without security breach.

# Changelog
## 4.5.11 
- Updated Miniconda version to 4.5.11
- Set conda-forge as top prio channel

# Usage

You can download and run this image with these commands:

```
docker-compose build
docker-compose up -d
```

This image is a modified version of [nvidia/cuda](https://gitlab.com/nvidia/cuda/blob/ubuntu18.04/9.2/base/Dockerfile) image modified to suite the needs.
