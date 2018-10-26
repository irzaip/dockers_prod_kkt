
ALL?=

.PHONY: build  # -- Build docker image from Dockerfile
build: 
	@exec docker build --label numrp3 -t numrp3:dev .

.PHONY: run  # -- Run docker image
run:
	@exec docker run --rm -d --name numrp3 -h numrp3.local -p 2222:22 -p 80:80 -p 443:443 -p 3306:3306 -p 5432:5432 -t numrp3:dev

.PHONY: runmount  # -- Run docker image
runmount:
	@exec docker run --rm -d --name numrp3 -h numrp3.local \
	-p 2222:22 -p 80:80 -p 443:443 -p 3306:3306 -p 5432:5432 \
	--mount type=bind,source=/Users/bayu/appdata/docker/pg,target=/var/lib/postgresql/data \
	--mount type=bind,source=/Users/bayu/appdata/docker/w3,target=/var/www \
	--mount type=bind,source=/Users/bayu/appdata/docker/cf,target=/etc/appcf \
	-t numrp3:dev

.PHONY: bash  # -- Get into container bash terminal
bash:
	@exec docker exec -it numrp3 bash

.PHONY: inspect  # -- Inspec container
inspect: 
	@exec docker inspect numrp3

.PHONY: ssh  # -- Login into docker container using ssh
ssh:
	@exec ssh -p 2222 root@localhost

.PHONY: stop  # -- Stop docker running image and remove container
stop:
	@exec docker stop numrp3
	@exec docker container rm numrp3

.PHONY: clean  # -- Run docker system prune (add ALL=-a to prune all)
clean: 
	@exec docker system prune -f $(ALL)

.PHONY: remove  # -- Remove this container
remove:
	@exec docker rmi --force $(shell docker images -q numrp3 | uniq)

.PHONY: port  # -- check docker container expose port
port:
	@exec docker port numrp3

.PHONY: mysql  # -- Connect to mysql server run in container
mysql:
	@exec mysql -h localhost -P 3306 --protocol=tcp -u root -p

.PHONY: psql  # -- Connect to postgresql server run in container
psql:
	@exec psql -h localhost -p 5432 -U postgres

touch: SHELL:=/bin/bash
touch:
	touch --no-dereference "$@"

.PHONY: list
list:
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1 \2/' | expand -t20
