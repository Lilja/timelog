# Tests

To be able to get something merged, we need new test cases for that feature and that all tests pass.

[Shunit2](https://github.com/kward/shunit2) is what we use to set up assert, setup and teardown logic.

[kcov](https://github.com/simonkagstrom/kcov) is used in docker to watch over what shunit's -x run spits out.

[codecov](https://codecov.io) is then being used to send coverage report which will report it to the commit in github.

## Unit tests

Some unit tests are located in `unittest.sh` which is the general purpose unit tests.

Because of BSD's implementation of `date` incompatibilities with the flag `-d` of the GNU implementation, a small adapter has been written in `timelog` called `wrap_date()` for having out-of-the-box support for OSX/BSD.
In order to mock/stub/fake having a BSD's date implementation for testing new features on e.g. windows(cygwin)/linux, `bsd_date_mock.sh` is written. It shadows a `date` binary which executes on a GNU `date` making the flow-chart like this.

1. Date input from user to timelog program
2. Timelog checks for a valid timestamp from the user input with `wrap_date`
3. `wrap_date` checks `date`'s argument `--version`
4. The fake `date` purposely returns with an exit code of 1 because BSD's `date` does not recognize `--version`
5. `wrap_date` sees `--version` being return as 1 so it proceeds with BSD compatible `date` calls.
6. The fake `date` translates BSD `date` to GNU `date`.

## Run unit tests
Make sure that you've run `test_dep.sh` so shunit2 is in the current directory.

## Run coverage manually
Unless you can't wait for the build to see the coverage of what you're building, run follow this step tp get local coverage metrics.

Use docker and run `runMetrics.sh` check the folder `metrics` for the reports. To open it in a browser `open metrics/index.html` on OS X/`xdg-open metrics/index.html` on linux.
