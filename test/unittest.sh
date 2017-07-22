#!/bin/bash

if [[ $1 = "-v" ]]; then debug="-v"; shift
else debug=""; fi

# Clean test directory if need to
[ -d dev ] && rm -r dev/

# Create test directory
mkdir dev/
dir=$(echo "$PWD/dev")

createProjectWithParams() {
timelog $debug --dev $dir create project > /dev/null <<END
$1
$2
$3
$4
$5
END
}

testFileSystem() {
  touch foo
  assertTrue "Can not create files on filesystem" "[ -f foo ]"
  rm foo
}

createProjectTest() {
  createProjectWithParams "Test" "ts" "40" "140" "kr"
}

createProjectWithoutMoneyPerHour() {
  createProjectWithParams "Test2" "ts2" "40" "s"
}

deleteProject() {
timelog $debug --dev $dir delete project > /dev/null << END
1
y
END
}

testCreateAndDeleteProject() {
  createProjectTest
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

  deleteProject
  code=$?
  assertTrue "Exit code for create project was not 0" "[ $code -eq 0 ]"
  assertTrue "Definition file was not deleted" "[ ! -f $dir/def/Test ]"
  assertTrue "Log file was not deleted" "[ ! -f $dir/Test.logs ]"
}

testCreateProjectWithoutMoneyPerHour() {
  createProjectWithoutMoneyPerHour
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

  deleteProject
}

testListProjects() {
  createProjectTest
  k=$(timelog $debug --dev $dir list projects)
  code=$?
  match=$(echo "$k" | grep "1:\ Test\ \[ts\]")
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "List projects did not print out the created project" "[ ! -z '$match' ]"
  deleteProject
}

testLogProject() {
  createProjectTest
timelog $debug --dev $dir log ts 0800 1000 0 >/dev/null <<END
n
END
  code=$?
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was created when specified not to create" "[ $(cat $dir/Test.logs | wc -l) -eq 0 ]"

timelog $debug --dev $dir log ts 0800 1000 0 >/dev/null <<END
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
  deleteProject
}

testLogProjectwithObscureTime() {
  createProjectTest

timelog $debug --dev $dir log ts 0840 1802 34 >/dev/null <<END
y
END
  code=$?
  logs=$(cat "$dir/Test.logs")

  dec_time=$(echo "$logs" | grep -o '\[[0-9]*\.*[0-9]*\]' | grep -o '[0-9]*\.[0-9]*')
  mil_time=$(echo "$logs" | grep -o '\{[0-9]*:[0-9]*\}' | grep -o '[0-9]*:[0-9]*')
  assertTrue "Decimal time did not equal 8.8" "[ $dec_time = '8.8' ]"
  assertTrue "Decimal time did not equal 08:48" "[ $mil_time = '08:48' ]"

  deleteProject
}

testShowWeeklyLogs() {
  createProjectTest
  current_week=$(date +%V)
  today=$(date +%A)
timelog $debug --dev $dir log ts 0840 1802 34 >/dev/null << END
y
END
  capture=$(timelog --dev $dir show logs ts $current_week)
  cmd=$(grep -q "Days worked for week $current_week" <<< $capture ; echo $?)
  assertTrue "Weekly stats for $today was recorded" "[ $cmd -eq 0 ]"
  cmd=$(grep -q "$today: 8\.8h \/ 08:48" <<< $capture ; echo $?)
  assertTrue "Today($today)'s decimal time and/or military time was not equal to 8.8h/08:48" "[ $cmd -eq 0 ]"

  deleteProject
}

testShowWeeklyLogsEmpty() {
  createProjectTest
  current_week=$(date +%V)
  current_year=$(date +%Y)
  today=$(date +%A)
  capture=$(timelog --dev $dir show logs ts $current_week)
  cmd=$(grep -q "Nothing worked on week $current_week year $current_year for project Test" <<< "$capture"; echo $?)
  assertTrue "When nothing was logged, the output wasn't nothing" "[ $cmd -eq 0 ]"

  deleteProject
}

testMultipleprojects() {
  createProjectWithParams "Test1" "ts1" "40" "140" "kr"
  createProjectWithParams "Test2" "ts2" "40" "240" "kr"

  projects=$(timelog $debug --dev $dir list projects | grep '^[0-9]:' | wc -l)
  assertTrue "There was not two projects created: $projects counted" "[ $projects -eq 2 ]"

timelog $debug --dev $dir log >/dev/null << END
1
08:00
12:00
0
y
END

timelog $debug --dev $dir log >/dev/null << END
2
08:00
18:00
0
y
END

  logs=$(timelog $debug --dev $dir show logs ts1 $(date +%V))
  remaining_hours=$(echo "$logs" | grep -o 'You have 36 hours more to work')
  worked_hours=$(echo "$logs" | grep -o 'You have worked for 4 hours')
  assertTrue "Remaining hours was not 36" "[ ! -z '$remaining_hours' ]"
  assertTrue "Worked hours was not 4" "[ ! -z '$worked_hours' ]"

  logs=$(timelog $debug --dev $dir show logs ts2 $(date +%V))
  remaining_hours=$(echo "$logs" | grep -o 'You have 30 hours more to work')
  worked_hours=$(echo "$logs" | grep -o 'You have worked for 10 hours')
  assertTrue "Remaining hours was not 30" "[ ! -z '$remaining_hours' ]"
  assertTrue "Worked hours was not 10" "[ ! -z '$worked_hours' ]"

  deleteProject
  deleteProject
}

rm -r $dir/

. shunit2-2.1.6/src/shunit2
