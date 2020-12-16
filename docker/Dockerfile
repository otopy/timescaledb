ARG PG_VERSION
ARG PREV_TS_VERSION=1.7.4
ARG PREV_EXTRA
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.14.0
FROM golang:${GO_VERSION}-alpine AS tools

ENV TOOLS_VERSION 0.8.1

RUN apk update && apk add --no-cache git \
    && mkdir -p ${GOPATH}/src/github.com/timescale/ \
    && cd ${GOPATH}/src/github.com/timescale/ \
    && git clone https://github.com/timescale/timescaledb-tune.git \
    && git clone https://github.com/timescale/timescaledb-parallel-copy.git \
    # Build timescaledb-tune
    && cd timescaledb-tune/cmd/timescaledb-tune \
    && git fetch && git checkout --quiet $(git describe --abbrev=0) \
    && go get -d -v \
    && go build -o /go/bin/timescaledb-tune \
    # Build timescaledb-parallel-copy
    && cd ${GOPATH}/src/github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy \
    && git fetch && git checkout --quiet $(git describe --abbrev=0) \
    && go get -d -v \
    && go build -o /go/bin/timescaledb-parallel-copy

############################
# Grab old versions from previous version
############################
ARG PG_VERSION
FROM timescale/timescaledb:${PREV_TS_VERSION}-pg${PG_VERSION}${PREV_EXTRA} AS oldversions
# Remove update files, mock files, and all but the last 5 .so/.sql files
RUN rm -f $(pg_config --sharedir)/extension/timescaledb--*--*.sql \
    && rm -f $(pg_config --sharedir)/extension/timescaledb*mock*.sql \
    && rm -f $(ls -1 $(pg_config --pkglibdir)/timescaledb-tsl-1*.so | head -n -5) \
    && rm -f $(ls -1 $(pg_config --pkglibdir)/timescaledb-1*.so | head -n -5) \
    && rm -f $(ls -1 $(pg_config --sharedir)/extension/timescaledb--1*.sql | head -n -5)

############################
# Now build image and copy in tools
############################
ARG PG_VERSION
FROM postgres:${PG_VERSION}
ARG OSS_ONLY

LABEL maintainer="Timescale https://www.timescale.com"

# Update list above to include previous versions when changing this
ENV TIMESCALEDB_VERSION 1.7.4

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/ 
COPY --from=oldversions /usr/local/lib/postgresql/timescaledb-*.so /usr/local/lib/postgresql/
COPY --from=oldversions /usr/local/share/postgresql/extension/timescaledb--*.sql /usr/local/share/postgresql/extension/

RUN set -ex \
    && apt update && apt install -y ca-certificates \
                git \
                openssl \
                tar \
                coreutils \
                dpkg-dev dpkg \
                gcc \
                libc-dev \
                make \
                cmake \
                libpq-dev \
                libssl-dev \
                libkrb5-dev \
                postgresql-server-dev-12 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /build/ \
    && git clone https://github.com/timescale/timescaledb /build/timescaledb \

#RUN apt install -y libssl-dev postgresql-server-dev-12 libkrb5-dev  && rm -rf /var/lib/apt/lists/*
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TIMESCALEDB_VERSION} \
    && ./bootstrap -DREGRESS_CHECKS=OFF -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY} \
    && cd build && make install \
    && cd ~ \
#COPY postgresql.conf.sample /var/lib/postgresql/data/postgresql.conf.sample
    && if [ "${OSS_ONLY}" != "" ]; then rm -f $(pg_config --pkglibdir)/timescaledb-tsl-*.so; fi \
    && rm -rf /build \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/share/postgresql/12/postgresql.conf.sample \
    && rm -rf /var/cache/apt \
#    && apt remove -y make cmake postgresql-server-dev-12 \
#    && apt remove -y make postgresql-server-dev-12 \
#    && apt remove -y gcc libc-dev libssl-dev \
#    && apt autoremove -y
#ls /usr/share/postgresql/12/

#/var/lib/postgresql/data/
#/var/lib/postgresql/
    #postgresql.conf  postgresql-server-dev-12
    #&& echo "shared_preload_libraries = 'timescaledb'" >> /var/lib/postgresql/data/postgresql.conf
    #&& sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /var/lib/postgresql/data/postgresql.conf
    
    #/usr/local/share/postgresql/postgresql.conf.sample
