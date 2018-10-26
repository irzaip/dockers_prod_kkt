FROM alpine:latest
MAINTAINER Bayu Iriantomo <bayu.irian@gmail.com>

# Install glibc and useful packages
RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk --update add --no-cache bash curl shadow git ca-certificates \
    # tini@testing \
    && apk add --no-cache --virtual .build-deps \
    libstdc++ glib \
    && curl "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk" -o glibc.apk \
    && curl -L "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-bin-2.23-r3.apk" -o glibc-bin.apk \
    && curl -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.25-r0/glibc-i18n-2.25-r0.apk" -o glibc-i18n.apk \
    && apk add --allow-untrusted glibc.apk glibc-bin.apk glibc-i18n.apk \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc/usr/lib \
    && apk del .build-deps \
    && rm -rf glibc*apk /var/cache/apk/*

# Configure environment
ENV CONDA_DIR /opt/conda
ENV SHELL /bin/bash
ENV CONTAINER_USER alpine
ENV CONTAINER_UID 1000
ENV CONTAINER_GID 100
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ENV PATH=$CONDA_DIR/bin:$PATH
ENV HOME=/home/$CONTAINER_USER

# Create user with UID=1000 and in the 'users' group
RUN echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su \
    && [ -d /var/mail ] || mkdir /var/mail \
    && useradd -m -s /bin/bash -g $CONTAINER_GID -u $CONTAINER_UID $CONTAINER_USER \
    && mkdir -p $CONDA_DIR \
    && chown $CONTAINER_USER:$CONTAINER_GID $CONDA_DIR \
    && chmod g+w /etc/passwd \
    && groupadd supervisor \
    && usermod -a -G supervisor $CONTAINER_USER \
    && mkdir -p /etc/supervisor.d \
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
    && curl -L $MINICONDA_URL  -o miniconda.sh \
    && echo "$MINICONDA_MD5_SUM  miniconda.sh" | md5sum -c - \
    && /bin/bash miniconda.sh -f -b -p $CONDA_DIR \
    && rm miniconda.sh \
    && $CONDA_DIR/bin/conda install --yes conda==$MINICONDA_VER \
    && $CONDA_DIR/bin/conda update --all --quiet --yes \
    && $CONDA_DIR/bin/conda clean --all -y

RUN $CONDA_DIR/bin/conda upgrade -y pip \
    && $CONDA_DIR/bin/conda config --add channels conda-forge \
    && $CONDA_DIR/bin/conda install -y jupyter uwsgi \
    && $CONDA_DIR/bin/conda clean --all -y \
    && $CONDA_DIR/bin/conda create -p  $CONDA_DIR/envs/appenv \
    && cd /tmp \
    && git clone https://github.com/Supervisor/supervisor.git \
    && cd supervisor \
    && $CONDA_DIR/bin/python setup.py build \
    && $CONDA_DIR/bin/python setup.py install \
    && cd .. \
    && rm -rf supervisor

USER root

# Configure Jupyter Notebook
ENV PASSWORD "condatiger"
ENV GEN_CERT 1

EXPOSE 8888 9001 5000-5010
WORKDIR $HOME

# Configure container startup as root
# ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/opt/conda/bin/supervisord", "-c", "/etc/supervisord.conf"]

COPY supervisord.conf /etc/supervisord.conf
COPY uwsgi.ini /etc/uwsgi/uwsgi.ini
COPY jupyter_notebook_config.py /etc/jupyter/

# Switch back to ubuntu to avoid accidental container runs as root
#USER $CONTAINER_USER
