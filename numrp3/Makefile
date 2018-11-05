
ALL?=
PS=$(shell docker ps -a | grep numrp3)
LS=$(shell docker container ls | grep numrp3)

all : stop build

.PHONY: build # -- Build docker image from Dockerfile
build: 
	@exec docker build --label numrp3 -t numrp3:dev .

.PHONY: run  # -- Run docker image
run:
	@-exec docker run -d --rm --name numrp3 -h numrp3.local -p 2222:22 -p 80:80 -p 443:443 -p 3306:3306 -p 5432:5432 -t numrp3:dev

.PHONY: runmount  # -- Run docker image
runmount:
	@-exec docker run -d --rm --name numrp3 -h numrp3.local \
	-p 2222:22 -p 80:80 -p 443:443 -p 3306:3306 -p 5432:5432 -p 3030-3040:3030-3040 \
	-v $(pwd)/data/ssl/:/etc/ssl/mail/ \
	-v $(pwd)/data/cfg/uwsgi/:/etc/uwsgi/conf.d/ \
	-v $(pwd)/data/cfg/ssh/:/etc/ssh/ \
	-v $(pwd)/data/cfg/nginx/:/etc/nginx/conf.d/ \
	-v $(pwd)/data/cfg/mysql/:/etc/mysql/conf.d/ \
	-v $(pwd)/data/web/pyenvs/:/var/envs/ \
	-v $(pwd)/data/web/apps/:/var/www/html/ \
    -v $(pwd)/data/keys/:/var/keys/ \
	-v pgsql-vol-1:/var/lib/postgresql/data/ \
	-v mysql-vol-1:/var/lib/mysql/ \
	-t numrp3:dev

.PHONY: bash  # -- Get into container bash terminal
bash:
	@-exec docker exec -it numrp3 bash

.PHONY: inspect  # -- Inspec container
inspect: 
	@-exec docker inspect numrp3

.PHONY: ssh  # -- Login into docker container using ssh
ssh:
	@-exec ssh -p 2222 alpine@localhost

.PHONY: sftp  # -- Login into docker container using sftp
sftp:
	@-exec sftp -oPort=2222 alpine@localhost

.PHONY: stop  # -- Stop docker running image and remove container
stop:
ifneq ($(PS),)
	@-exec docker stop numrp3
endif
	@-sleep 0

.PHONY: clean  # -- Run docker system prune (add ALL=-a to prune all)
clean: 
	@( read -p "[system prune -f] Are you sure?!? [y/N]: " sure && case "$$sure" in [yY]) true;; *) false;; esac )
	@-exec docker system prune -f $(ALL)

.PHONY: remove  # -- Remove this image
remove:
	@( read -p "[docker rmi] Are you sure?!? [y/N]: " sure && case "$$sure" in [yY]) true;; *) false;; esac )
	@-exec docker rmi --force $(shell docker images -q numrp3 | uniq)

.PHONY: port  # -- check docker container expose port
port:
	@-exec docker port numrp3

.PHONY: mysql  # -- Connect to mysql server run in container
mysql:
	@-exec mysql -h localhost -P 3306 --protocol=tcp -u root -p

.PHONY: psql  # -- Connect to postgresql server run in container
psql:
	@-exec psql -h localhost -p 5432 -U postgres

touch: SHELL:=/bin/bash
touch:
	@-touch --no-dereference "$@"

.PHONY: list
list:
	@-grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1 \2/' | expand -t20

test:
	@( read -p "Are you sure?!? [y/N]: " sure && case "$$sure" in [yY]) true;; *) false;; esac )
	@-exit 1 ||:
