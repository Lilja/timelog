FROM ubuntu:12.04
MAINTAINER Erik Lilja <6134511+Lilja@users.noreply.github.com>

RUN apt-get update \
 && apt-get install -y --no-install-recommends elfutils libdw1/precise libasm1/precise libdw-dev/precise libelf-dev libcurl4-openssl-dev git curl cmake make build-essential \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Xenial
# RUN apt-get install -y pkg-config
# RUN apt-get install -y binutils-dev libcurl4-openssl-dev zlib1g-dev libdw-dev libiberty-dev cmake git python curl

RUN git clone https://github.com/SimonKagstrom/kcov /tmp/kcov
WORKDIR /tmp/kcov/build
RUN cmake .. && make && make install

RUN mkdir /tmp/timelog
RUN mkdir /tmp/timelog/test
RUN mkdir /tmp/timelog/bin

COPY test/unittest.sh /tmp/timelog/test/unittest.sh
COPY test/test_dep.sh /tmp/timelog/test/test_dep.sh
COPY bin/timelog /tmp/timelog/bin/timelog

RUN chmod +x /tmp/timelog/test/unittest.sh
RUN chmod +x /tmp/timelog/test/test_dep.sh
RUN chmod +x /tmp/timelog/bin/timelog

# Run the dependecy script, get shunit2 so that unittest.sh can execute the test cases
RUN /tmp/timelog/test/test_dep.sh /tmp
# Now that shunit2 exists in the first parameter sent to test_dep, we can cd/WORKDIR to that
# directory and run the unit_tests, as long as the directory you stand in has a shunit2 folder.

ENV PATH="$PATH:/tmp/timelog/bin"

# Prepare kcov output folder
RUN mkdir /tmp/cov

# Clear any PS4 variable that prevents us from getting metrics
ENV PS4=+

WORKDIR /tmp

# Run and only include bin/timelog
RUN kcov --include-path=/tmp/timelog/bin/timelog /tmp/cov/ /tmp/timelog/test/unittest.sh
