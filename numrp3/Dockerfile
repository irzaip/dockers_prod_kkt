FROM alpine:latest

MAINTAINER Bayu Irian <bayu.irian@gmail.com>
## Nginx Uwsgi Mysql Runit Php/Postgre/Python = NUMRP3

RUN echo "Installing package" && \
    echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
    dumb-init runit su-exec "gosu@testing" sudo \ 
    curl bash grep gawk bc psmisc awall \
    openssl ca-certificates \
    openssh \
    libpq postgresql postgresql-contrib postgresql-plpython3 postgresql-plpython3-contrib \
    mysql \
    postgresql-client mysql-client \
    nginx acme-client libressl \
    uwsgi uwsgi-python3 uwsgi-logfile \
    memcached \
    python3 py3-virtualenv py3-psycopg2 "py3-pymysql@testing" \
    py3-sqlalchemy py3-jinja2 py3-lxml py3-curl py3-requests py3-bcrypt py3-six py3-cffi py3-dnspython py3-netifaces py3-flask \
    php7-cli php7-fpm php7-mysqli php7-pgsql php7-xml php7-curl php7-gd php7-intl php7-json php7-mbstring php7-mcrypt && \
    adduser -s /bin/bash -D alpine && \
    echo "alpine ALL=(ALL) ALL" >> /etc/sudoers && \
    rm -rf /var/cache/apk/*

#RUN apk add --no-cache --virtual \
#    .build-deps \
#    py3-pip python3-dev build-base pcre-dev openssl-dev linux-headers && \
#    pip3 install --no-cache-dir PyMySQL && \
#    apk del .build-deps && \
#    rm -rf /var/cache/apk/*

ENV LANG en_US.utf8
ENV PGDATA /var/lib/postgresql/data
ENV POSTGRES_PASSWORD "tiger"
ENV ALPINE_PASSWORD "alpine"
ENV PGPORT 5432

EXPOSE 22 3306 5432 80 443

COPY runit/ /opt/numrp3/runit/
COPY build/ /opt/numrp3/build/

RUN echo "root:$POSTGRES_PASSWORD" | chpasswd && \
    echo "alpine:$ALPINE_PASSWORD" | chpasswd && \
    /bin/bash /opt/numrp3/build/service_setup.sh && \
    rm -rf /opt/numrp3

VOLUME /var/lib/postgresql/data
VOLUME /var/lib/mysql
VOLUME /var/lib/nginx/html

# HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/sbin/runsvdir", "-P", "/etc/service"]
