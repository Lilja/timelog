FROM ubuntu:12.04
MAINTAINER Erik Lilja <6134511+Lilja@users.noreply.github.com>

USER root
RUN apt-get update

RUN  apt-get update -qq

# Precise
RUN apt-get install -y elfutils libdw1/precise libasm1/precise libdw-dev/precise libelf-dev libcurl4-openssl-dev git curl cmake make build-essential \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Xenial
# RUN apt-get install -y pkg-config
# RUN apt-get install -y binutils-dev libcurl4-openssl-dev zlib1g-dev libdw-dev libiberty-dev cmake git python curl

RUN git clone https://github.com/SimonKagstrom/kcov /tmp/kcov
RUN cd /tmp/kcov && mkdir build && cd build && cmake .. && make && make install && cd ..

RUN mkdir /tmp/timelog
RUN mkdir /tmp/timelog/test
RUN mkdir /tmp/timelog/bin

COPY test/unittest.sh /tmp/timelog/test/unittest.sh
COPY test/test_dep.sh /tmp/timelog/test/test_dep.sh
COPY bin/timelog /tmp/timelog/bin/timelog
RUN cd /tmp/timelog/test && ./test_dep.sh

RUN chmod +x /tmp/timelog/test/unittest.sh
RUN chmod +x /tmp/timelog/bin/timelog

ENV PATH="$PATH:/tmp/timelog/bin"
RUN mkdir /tmp/cov
ENV PS4=+

# Travis stuff
ARG TRAVIS_JOB_ID
ENV TRAVIS_JOB_ID=${TRAVIS_JOB_ID}

RUN cd /tmp/timelog/test && kcov --include-path=/tmp/timelog/bin/timelog /tmp/cov/ unittest.sh
