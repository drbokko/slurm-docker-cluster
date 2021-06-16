FROM ubuntu:focal-20210416

LABEL org.opencontainers.image.source="https://github.com/drbokko/slurm-docker-cluster" \
      org.opencontainers.image.title="slurm-docker-cluster" \
      org.opencontainers.image.description="Slurm Docker cluster on Ubuntu 20.04LTS based on work from Giovanni Torres" \
      org.label-schema.docker.cmd="docker-compose up -d" \
      maintainer="Vittorio Bocconew"

ARG SLURM_TAG=slurm-20-11-7-1
ARG GOSU_VERSION=1.13

RUN groupadd -r --gid=996 munge \
    && useradd -r -g munge --uid=996 -s /sbin/nologin munge

RUN apt-get update && apt-get install -y \
       wget \
       bzip2 \
       perl \
       git \
       gnupg \
       make \
       python3 \
       munge \
       libmunge-dev \
       gcc

RUN set -x \
    && git clone https://github.com/SchedMD/slurm.git /tmp/slurm

#RUN set -ex \
#    && yum makecache fast \
#    && yum -y update \
#    && yum -y install epel-release \
#    && yum -y install \
#       wget \
#       bzip2 \
#       perl \
#       gcc \
#       gcc-c++\
#       git \
#       gnupg \
#       make \
#       munge \
#       munge-devel \
#       python-devel \
#       python-pip \
#       python34 \
#       python34-devel \
#       python34-pip \
#       mariadb-server \
#       mariadb-devel \
#       psmisc \
#       bash-completion \
#       vim-enhanced \
#    && yum clean all \
#    && rm -rf /var/cache/yum
#
#RUN pip install Cython nose && pip3.4 install Cython nose
#

RUN set -x \
#     && git clone https://github.com/SchedMD/slurm.git /tmp/slurm \
    && cd /tmp/slurm \
    && git checkout tags/$SLURM_TAG \
    && ./configure --enable-debug --prefix=/usr --sysconfdir=/etc/slurm \
        --with-mysql_config=/usr/bin  --libdir=/usr/lib64 \
    && make install -j 16

RUN set -x \
    && cd /tmp/slurm \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && cd \
    && rm -rf /tmp/slurm \
    && groupadd -r --gid=995 slurm \
    && useradd -r -g slurm --uid=995 slurm

RUN set -x \
    && mkdir /etc/default/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/run/munge \
        /var/run/slurmdbd \
        /var/lib/slurmd \
        /var/log/slurm \
        /data \
    && touch /var/lib/slurmd/node_state \
        /var/lib/slurmd/front_end_state \
        /var/lib/slurmd/job_state \
        /var/lib/slurmd/resv_state \
        /var/lib/slurmd/trigger_state \
        /var/lib/slurmd/assoc_mgr_state \
        /var/lib/slurmd/assoc_usage \
        /var/lib/slurmd/qos_usage \
        /var/lib/slurmd/fed_mgr_state \
    && chown -R slurm:slurm /var/*/slurm* \
    && chown -R munge:munge /var/*/munge* \
    && chown -R munge:munge /run/munge* \
    && /sbin/create-munge-key
RUN apt install -y mariadb-server
COPY slurm.conf /etc/slurm/slurm.conf
COPY slurmdbd.conf /etc/slurm/slurmdbd.conf

RUN set -ex \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
#    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
#    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
#

#
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
#
CMD ["slurmdbd"]
