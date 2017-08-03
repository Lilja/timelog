#!/bin/bash

rm -r dev/
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

logProjectTest() {
timelog $debug --dev $dir log ts 0800 1800 0 >/dev/null <<END
y
END
}

testFileSystem() {
  touch foo
  assertTrue "Can not create files on filesystem" "[ -f foo ]"
  rm foo
}

testHasTimelogBinary() {
  k=$(which timelog 2>&1 >/dev/null ; echo $?)
  assertTrue "Timelog binary was not found" "[ $k -eq 0 ]"
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

testLogProjectWithDate() {
  day="2017-01-01"
  nextDay="2017-01-02"
  createProjectTest
timelog $debug --dev $dir log ts 0800 1000 0 >/dev/null --date "$day" <<END
y
END
  code=$?
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was not created when specifying custom date" "[ $( wc -l < $dir/Test.logs) -eq 1 ]"

timelog $debug --dev $dir log ts 0800 1100 0 --date "$nextDay" >/dev/null <<END
y
END
  code=$?
  logs=$(cat "$dir/Test.logs")
  amount_of_logs=$(wc -l < $dir/Test.logs 2>/dev/null)
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was not created. The amount of logs are: '$amount_of_logs'" "[ $amount_of_logs -eq 2 ]"

  dayOneLogs=$(echo "$logs" | head -n1)
  dayTwoLogs=$(echo "$logs" | tail -n1)
  dec_time=$(echo "$dayOneLogs" | grep -o '\[2\]' | grep -o '2')
  mil_time=$(echo "$dayOneLogs" | grep -o '\{02:00\}' | grep -o '02:00')
  dayOneDate=$(echo "$dayOneLogs" | grep -o "\/$day")
  assertTrue "Decimal time was not 2" "[ $dec_time -eq 2 ]"
  assertTrue "HH:mm time was not 02:00" "[ $mil_time = '02:00' ]"
  assertTrue "Custom date was not $day" "[ '$dayOneDate' = '/$day' ]"

  dec_time=$(echo "$dayTwoLogs" | grep -o '\[3\]' | grep -o '3')
  mil_time=$(echo "$dayTwoLogs" | grep -o '\{03:00\}' | grep -o '03:00')
  dayTwoDate=$(echo "$dayTwoLogs" | grep -o "\/$nextDay")
  assertTrue "Decimal time was not 3" "[ $dec_time -eq 3 ]"
  assertTrue "HH:mm time was not 03:00" "[ $mil_time = '03:00' ]"
  assertTrue "Custom date was not $nextDay" "[ '$dayTwoDate' = '/$nextDay' ]"

  deleteProject
}

testLogWeekFirstOfJan() {
  # Tests the edge case 2017-01-01. If retrieving 'year-week-day_in_week' it should retrieve:
  # 2016-52-7
  day="2017-01-01"
  year_week_day_of_date="2016-52-7"
  createProjectTest
timelog $debug --dev $dir log ts 0800 1000 0 >/dev/null --date "$day" <<END
y
END
  code=$?
  logs=$(cat "$dir/Test.logs")
  amount_of_logs=$(wc -l < $dir/Test.logs 2>/dev/null)
  mixed_date=$(echo "$logs" | grep -o "$year_week_day_of_date\/$day")
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was not created when specifying custom date" "[ $( wc -l < $dir/Test.logs) -eq 1 ]"
  assertTrue "Custom date was not $day" "[ '$mixed_date' = '$year_week_day_of_date/$day' ]"

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

testDifferentInputFormats() {
  createProjectTest
  rgx="Decimal time: 2 Military time: 02:00"
  list=("[8,10] [800,1000] [0800,1000] [8.00,10.00] [8:00,10:00] [08:00,10:00]")

  for it in $list; do
    begin=$(echo "$it" | grep -o "[0-9]*\:*\.*[0-9]*," | sed 's#,##')
    end=$(echo "$it" | grep -o ",[0-9]*\:*\.*[0-9]*" | sed 's#,##')
entry=$(timelog $debug --dev $dir log ts "$begin" "$end" 0 <<END
n
END
)
    regexd=$(echo "$entry" | grep -o "$rgx")

    assertTrue "Begining time of '$begin' and end time of '$end' did not equal to the output time of 2/02:00:$entry" "[ '$regexd' = '$rgx' ]"
  done

  deleteProject
}

testPurge() {
  createProjectTest
  logProjectTest
timelog $debug --dev $dir --purge << END
timelog
END
  assertTrue "No log folder was deleted when purging" "[ ! -d '$dir' ]"
}

rm -r $dir/

. shunit2-2.1.6/src/shunit2
