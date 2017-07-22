#!/bin/bash

if [[ $1 = "-v" ]]; then debug="-v"
else debug=""; fi

# Clean test directory if need to
[ -d dev ] && rm -r dev/

# Create test directory
mkdir dev/
dir=$(echo "$PWD/dev")

testFileSystem(){
  touch foo
  assertTrue "Can not create files on filesystem" "[ -f foo ]"
  rm foo
}

createProjectTest() {
  if [[ $1 -eq 5 ]]; then
timelog $debug --dev $dir create project > /dev/null <<END
Test
ts
40
140
kr
END
  fi
}

createProjectWithoutMoneyPerHour() {
  if [[ $1 -eq 5 ]]; then
timelog $debug --dev $dir create project > /dev/null <<END
Test2
ts2
40
s
END
  fi
}

deleteProjectTest() {
  if [[ $1 -eq 5 ]]; then
timelog $debug --dev $dir delete project > /dev/null << END
1
y
END
  fi
}

testCreateAndDeleteProject() {
  createProjectTest 5
  code=$?
  proj_name=$(grep -o 'project_name\ *\=\ *Test' $dir/def/Test)
  proj_id=$(grep -o 'project_id\ *\=\ *Test' $dir/def/Test)
  target=$(grep -o 'target_hours\ *\=\ *40' $dir/def/Test)
  mph=$(grep -o 'money_per_hour\ *\=\ *140' $dir/def/Test)
  curr=$(grep -o 'currency\ *\=\ *kr' $dir/def/Test)
  assertTrue "Exit code for create project was not 0" "[ $code -eq 0 ]"
  assertTrue "Definition file could not be created" "[ -f $dir/def/Test ]"
  assertTrue "Log file could not be created" "[ -f $dir/Test.logs ]"
  assertTrue "Project name was not retrieved" "[ ! -z $proj_name ]"
  assertTrue "Project id was not retrieved" "[ -f $proj_id ]"
  assertTrue "Target hours was not retrieved" "[ ! -z $target ]"
  assertTrue "Money per hour was not retrieved" "[ ! -z $mph ]"
  assertTrue "Currency was not retrieved" "[ ! -z $curr ]"

  deleteProjectTest 5
  code=$?
  assertTrue "Exit code for create project was not 0" "[ $code -eq 0 ]"
  assertTrue "Definition file was not deleted" "[ ! -f $dir/def/Test ]"
  assertTrue "Log file was not deleted" "[ ! -f $dir/Test.logs ]"
}

testCreateProjectWithoutMoneyPerHour() {
  createProjectWithoutMoneyPerHour 5
  proj_name=$(grep -o 'project_name\ *\=\ *Test' $dir/def/Test2)
  proj_id=$(grep -o 'project_id\ *\=\ *Test' $dir/def/Test2)
  target=$(grep -o 'target_hours\ *\=\ *40' $dir/def/Test2)
  mph=$(grep -o 'money_per_hour\ *\=\ *140' $dir/def/Test2)
  curr=$(grep -o 'currency\ *\=\ *kr' $dir/def/Test2)
  assertTrue "Exit code for create project was not 0" "[ $code -eq 0 ]"
  assertTrue "Definition file could not be created" "[ -f $dir/def/Test2 ]"
  assertTrue "Log file could not be created" "[ -f $dir/Test2.logs ]"
  assertTrue "Project name was not retrieved" "[ ! -z $proj_name ]"
  assertTrue "Project id was not retrieved" "[ -f $proj_id ]"
  assertTrue "Target hours was not retrieved" "[ ! -z $target ]"
  assertTrue "Money per hour was retrieved" "[ -z $mph ]"
  assertTrue "Currency was retrieved" "[ -z $curr ]"

  deleteProjectTest 5
}

testListProjects() {
  createProjectTest 5
  k=$(timelog $debug --dev $dir list projects)
  code=$?
  match=$(echo "$k" | grep "1:\ Test\ \[ts\]")
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "List projects did not print out the created project" "[ ! -z '$match' ]"
  deleteProjectTest 5
}

testLogProject() {
  createProjectTest 5
timelog $debug --dev $dir log ts 0800 1000 0 <<END
n
END
  code=$?
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was created when specified not to create" "[ $(cat $dir/Test.logs | wc -l) -eq 0 ]"


timelog $debug --dev $dir log ts 0800 1000 0 <<END
y
END
  code=$?
  logs=$(cat "$dir/Test.logs")
  amount_of_logs=$(cat $dir/Test.logs 2>/dev/null | wc -l)
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was not created" "[ $amount_of_logs -eq 1 ]"

  dec_time=$(echo "$logs" | grep -o '\[2\]' | grep -o '2')
  mil_time=$(echo "$logs" | grep -o '\{02:00\}' | grep -o '02:00')
  assertTrue "Decimal time was not 2" "[ $dec_time -eq 2 ]"
  assertTrue "HH:mm time was not 02:00" "[ $mil_time = '02:00' ]"
  deleteProjectTest 5
}

testLogProjectwithObscureTime() {
  createProjectTest 5

timelog $debug --dev $dir log ts 0840 1802 34 <<END
y
END
  code=$?
  logs=$(cat "$dir/Test.logs")

  dec_time=$(echo "$logs" | grep -o '\[[0-9]*\.*[0-9]*\]' | grep -o '[0-9]*\.[0-9]*')
  mil_time=$(echo "$logs" | grep -o '\{[0-9]*:[0-9]*\}' | grep -o '[0-9]*:[0-9]*')
  assertTrue "Decimal time did not equal 8.8" "[ $dec_time = '8.8' ]"
  assertTrue "Decimal time did not equal 08:48" "[ $mil_time = '08:48' ]"

  deleteProjectTest 5
}

testShowWeeklyLogs() {
  createProjectTest 5
  current_week=$(date +%V)
  today=$(date +%A)
timelog $debug --dev $dir log ts 0840 1802 34 << END
y
END
  capture=$(timelog --dev $dir show logs ts $current_week)
  cmd=$(grep -q "Days worked for week $current_week" <<< $capture ; echo $?)
  assertTrue "Weekly stats for $today was recorded" "[ $cmd -eq 0 ]"
  cmd=$(grep -q "$today: 8\.8h \/ 08:48" <<< $capture ; echo $?)
  assertTrue "Today($today)'s decimal time and/or military time was not equal to 8.8h/08:48" "[ $cmd -eq 0 ]"

  deleteProjectTest 5
}

testShowWeeklyLogsEmpty() {
  createProjectTest 5
  current_week=$(date +%V)
  current_year=$(date +%Y)
  today=$(date +%A)
  capture=$(timelog --dev $dir show logs ts $current_week)
  cmd=$(grep -q "Nothing worked on week $current_week year $current_year for project Test" <<< "$capture"; echo $?)
  assertTrue "When nothing was logged, the output wasn't nothing" "[ $cmd -eq 0 ]"

  deleteProjectTest 5
}

# Days worked for week 28
# Monday: 8.8h / 08:48
# ------
# You have worked for 3.66667 hours at the following days: Monday
# You have 36.3333 hours out of 40 hours giving you an estimate of
# 9.08333 hours for 4 more days.
# You have earned 513.334 kr pre-tax!

# timelog $debug --dev $dir show logs ts $(date +%V)
# code=$?

rm -r $dir/


. shunit2-2.1.6/src/shunit2
