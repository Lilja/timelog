#!/bin/bash
start=$(date +%s)

if [[ $1 = "-v" ]]; then debug="-v"; shift
else debug=""; fi

dir="$PWD/dev"

# Clean test directory if need to
[ -d "$dir" ] && rm -r "$dir"

# Create test directory
mkdir "$dir"

createProjectWithParams() {
timelog $debug --dev "$dir" create project >/dev/null <<END
$1
$2
$3
$4
$5
END
}

logProjectTest() {
timelog $debug --dev "$dir" log ts 0800 1800 0 >/dev/null <<END
y
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
timelog $debug --dev "$dir" delete project > /dev/null << END
1
y
END
}

testHasTimelogBinary() {
  k=$(which timelog 2>&1 >/dev/null ; echo $?)
  assertTrue "Timelog binary was not found" "[ $k -eq 0 ]"
}

testWhenEmptyProjectInitally() {
  output=$(timelog --dev "$dir" list project_id >/dev/null)
  assertTrue "When no project have been created, there are projects created with list project_id" "[ -z '$output' ]"
  if [ ! -z "$output" ]; then exit 1; fi
}

testCreateAndDeleteProject() {
  createProjectTest
  code=$?
  proj_name=$(grep -o 'project_name\ *\=\ *Test' "$dir/def/Test")
  proj_id=$(grep -o 'project_id\ *\=\ *Test' "$dir/def/Test")
  target=$(grep -o 'target_hours\ *\=\ *40' "$dir/def/Test")
  mph=$(grep -o 'money_per_hour\ *\=\ *140' "$dir/def/Test")
  curr=$(grep -o 'currency\ *\=\ *kr' "$dir/def/Test")
  assertTrue "Exit code for create project was not 0" "[ $code -eq 0 ]"
  assertTrue "Definition file could not be created" "[ -f "$dir/def/Test" ]"
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

testCreateProjectWithShadyProjectName() {
  proj_name="Test { }"
  createProjectWithParams "$proj_name" "test2" "40" "40" "kr"
  code=$?

  assertTrue "Exit code for create project was not 0" "[ $code -eq 0 ]"
  assertTrue "No log file created with project name '$proj_name'" "[ -f '$dir/$proj_name.logs' ]"
  assertTrue "No definition file created with project name '$proj_name' " "[ -f '$dir/def/$proj_name' ]"

  deleteProject

  createProjectWithParams "Test" "test2" "40" "40d"
  code=$?
  assertTrue "Exit code for faulty create project was not 1" "[ $code -eq 1 ]"

}

testCreateProjectWithFaultyParams() {
  createProjectWithParams "Test" "test2" "40d"
  code=$?
  assertTrue "Exit code for faulty create project was not 1" "[ $code -eq 1 ]"

  createProjectWithParams "Test ]"
  code=$?
  assertTrue "Exit code for faulty create project was not 1 when having a [ in the project name" "[ $code -eq 1 ]"

  createProjectWithParams "Test ["
  code=$?
  assertTrue "Exit code for faulty create project was not 1 when having a [ in the project name" "[ $code -eq 1 ]"

  createProjectWithParams "Test ;"
  code=$?
  assertTrue "Exit code for faulty create project was not 1 when having a ; in the project name" "[ $code -eq 1 ]"


  createProjectWithParams "Test" "test2" "40" "40d"
  code=$?
  assertTrue "Exit code for faulty create project was not 1" "[ $code -eq 1 ]"

  projects=$(ls "$dir/*.logs" 2>/dev/null | wc -l)
  assertTrue "Amount of projects should be 0" "[ $projects -eq 0 ]"
}

testCreateProjectWithoutMoneyPerHour() {
  createProjectWithoutMoneyPerHour
  code=$?
  proj_name=$(grep -o 'project_name\ *\=\ *Test' "$dir/def/Test2")
  proj_id=$(grep -o 'project_id\ *\=\ *Test' "$dir/def/Test2")
  target=$(grep -o 'target_hours\ *\=\ *40' "$dir/def/Test2")
  mph=$(grep -o 'money_per_hour\ *\=\ *140' "$dir/def/Test2")
  curr=$(grep -o 'currency\ *\=\ *kr' "$dir/def/Test2")
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
  k=$(timelog $debug --dev "$dir" list projects)
  code=$?
  match=$(echo "$k" | grep "1:\ Test\ \[ts\]")
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "List projects did not print out the created project" "[ ! -z '$match' ]"
  deleteProject
}

testLogProject() {
  createProjectTest
timelog $debug --dev "$dir" log ts 0800 1000 0 >/dev/null <<END
n
END
  code=$?
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was created when specified not to create" "[ $(< $dir/Test.logs wc -l) -eq 0 ]"

timelog $debug --dev "$dir" log ts 0800 1000 0 >/dev/null <<END
y
END
  code=$?
  logs=$(cat "$dir/Test.logs")
  amount_of_logs=$(< $dir/Test.logs 2>/dev/null wc -l)
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was not created" "[ $amount_of_logs -eq 1 ]"

  dec_time=$(echo "$logs" | grep -o '\[2\]' | grep -o '2')
  mil_time=$(echo "$logs" | grep -o '\{02:00\}' | grep -o '02:00')
  assertTrue "Decimal time was not 2" "[ $dec_time -eq 2 ]"
  assertTrue "HH:mm time was not 02:00" "[ $mil_time = '02:00' ]"
  deleteProject
}

testLogProjectWithNowAtEnd() {
  now_one_hour_ago=$(date +%H%M -d "$(($(date +%k)-1))$(date +%M)") # %k beacuse %H sometimes prepend 0, can't do this math expr then `$((08-07))`
  createProjectTest
timelog $debug --dev "$dir" log ts >/dev/null <<END
$now_one_hour_ago

0
y
END
  code=$?
  logs=$(cat "$dir/Test.logs")
  amount_of_logs=$(< $dir/Test.logs 2>/dev/null wc -l)
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was not created" "[ $amount_of_logs -eq 1 ]"

  dec_time=$(echo "$logs" | grep -o '\[1\]' | grep -o '1')
  mil_time=$(echo "$logs" | grep -o '\{01:00\}' | grep -o '01:00')
  assertTrue "Decimal time was not 1" "[ $dec_time -eq 1 ]"
  assertTrue "HH:mm time was not 01:00. $logs" "[ $mil_time = '01:00' ]"
  deleteProject
}

testLogProjectWithDate() {
  day="2017-01-01"
  nextDay="2017-01-02"
  nextDayAfterThat="2017-01-03"
  createProjectTest
timelog $debug --dev "$dir" log ts 0800 1000 0 >/dev/null --date "$day" <<END
y
END
  code=$?
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was not created when specifying custom date" "[ $( wc -l < $dir/Test.logs) -eq 1 ]"

timelog $debug --dev "$dir" log ts 0800 1100 0 --date "$nextDay" >/dev/null <<END
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

timelog $debug --dev "$dir" log ts 0800 1100 0 --date >/dev/null <<END
$nextDayAfterThat
y
END
  code=$?
  logs=$(cat "$dir/Test.logs")
  amount_of_logs=$(wc -l < $dir/Test.logs 2>/dev/null)
  dayThreeDate=$(echo "$logs" | grep -o "\/$nextDayAfterThat")
  assertTrue "Exit code was not 0" "[ $code -eq 0 ]"
  assertTrue "A log entry was not created when specifing date throught prompt. The amount of logs are: '$amount_of_logs'" "[ $amount_of_logs -eq 3 ]"
  assertTrue "Custom date was not '$nextDayAfterThat', '$dayThreeDate'" "[ '$dayThreeDate' = '/$nextDayAfterThat' ]"

  deleteProject
}

testLogProjectWithFaultyDate() {
  createProjectTest
timelog $debug --dev "$dir" log ts 0800 1000 0 >/dev/null --date "20asdwdawdqw" <<END
END
  code=$?
  assertTrue "Exit code was 0" "[ $code -ne 0 ]"
  assertTrue "A log entry was created when specifying a faulty custom date" "[ $( wc -l < $dir/Test.logs) -eq 0 ]"

  deleteProject
}

testLogWeekFirstOfJan() {
  # Tests the edge case 2017-01-01. If retrieving 'year-week-day_in_week' it should retrieve:
  # 2016-52-7
  day="2017-01-01"
  year_week_day_of_date="2016-52-7"
  createProjectTest
timelog $debug --dev "$dir" log ts 0800 1000 0 >/dev/null --date "$day" <<END
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

timelog $debug --dev "$dir" log ts 0840 1802 34 >/dev/null <<END
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
timelog $debug --dev "$dir" log ts 0840 1802 34 >/dev/null << END
y
END
  capture=$(timelog --dev "$dir" show logs ts $current_week)
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
  output=$(timelog --dev "$dir" show logs ts $current_week)
  patt="Nothing worked on week $current_week year $current_year for project Test"
  assertTrue "When nothing was logged, the output wasn't nothing '$output'" "[ '$output' = '$patt' ]"

  deleteProject
}

testShowWeeklyLogs() {
  createProjectTest
  mon="2017-08-14"
  tue="2017-08-15"
  wed="2017-08-16"
  thu="2017-08-17"
  fri="2017-08-18"
  week="33"
timelog $debug --dev "$dir" log ts 0800 1600 0 --date "$mon" >/dev/null << END
y
END
timelog $debug --dev "$dir" log ts 0800 1600 0 --date "$tue" >/dev/null << END
y
END
timelog $debug --dev "$dir" log ts 0800 1600 0 --date "$wed" >/dev/null << END
y
END
timelog $debug --dev "$dir" log ts 0800 1600 0 --date "$thu" >/dev/null << END
y
END
timelog $debug --dev "$dir" log ts 0800 1700 0 --date "$fri" >/dev/null << END
y
END
  # Overtime by 1 hour logged(friday). Should mention that the user has worked overtime in show logs
  stdout=$(timelog $debug --dev "$dir" show logs ts "$week")

  cmd=$(grep -q "[oO]vertime" <<< $stdout ; echo $?)
  assertTrue "Overtime of 1 hour was not mentioned" "[ $cmd -eq 0 ]"

  deleteProject
}

testMultipleprojects() {
  createProjectWithParams "Test1" "ts1" "40" "140" "kr"
  createProjectWithParams "Test2" "ts2" "40" "240" "kr"

  projects=$(timelog $debug --dev "$dir" list projects | grep -c '^[0-9]:')
  assertTrue "There was not two projects created: $projects counted" "[ $projects -eq 2 ]"

timelog $debug --dev "$dir" log >/dev/null << END
1
08:00
12:00
0
y
END

timelog $debug --dev "$dir" log >/dev/null << END
2
08:00
18:00
0
y
END

  logs=$(timelog $debug --dev "$dir" show logs ts1 $(date +%V))
  remaining_hours=$(echo "$logs" | grep -o 'You have 36 hours more to work')
  worked_hours=$(echo "$logs" | grep -o 'You have worked for 4 hours')
  assertTrue "Remaining hours was not 36" "[ ! -z '$remaining_hours' ]"
  assertTrue "Worked hours was not 4" "[ ! -z '$worked_hours' ]"

  logs=$(timelog $debug --dev "$dir" show logs ts2 $(date +%V))
  remaining_hours=$(echo "$logs" | grep -o 'You have 30 hours more to work')
  worked_hours=$(echo "$logs" | grep -o 'You have worked for 10 hours')
  assertTrue "Remaining hours was not 30" "[ ! -z '$remaining_hours' ]"
  assertTrue "Worked hours was not 10" "[ ! -z '$worked_hours' ]"

  deleteProject
  deleteProject
}

testLogStart() {
  createProjectWithParams "Test1" "ts1" "40" "140" "kr"

  now_in_one_hour=$(date +%H%M -d "$(($(date +%k)+1))$(date +%M)")
  timelog $debug --dev "$dir" start ts1 >/dev/null

timelog $debug --dev "$dir" log ts1>/dev/null << END
$now_in_one_hour
0
y
END

  logs=$(timelog $debug --dev "$dir" show logs ts1 $(date +%V))
  remaining_hours=$(echo "$logs" | grep -o 'You have 39 hours more to work')
  worked_hours=$(echo "$logs" | grep -o 'You have worked for 1 hours')
  assertTrue "Remaining hours was not 39" "[ ! -z '$remaining_hours' ]"
  assertTrue "Worked hours was not 1" "[ ! -z '$worked_hours' ]"

  deleteProject
}

testLogWithNote() {
  createProjectTest
  current_week=$(date +%V)
  note="Bash stuff, meeting at 9."
timelog $debug --dev "$dir" log ts >/dev/null << END
08:00
12:00
0
y
END
  assertTrue "The exit code of log creation without --note opt was not 0" "[ $? -eq 0 ]"

  output=$(timelog $debug --dev "$dir" show logs ts "$current_week")
  assertTrue "The exit code of show logs was not 0" "[ $? -eq 0 ]"

  # A day should display: "day: 4h / 04:00 " Notice the space at the end.
  # If a log entry with no --note, there should not be any more stuff beside what's listed above.
  end_of_day_line=$(echo "$output" | grep -o "04:00\ $")
  assertTrue "When creating a log entry with no note, note text was inserted " "[ ! -z '$end_of_day_line' ]"

timelog $debug --dev "$dir" log ts --note  >/dev/null << END
08:00
12:00
0
$note
y
END
  assertTrue "The exit code of log creation was not 0" "[ $? -eq 0 ]"

  output=$(timelog $debug --dev "$dir" show logs ts "$current_week")
  assertTrue "The exit code of log entry was not 0" "[ $? -eq 0 ]"

  log_note=$(echo "$output" | grep -o "$note")
  assertTrue "A note entry was not found when showing logs" "[ '$log_note' = '$note' ]"
  deleteProject
}

testLogNoteWithEmptyNote() {
  createProjectTest
  current_week=$(date +%V)
  note="Bash stuff, meeting at 9."
timelog --dev "$dir" log ts --note >/dev/null << END
08:00
12:00
0

y
END
  assertTrue "The exit code of log creation was not 0" "[ $? -eq 0 ]"

  output=$(timelog $debug --dev "$dir" show logs ts "$current_week")
  assertTrue "The exit code of log entry was not 0" "[ $? -eq 0 ]"

  end_of_day_line=$(echo "$output" | grep -o "04:00\ $")
  assertTrue "A note entry was found when showing logs" "[ ! -z '$end_of_day_line' ]"
  deleteProject
}

testDifferentInputFormats() {
  createProjectTest
  rgx="Decimal time: 2 Military time: 02:00"
  list=("[8,10] [800,1000] [0800,1000] [8.00,10.00] [8:00,10:00] [08:00,10:00]")

  for it in $list; do
    begin=$(echo "$it" | grep -o "[0-9]*\:*\.*[0-9]*," | sed 's#,##')
    end=$(echo "$it" | grep -o ",[0-9]*\:*\.*[0-9]*" | sed 's#,##')
entry=$(timelog $debug --dev "$dir" log ts "$begin" "$end" 0 <<END
n
END
)
    regexd=$(echo "$entry" | grep -o "$rgx")

    assertTrue "Begining time of '$begin' and end time of '$end' did not equal to the output time of 2/02:00:$entry" "[ '$regexd' = '$rgx' ]"
  done

  deleteProject
}

testCalculate() {
  regex="4/04:00"
  timelog $debug --dev "$dir" calc 0800 1200 0 | grep -q "$regex"
  code=$?
  assertTrue "Calculating 0800 1200 0 did not return '$regex'" "[ $code -eq 0 ]"

  timelog $debug --dev "$dir" calc 0800 1200 | grep -q "$regex"
  code=$?
  assertTrue "Calculating 0800 1200 with implicit break time 0 did not return '$regex'" "[ $code -eq 0 ]"
}

testCalculateInvalidTimes() {
  timelog $debug --dev "$dir" calc 080a0 1200 0 &>/dev/null
  code=$?
  assertTrue "Calculating 080a0 1200 0 returned an exit code of $code" "[ $code -eq 1 ]"

  timelog $debug --dev "$dir" calc 0800 12b00 &>/dev/null
  code=$?
  assertTrue "Calculating 0800 12b00 returned an exit code of $code" "[ $code -eq 1 ]"

  timelog $debug --dev "$dir" calc 0800 1200 2b &>/dev/null
  code=$?
  assertTrue "Calculating 0800 1200 2b returned an exit code of $code" "[ $code -eq 1 ]"
}

testUnknownArgument() {
  cmd=$(timelog asdf | grep "Unknown argument 'asdf'")
  assertTrue "Faulty command did not match the string 'Unknown argument'" "[ ! -z '$cmd' ]"
}

testPurge() {
  createProjectTest
  logProjectTest
timelog $debug --dev "$dir" --purge >/dev/null << END
timelog
END
  assertTrue "No log folder was deleted when purging" "[ ! -d '$dir' ]"
}

. shunit2-2.1.6/src/shunit2
end=$(date +%s)
diff=$((end-start))
minutes=$((diff/60%60))
seconds=$((diff%60))
echo "Unit tests took $minutes min(s), $seconds second(s) to run"
