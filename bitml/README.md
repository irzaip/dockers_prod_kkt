# Docker Alpine Miniconda

Dockerfile with:
- Alpine:latest image
- Miniconda 4.5.11
- Jupyter
- UWSGI

service managed by supervisord

A special user is create with uid 1000 and can be use with any public user without security breach.

# Changelog
## 1.0 
- Updated Miniconda version to 4.5.11
- Set conda-forge as top prio channel

# Usage

You can download and run this image with these commands:

```
docker-compose build
docker-compose up -d
```

All done.
