#!/bin/bash
# mocks BSD's date
# For example:

# Date version  BSD                                     GNU
# Command       date -jf "%Y-%m-%d" "2017-01-01" "%A"   date "%A" -d "2017-01-01"
# Output        Sat                                     Sat

# Mock BSD's --version incompatablity. GNU accepts --version so we have to exit non 0 for testing

date() {
  [ "$1" = "--version" ] && exit 1;

  amount_of_args=0
  skip_next=0

  for var in "$@"; do
    if [ "$skip_next" -eq 0 ]; then
      case "$var" in
        "-jf")
          # -jf and it's input format that is the next argument is not interesting.
          # -jf and a format is always supplied for a correct date.
          skip_next=1
          shift
        ;;
        *)
          amount_of_args=$((amount_of_args+=1))
        ;;
      esac
    else
      shift
      skip_next=0
    fi
  done

  if [ "$amount_of_args" -eq 1 ]; then
    command date "$1"
  elif [ "$amount_of_args" -eq 2 ]; then
    command date "$2" -d "$1"
  elif [ "$amount_of_args" -eq 0 ]; then
    exit 0
  else
    echo "Error, more than 2 or less than 1 arguments supplied. Don't know what to make of that. Aborting"
    exit 1
  fi
}

dir="$PWD/dev"
rm -r "$dir"
mkdir -p "$dir"

testOnBSDDateMock() {
  (. timelog --dev "$dir" project create 2>&1 >/dev/null <<END
Test1
ts1
40
140
kr
END
)
  assertTrue "Exit code of create project with bsd mock was not 0" "[ $? -eq 0 ]"

  (. timelog --dev "$dir" start --date "2017-01-01 12:00" 2>&1 >/dev/null)
  assertTrue "Exit code of start with bsd mock was not 0" "[ $? -eq 0 ]"

  (. timelog --dev "$dir" pause --date "2017-01-01 13:00" 2>&1 >/dev/null)
  assertTrue "Exit code of pause with bsd mock was not 0" "[ $? -eq 0 ]"

  (. timelog --dev "$dir" resume --date "2017-01-01 14:00" 2>&1 >/dev/null)
  assertTrue "Exit code of resume with bsd mock was not 0" "[ $? -eq 0 ]"

  cat "$dir/saved_log_times" | grep -q "Test1;start;2017-01-01 12:00"
  assertTrue "Saved log entries did not have start with timestamp" "[ $? -eq 0 ]"

  cat "$dir/saved_log_times" | grep -q "Test1;pause;2017-01-01 13:00"
  assertTrue "Saved log entries did not have pause with timestamp" "[ $? -eq 0 ]"

  cat "$dir/saved_log_times" | grep -q "Test1;resume;2017-01-01 14:00"
  assertTrue "Saved log entries did not have resume with timestamp" "[ $? -eq 0 ]"

  (. timelog --dev "$dir" log 2>&1 >/dev/null << END
15:00
y
END
)
  assertTrue "Exit code of log with bsd mock was not 0" "[ $? -eq 0 ]"

  grep -q "\[2\]" dev/Test1.logs
  assertTrue "Logs did not have [2] field." "[ $? -eq 0 ]"
}

. shunit2-2.1.6/src/shunit2
