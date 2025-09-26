FROM debian:bookworm-slim AS berkeleydb

# Install build essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    autoconf \
    automake \
    libtool \
    pkg-config \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

# Download and extract BerkeleyDB
RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz \
    && tar -xzf ${BERKELEYDB_VERSION}.tar.gz \
    && sed -i 's/__atomic_compare_exchange/__atomic_compare_exchange_db/g' ${BERKELEYDB_VERSION}/dbinc/atomic.h \
    && mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix
RUN CFLAGS=-Wno-error=implicit-function-declaration \
    ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX} \
    && make -j$(nproc) \
    && make install \
    && rm -rf ${BERKELEYDB_PREFIX}/docs

FROM debian:bookworm-slim AS bitbar

COPY --from=berkeleydb /opt /opt
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    automake \
    git \
    libboost-all-dev \
    libevent-dev \
    libzmq3-dev \
    libssl-dev \
    libgmp-dev \
    pkg-config \
    file \
    chrpath \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG BITBAR_VERSION="master"
ENV BITBAR_VERSION=${BITBAR_VERSION}
ENV BITBAR_PREFIX=/opt/bitbar-${BITBAR_VERSION}

RUN git clone --depth 1 --branch ${BITBAR_VERSION} https://github.com/crypto-currency/bitbar /bitbar-${BITBAR_VERSION}

WORKDIR /bitbar-${BITBAR_VERSION}/src
RUN make -f makefile.unix BDB_INCLUDE_PATH='/opt/db-4.8.30.NC/include/' BDB_LIB_PATH=/opt/db-4.8.30.NC/lib USE_UPNP=- RELEASE=1 -j 4\
    && mkdir -p ${BITBAR_PREFIX}/bin \
    && cp ./bitbard ${BITBAR_PREFIX}/bin/bitbard \
    && strip ${BITBAR_PREFIX}/bin/bitbard

# Build stage for compiled artifacts
FROM debian:bookworm-slim

LABEL maintainer.0="Ahmed Bodiwala (ahmedbodi@crypto-expert.com)"

RUN useradd -m -s /bin/bash bitbar
RUN apt-get update && apt-get install -y --no-install-recommends \
    libboost-filesystem1.74.0 \
    libboost-system1.74.0 \
    libboost-thread1.74.0 \
    libboost-chrono1.74.0 \
    libboost-program-options1.74.0 \
    libevent-2.1-7 \
    libzmq3-dev \
    libssl-dev \
    libgmp-dev \
    libfmt-dev \
    gosu \
    && rm -rf /var/lib/apt/lists/*

ENV BITBAR_DATA=/home/bitbar/.bitbar
ENV BITBAR_VERSION="master"
ENV BITBAR_PREFIX=/opt/bitbar-${BITBAR_VERSION}
ENV PATH=${BITBAR_PREFIX}/bin:$PATH

COPY --from=bitbar /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/bitbar/.bitbar"]

EXPOSE 9344 8777

ENTRYPOINT ["/entrypoint.sh"]

RUN env
RUN bitbard --help | grep "Bitbar version"

CMD ["bitbard"]

