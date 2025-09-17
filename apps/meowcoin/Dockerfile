FROM alpine AS berkeleydb

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add build-base
RUN apk --no-cache add libressl
ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix
RUN CFLAGS=-Wno-error=implicit-function-declaration ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

FROM alpine AS meowcoin

COPY --from=berkeleydb /opt /opt

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add boost-dev
RUN apk --no-cache add build-base
RUN apk --no-cache add chrpath
RUN apk --no-cache add file
RUN apk --no-cache add fmt-dev
RUN apk --no-cache add gnupg
RUN apk --no-cache add libevent-dev
RUN apk --no-cache add libressl
RUN apk --no-cache add libressl-dev
RUN apk --no-cache add libtool
RUN apk --no-cache add linux-headers
RUN apk --no-cache add zeromq-dev
RUN apk --no-cache add git
RUN apk --no-cache add gmp
RUN apk --no-cache add gmp-dev

ARG MEOWCOIN_VERSION="Meow-v3.0.4"
ENV MEOWCOIN_VERSION=${MEOWCOIN_VERSION}
ENV MEOWCOIN_PREFIX=/opt/meowcoin-${MEOWCOIN_VERSION}

RUN git clone --depth 1 --branch ${MEOWCOIN_VERSION} https://github.com/Meowcoin-Foundation/Meowcoin /meowcoin-${MEOWCOIN_VERSION}

WORKDIR /meowcoin-${MEOWCOIN_VERSION}
RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h

# missing includes required by alpine compiler
RUN sed -i '/#include <stdint.h>/a #include <stdexcept>' src/support/lockedpool.h

RUN ./autogen.sh
RUN ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
  --prefix=${MEOWCOIN_PREFIX} \
  --mandir=/usr/share/man \
  --disable-tests \
  --disable-bench \
  --disable-ccache \
  --with-gui=no \
  --with-utils \
  --with-libs \
  --with-daemon
RUN make -j4
RUN make install
RUN strip ${MEOWCOIN_PREFIX}/bin/meowcoin-cli
RUN strip ${MEOWCOIN_PREFIX}/bin/meowcoind
RUN strip ${MEOWCOIN_PREFIX}/lib/libmeowcoinconsensus.a
RUN strip ${MEOWCOIN_PREFIX}/lib/libmeowcoinconsensus.so.0.0.0

# Build stage for compiled artifacts
FROM alpine

LABEL maintainer.0="Ahmed Bodiwala (ahmedbodi@crypto-expert.com)"

RUN adduser -S meowcoin
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  boost-filesystem \
  boost-system \
  boost-thread \
  boost-chrono \
  boost-program_options \
  libevent \
  libzmq \
  su-exec \
  fmt-dev \
  libressl-dev \
  gmp

ENV MEOWCOIN_DATA=/home/meowcoin/.meowcoin
ENV MEOWCOIN_VERSION="Meow-v3.0.4"
ENV MEOWCOIN_PREFIX=/opt/meowcoin-${MEOWCOIN_VERSION}
ENV PATH=${MEOWCOIN_PREFIX}/bin:$PATH

COPY --from=meowcoin /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/meowcoin/.meowcoin"]

EXPOSE 8767 8766

ENTRYPOINT ["/entrypoint.sh"]

RUN env
RUN meowcoind -version | grep "Meowcoin Core Daemon version"

CMD ["meowcoind"]

