FROM ragnaroek/kcov:v33
MAINTAINER Erik Lilja <6134511+Lilja@users.noreply.github.com>

RUN apt-get update
RUN apt-get install -y --no-install-recommends curl

RUN mkdir /tmp/timelog
RUN mkdir /tmp/timelog/test
RUN mkdir /tmp/timelog/bin

COPY test/unittest.sh /tmp/timelog/test/unittest.sh
COPY test/bsd_date_mock.sh /tmp/timelog/test/bsd_date_mock.sh
COPY test/test_dep.sh /tmp/timelog/test/test_dep.sh
COPY bin/timelog /tmp/timelog/bin/timelog

RUN chmod +x /tmp/timelog/test/unittest.sh
RUN chmod +x /tmp/timelog/test/bsd_date_mock.sh
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
RUN kcov --include-pattern=/tmp/timelog/bin/timelog /tmp/cov/ /tmp/timelog/test/unittest.sh
# Run with BSD stub
RUN kcov --include-pattern=/tmp/timelog/bin/timelog /tmp/cov/ /tmp/timelog/test/bsd_date_mock.sh
RUN ls /tmp/cov
