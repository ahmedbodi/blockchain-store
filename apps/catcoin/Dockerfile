FROM alpine AS berkeleydb

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add autoconf
RUN apk --no-cache add automake
RUN apk --no-cache add build-base
RUN apk --no-cache add libressl
ENV BERKELEYDB_VERSION=db-6.2.23
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz
RUN tar -xzf *.tar.gz
RUN mkdir -p ${BERKELEYDB_PREFIX}

WORKDIR /${BERKELEYDB_VERSION}/build_unix
RUN CFLAGS=-Wno-error=implicit-function-declaration ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX}
RUN make -j4
RUN make install
RUN rm -rf ${BERKELEYDB_PREFIX}/docs

FROM alpine AS catcoin-core

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

ARG CATCOIN_VERSION="v2.2.0"
ENV CATCOIN_VERSION=${CATCOIN_VERSION}
ENV CATCOIN_PREFIX=/opt/catcoin-${CATCOIN_VERSION}

RUN git clone --depth 1 --branch ${CATCOIN_VERSION} https://github.com/ahmedbodi/catcoincore /catcoin-${CATCOIN_VERSION}

WORKDIR /catcoin-${CATCOIN_VERSION}
RUN sed -i '/AC_PREREQ/a\AR_FLAGS=cr' src/univalue/configure.ac
RUN sed -i '/AX_PROG_CC_FOR_BUILD/a\AR_FLAGS=cr' src/secp256k1-zkp/configure.ac
RUN sed -i s:sys/fcntl.h:fcntl.h: src/compat.h

# missing includes required by alpine compiler
RUN sed -i '/#include <stdint.h>/a #include <stdexcept>' src/support/lockedpool.h
RUN sed -i '/#include <attributes.h>/a #include <cstdint>' src/util/bip32.h
RUN sed -i '/#include <cstring>/a #include <cstdint>' src/util/string.h
# fixes overflow causing segfault
RUN sed -i '/char\ scratchpad\[SCRYPT_SCRATCHPAD_SIZE\];/a\memset(scratchpad, 0, sizeof(scratchpad));' src/crypto/scrypt.cpp
RUN sed -i 's/char\ scratchpad\[SCRYPT_SCRATCHPAD_SIZE\];/thread_local &/g' src/crypto/scrypt.cpp
# update filesystem to v1.2.2: fixes alpine build error
RUN wget -O src/libmw/deps/ghc/include/ghc/filesystem.hpp https://github.com/gulrak/filesystem/releases/download/v1.2.2/filesystem.hpp

RUN ./autogen.sh
RUN ./configure LDFLAGS=-L`ls -d /opt/db*`/lib/ CPPFLAGS=-I`ls -d /opt/db*`/include/ \
  --prefix=${CATCOIN_PREFIX} \
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
RUN strip ${CATCOIN_PREFIX}/bin/catcoin-cli
RUN strip ${CATCOIN_PREFIX}/bin/catcoin-tx
RUN strip ${CATCOIN_PREFIX}/bin/catcoind
RUN strip ${CATCOIN_PREFIX}/lib/libbitcoinconsensus.a
RUN strip ${CATCOIN_PREFIX}/lib/libbitcoinconsensus.so.0.0.0

# Build stage for compiled artifacts
FROM alpine

LABEL maintainer.0="Ahmed Bodiwala (ahmedbodi@crypto-expert.com)"

RUN adduser -S catcoin
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk --no-cache add \
  boost-filesystem \
  boost-system \
  boost-thread \
  libevent \
  libzmq \
  su-exec \
  fmt-dev \
  libressl-dev \
  gmp

ENV CATCOIN_DATA=/home/catcoin/.catcoin
ENV CATCOIN_VERSION="v2.2.0"
ENV CATCOIN_PREFIX=/opt/catcoin-${CATCOIN_VERSION}
ENV PATH=${CATCOIN_PREFIX}/bin:$PATH

COPY --from=catcoin-core /opt /opt
COPY docker-entrypoint.sh /entrypoint.sh

VOLUME ["/home/catcoin/.catcoin"]

EXPOSE 9332 9333 19332 19335 19443 19444

ENTRYPOINT ["/entrypoint.sh"]

RUN env
RUN catcoind -version | grep "Catcoin Core version ${CATCOIN_VERSION}"

CMD ["catcoind"]

