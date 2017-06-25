#!/bin/bash

# Create test directory
mkdir dev/
dir=$(echo "$PWD/dev")

echo "-----------------"
echo "     Tests"
echo "-----------------"

test_case_name="Can create files on filesystem"
touch foo
if [ -f foo ]; then echo "PASSED: $test_case_name"
else echo "FAILED: $test_case_name"; fi
rm foo

# Test of create project
timelog -v --dev $dir create project <<END
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
  echo "PASSED: $test_case_name"
else
  echo "FAILED: $test_case_name"
  echo "$(test -f $dir/def/Test ; echo $?) : $(test -f $dir/Test.logs ; echo $?) : $(test ! -z $target ; echo $?) "
  exit 1
fi

echo "-----------------"
echo "List projects"
echo "-----------------"
k=$(timelog -v --dev $dir list projects)
match=$(echo "$k" | grep "1:\ Test\ \[ts\]")
test_case_name="List projects should list the newly created project"
[ -z "$match" ] && {
  echo "FAILED: $test_case_name"; exit 1;
} || { echo "PASSED: $test_case_name"; }

echo "-----------------"
echo "Log time for given project"
echo "-----------------"
test_case_name="A log entry should be created to file"
timelog -v --dev $dir log project ts 0800 1000 0
logs=$(cat "$dir/Test.logs")
k=$(echo "$logs" | wc -l)

[ $k -ne 1 ] && {
  echo "$test_case_name"; exit 1;
} || { echo "PASSED: $test_case_name"; }

dec_time=$(echo "$logs" | grep -o '\[2\]' | grep -o '2')
test_case_name="Decimal time did not equal to 2"
[ $dec_time -ne 2 ] && {
  echo "$test_case_name"; exit 1;
} || { echo "PASSED: $test_case_name"; }

echo "-----------------"
echo "Delete project is deleted from filesystem"
echo "-----------------"
timelog --dev $dir delete project <<END
1
y
END
test_case_name="Deleted project does no longer exists"
if [ ! -f "$dev/def/Test" ] &&
   [ ! -f "$dev/Test.logs" ]; then
  echo "PASSED: $test_case_name"
else
  echo "FAILED: $test_case_name"
  exit 1
fi

rm dev/config
rmdir dev/def/
rmdir dev/
