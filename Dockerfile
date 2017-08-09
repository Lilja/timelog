FROM ubuntu:12.04
USER root
RUN apt-get update

RUN  apt-get update -qq

# Precise
RUN apt-get install -y elfutils libdw1/precise libasm1/precise libdw-dev/precise libelf-dev libcurl4-openssl-dev git curl cmake make build-essential

# Xenial
# RUN apt-get install -y pkg-config
# RUN apt-get install -y binutils-dev libcurl4-openssl-dev zlib1g-dev libdw-dev libiberty-dev cmake git python curl

RUN cd /tmp
RUN git clone https://github.com/SimonKagstrom/kcov
RUN printenv
RUN cd kcov && mkdir build && cd build && cmake .. && make && make install && cd ..

RUN mkdir /tmp/timelog
RUN mkdir /tmp/timelog/test
RUN mkdir /tmp/timelog/bin

ADD test/unittest.sh /tmp/timelog/test/unittest.sh
ADD test/test_dep.sh /tmp/timelog/test/test_dep.sh
ADD bin/timelog /tmp/timelog/bin/timelog
RUN cd /tmp/timelog/test && ./test_dep.sh && cd ..

RUN chmod +x /tmp/timelog/test/unittest.sh
RUN chmod +x /tmp/timelog/bin/timelog

ENV PATH="$PATH:/tmp/timelog/bin"
RUN mkdir /tmp/cov
ENV PS4=+

# Travis stuff
ARG TRAVIS_JOB_ID
ENV TRAVIS_JOB_ID=${TRAVIS_JOB_ID}

RUN cd /tmp/timelog/test && kcov --coveralls-id=${TRAVIS_JOB_ID} --include-path=/tmp/timelog/bin/timelog /tmp/cov/ unittest.sh
RUN /bin/bash -c <(curl -s https://codecov.io/bash) -s /tmp/cov
