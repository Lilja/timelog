#!/bin/bash

if [[ $1 = "-v" ]]; then debug="-v"
else debug=""; fi
# Create test directory
mkdir dev/
dir=$(echo "$PWD/dev")

echo "-----------------"
echo "     Tests"
echo "-----------------"
green() { echo -ne "$(tput setaf 2)$*$(tput setaf 9) "; }
red() { echo -ne "$(tput setaf 1)$*$(tput setaf 9) "; }

test_case_name="Can create files on filesystem"
touch foo
if [ -f foo ]; then green "PASSED"; echo "$test_case_name"
else red "FAILED:"; echo "$test_case_name"; fi
rm foo

# Test of create project
timelog $debug --dev $dir create project <<END
Test
ts
140
40
kr
END

test_case_name="Created project should have def. and .logs file"
target=$(grep -o 'target_hours\ *\=\ *40' $dir/def/Test)
if [[ -f "$dir/def/Test" &&
    -f "$dir/Test.logs"  &&
    ! -z $target ]]; then
  green "PASSED:"; echo "$test_case_name"
else
  red "FAILED:"; echo "$test_case_name"
  echo "$(test -f $dir/def/Test ; echo $?) : $(test -f $dir/Test.logs ; echo $?) : $(test ! -z $target ; echo $?) "
  exit 1
fi

echo "-----------------"
echo "List projects"
echo "-----------------"
k=$(timelog $debug --dev $dir list projects)
match=$(echo "$k" | grep "1:\ Test\ \[ts\]")
test_case_name="List projects should list the newly created project"
[ -z "$match" ] && {
  red "FAILED:"; echo "$test_case_name"; exit 1;
} || { green "PASSED"; echo "$test_case_name"; }

echo "-----------------"
echo "Log time for given project"
echo "-----------------"
test_case_name="A log entry should not be created if aborted"
timelog $debug --dev $dir log project ts 0800 1000 0 <<END
n
END
if [[ -f "$dir/Test.logs" && $(cat "$dir/Test.logs" | wc -l) -eq 0 ]]; then
  green "PASSED:"; echo "$test_case_name";
else
  red "FAILED:"; echo "$test_case_name"; exit 1;
fi

# -----------------------------------------------------------------------

test_case_name="A log entry should be created to file"
timelog $debug --dev $dir log project ts 0800 1000 0 <<END
y
END
code=$?
logs=$(cat "$dir/Test.logs")
k=$(echo "$logs" | wc -l)

if [[ $code -eq 0 && $k -eq 1 ]]; then
  green "PASSED:"; echo "$test_case_name";
else 
  red "FAILED:"; echo "$test_case_name"; echo "exit code:'$code' : amount of lines: '$k'"; exit 1;
fi

# -----------------------------------------------------------------------

dec_time=$(echo "$logs" | grep -o '\[2\]' | grep -o '2')
test_case_name="Decimal time should equal to 2"
if [[ ! -z "$logs" && $dec_time -eq 2 ]]; then
  green "PASSED:"; echo "$test_case_name";
else red "FAILED:"; echo "$test_case_name"; echo "should not be empty: '$logs' : should be 2:'$dec_time'"; exit 1; fi

# -----------------------------------------------------------------------

mil_time=$(echo "$logs" | grep -o '\{02:00\}' | grep -o '02:00')
test_case_name="Military time should equal to 02:00"
if [[ ! -z "$logs" && $mil_time = "02:00" ]]; then
  green "PASSED:"; echo "$test_case_name";
else red "FAILED:"; echo "$test_case_name"; echo "$logs : $mil_time"; exit 1; fi

# -----------------------------------------------------------------------
test_case_name="A log entry should be created to file x2 - with obscure time"
timelog $debug --dev $dir log project ts 0840 1802 34 <<END
y
END
code=$?
logs=$(cat "$dir/Test.logs" | head -n2 | tail -n1)
echo "LOGS:$logs"
k=$(echo "$logs" | wc -l)

dec_time=$(echo "$logs" | grep -o '\[[0-9]*\.*[0-9]*\]' | grep -o '[0-9]*\.[0-9]*')
test_case_name="Decimal time should equal to 2"
if [[ ! -z "$logs" && $dec_time = "8.8" ]]; then
  green "PASSED:"; echo "$test_case_name";
else red "FAILED:"; echo "$test_case_name"; echo "should not be empty: '$logs' : should be 2:'$dec_time'"; exit 1; fi

# -----------------------------------------------------------------------

mil_time=$(echo "$logs" | grep -o '\{[0-9]*:[0-9]*\}' | grep -o '[0-9]*:[0-9]*')
test_case_name="Military time should equal to 02:00"
if [[ ! -z "$logs" && $mil_time = "08:48" ]]; then
  green "PASSED:"; echo "$test_case_name";
else red "FAILED:"; echo "$test_case_name"; echo "should not be empty:'$logs' : should be 08:48:'$mil_time'"; exit 1; fi

echo "-----------------"
echo "Delete project is deleted from filesystem"
echo "-----------------"
timelog $debug --dev $dir delete project <<END
1
y
END
test_case_name="Deleted project does no longer exists"
if [[ ! -f "$dev/def/Test" &&
    ! -f "$dev/Test.logs" ]]; then
  green "PASSED:"; echo "$test_case_name";
else
  red "FAILED:"; echo "$test_case_name";
  exit 1
fi

ls dev/def/
rm dev/config
rmdir dev/def/
rmdir dev/
