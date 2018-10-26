# NUMRP3
## Nginx Uwsgi Mysql Runit Python-Php-Postgre

System:
- Alpine:lates
- Nginx
- Uwsgi
- MySql
- Memcached
- Runit
- Python3
- Php
- PostgreSql

Using dumb-init and runit as service manager

# Changelog
## 1.0 
- First release

# Usage

You can download and run this image with these commands:

```
make
make run
make runmount (with mount, please edit Makefile)
make bash
make ssh (password: alpine)
make mysql (password: mysql)
make psql (password: tiger)
make port
make inspect
make stop
make remove
make clean
make list
```

all done.
