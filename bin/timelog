#!/bin/bash

# Author Erik Lilja, github@lilja
log_path="$HOME/.config/timelogs"

# Increased log level = more debugy
log_level=0

function logger_debug {
  [ $log_level -ge 1 ] && echo "$(date +%Y-%m-%d\ %H:%M:%S) DEBUG $1"
}

function usage {
    #read -r -d '' VAR <<- EOM
    #Timelog is a script written for keeping track of time for projects.
    #It will log time inputed via this CLI to store it to the disk in $HOME/.config/timelog/.log.

    #Usage: $(basename $0)
           #[-p|--project] name
           #[times: \d{2}:{0,1}\d{2}]*
    #EOM
    echo "Usage"
    exit 0
}

function list_projects {
  files=$(ls $log_path/def/ 2>/dev/null)
  it=1
  for file_name in $files; do
    file=$(cat $log_path/def/$file_name)
    name=$(echo "$file" | grep -o 'project_name\ *\=\ *.*' | cut -d '=' -f 2- | awk '{$1=$1};1')
    short=$(echo "$file" | grep -o 'short_hand_name\ *\=\ *.*' | cut -d '=' -f 2- | awk '{$1=$1};1')
    printf "${it}: $name [$short]\n"
    it=$((it+1))
  done
}

function get_all_projects {
  all_projects=$(list_projects)
}

function parse_timestamp {
  echo $1 | sed 's/[a-z][A-Z][:]//g'
}

function test_timestamp {
  k=$(echo $1 | grep -oP '\d{2}:*\d{2}')
  logger_debug "test_timestamp: '$1' => '$k'"
  [ $k == $1 ] && exit 0 || exit 1
}

function test_break {
  k=$(echo $1 | grep -oP '\d*')
  logger_debug "test_break: '$1' => '$k'"
  [ $k == $1 ] && exit 0 || exit 1
}

function does_project_exist {
  if [ -f "$log_path/def/$1" ]; then exit 0; else exit 1; fi
}

function delete_project {
  if [ ! -z "$all_projects" ]; then
      echo "The projects"
      echo -e "$all_projects"

      echo "Which project do you want deleted?"
      read proj

      echo "Are you sure you want to delete it? (y/n)"
      read ans
      if [ "$ans" = "y" ]; then
        logger_debug "Sending $proj as param info to project info"
        proj=$(get_project_from_all_projects $proj)
        logger_debug "Matched '$proj'"
        [ -f "$log_path/def/$proj" ] && {
            rm "$log_path/$proj.logs" ;
            rm "$log_path/def/$proj" ;
            logger_debug "Deleting logs '$proj_name.logs'" ;
            logger_debug "Deleting definition 'def/$proj_name'" ;
            all_projects=$(list_projects) ;
        } || {
          echo "No such project file: '$log_path/def/$proj'" ;
        }
      fi
  else
      echo "No projects, can't delete nothing that doesn't exist!"
  fi
}

function get_project_from_all_projects {
  echo "$all_projects" | grep "^$1" | grep -o ':\ .*\[' | sed 's#^:\ *\(.*\)\[$#\1#' | sed 's/*//;s/ *$//'
}

function describe_project {
  echo "Creating a new project"
  echo "What would you like to call it?"
  read project_name

  echo "What is a short-hand name you would call it?"
  echo "(This is used to specify which project you would like to submit time to)"
  read project_short

  echo "(Optional) What does the project pay(per hour)?"
  read money_per_hour

  [ ! -f "$log_path/def/$project_short" ] && {
      logger_debug "Initalizing project $project_name" ;
      touch $log_path/def/$project_name
      echo "project_name=$project_name" > $log_path/def/$project_name ;
      echo "short_hand_name=$project_short" >> $log_path/def/$project_name ;
      echo "money_per_hour=$money_per_hour" >> $log_path/def/$project_name ;
  }
}

function set_default_project {
  proj_short=$1
  sed 's#default_project\ *\=\ *.*#default_project=$proj_short/g' '$log_path/config'
  logger_debug "Setting default project to $1"
}

function init_program {
  mkdir -p $log_path; logger_debug "Created $log_path";
  mkdir $log_path/def/; logger_debug "Created $log_path/def";
  touch $log_path/config
  echo "default_project=" > $log_path/config
  logger_debug "Initalizing the program. Creating folder and config."
}

function get_default_project {
  cat $log_path/config | grep -o 'default_project\ *\=\ *.*' | cut -d '=' -f 2- | awk '{$1=$1};1'
}

function get_project {
  default=$(get_default_project)
  # $1 = project, if $1 = empty then $default. If $1 != default then default. else $1
  if [ -z "$1" ]; then echo $default;
  elif [ "$1" != "$default" ]; then echo $1;
  else; echo $default ; fi
}

function is_program_inited {
  if [ -f $log_path/config ] ; then exit 0
  else
      logger_debug "The program is not initialized"
      exit 1
  fi
}

function write_to_disk {
  # $1 = project_name
  # $2 = decimal time
  # $3 = Start time
  # $4 = End time
  # $5 = Break minutes
  project=$1
  dec_time=$2
  start_time=$3
  end_time=$4
  break_min=$5
  note=$6
  date=$(date +%Y-%m-%d)
  week_date=$(date +%Y-%V-%d)
  proj_log_path=$(get_log_path_for_project $project)
  entry="$week_date/$date [$dec_time] ($start_time $end_time $break_min) [$note]"
  echo "$entry" >> $proj_log_path
  logger_debug "Writing log entry $entry to $proj_log_path"
}

function get_log_path_for_project {
  echo "$log_path/$1.logs"
}

function time_to_decimal_time {
  # t1 = $1
  # t1h = the hour in 24h-format
  # t1m = the hour in 24h-format

  # t2 = $2
  # t2h = the hour in 24h-format
  # t2m = the hour in 24h-format

  # t3 = $3
  # t1h = the hour in 24h-format
  t1h=$1
  t1m=$2
  t2h=$3
  t2m=$4
  t3m=$5

  if  [ "$t1h" -ge 0 ] ||
      [ "$t1h" -le 23 ] ||
      [ "$t2h" -ge 0 ] ||
      [ "$t2h" -le 23 ]
  then
    # Remove leading zeros
	t1h=${t1h#0}
	t1m=${t1m#0}
	t2h=${t2h#0}
    t2m=${t2m#0}

    # Minimize stuff

    # We want to subtract hours here.
    # 0830 & 1600 => 0000 & 0830
    # 0725 & 1210 => 0000 & 0445

    if [ "$t1m" -gt "$t2m" ]  # 0830, 1600.
    then
        # t2's minute is lesser. Add 60 to it and subtrace t2h by one.
        t2h=$((t2h-=1))
        t2m=$((t2m+60))
    fi # t1m -gt t2m

    # Should be good to go, do the subtraction
    t2h=$((t2h-t1h))
    t2m=$((t2m-t1m))

    # t1h, t1m not relevant any more.
    unset t1h
    unset t1m

    # Fix third argument
    if [ ! -z "$t3m" ] && [ "$t3m" -gt 0 ] # is not empty or negative
    then
        # Wrap it up with an if-statement checking if t3m/60 is larger than t2h. If so, break is larger than end time.
        tbh=$((t3m/60))
        total_min=$((t2h*60+(t2m)))

        if [ "$t3m" -lt "$total_min" ] # is it even a valid procedure?
        then
            if [ "$t2m" -gt "$t3m" ] # if there is room to just subtract. (h1=0445; h2=45;h2-h1)=>0400
            then
                t2m=$((t2m-t3m))
            else
                # Since t2m is lower than t3m, borrow hours from t2h and then subtract
                temp=$(echo "$t3m")
                while [ "$t3m" -gt "$t2m" ]
                do
                    t2h=$((t2h-=1))
                    t2m=$((t2m+60))
                done
                t2m=$((t2m-temp))
            fi # t3m -lt total_min
        fi # t3m -lt total_min
    fi # ! -z t3m && t3m -gt 0
    total_start_minutes=$((10#$t1h*60 + 10#$t1m))
    total_minutes=$((10#$t2h*60 + 10#$t2m))

    dectime=$(awk "BEGIN {print ($t2h+($t2m/60))}")
    echo $dectime
    exit 0
  fi
  logger_debug "Could not compute: $t1h $t1m $t2h $t2m $t3m"
  exit 1
}

function calculate_time_with_parameters {
  # start_time = $1
  # stop_time = $2
  # break_minutes = $3
  # project = $4

  # TODO: Parsing.
  # Make the examples:
  # 0900 => h:09, m:00
  # 09:00 => h:09, m:00
  # 25:60 => Raise error

  t1h=$(echo "${1:0:2}")
  t1m=$(echo "${1:2:4}")
  t2h=$(echo "${2:0:2}")
  t2m=$(echo "${2:2:4}")
  t3m=$3
  project=$4

  echo "times: $t1h:$t1m, $t2h:$t2m, $t3m"
  dec_time=$(time_to_decimal_time $t1h $t1m $t2h $t2m $t3m)
  write_to_disk $project $dec_time $1 $2 $3

}

# main
while [[ $# -ge 1 ]]; do
  case $1 in
    create)
      case "$2" in
        project)
          logger_debug "About to describe project project"
          describe_project
          new_project="y"
          shift ; shift
        ;;
        *)
          usage
        ;;
      esac
    ;;
    show)
      case "$2" in
        logs)
          ''
        ;;
      esac
    ;;
    delete)
      case "$2" in
        project)
          delete_project="y"
          shift ; shift
        ;;
        *)
          shift
        ;;
      esac
    ;;
    -sdf|--set-default-project)
      set_default_project $1
      logger_debug "Setting project to $1"
      shift; shift
    ;;
    -p|--projects)
      proj_name=$2
      shift; shift
    ;;
    --note)
      note=$2
      shift; shift
    ;;
    log)
      case "$2" in
        project)
          proj_name=$3
          shift ; shift
        ;;
      esac

      start_time=$(parse_timestamp $2)
      k="$(test_timestamp $2)"
      [ $? -eq 0 ] || { echo "$2 is not a number!"; usage; }

      stop_time=$(parse_timestamp $3)
      k="$(test_timestamp $3)"
      [ $? -eq 0 ]  || { echo "$3 is not a number!"; usage; }

      break_minutes=$4
      k="$(test_break $4)"

      [ $? -eq 0 ]  || { echo "$4 is not a number!"; usage; }

      logger_debug "Inputs: Start:$2 End:$3 Break:$4"
      logger_debug "Parsed: Start:$start_time End:$stop_time Break:$break_minutes"

      shift; shift; shift
    ;;
    -v)
      logger_debug "Debug is toggled"
      log_level=1
      shift
    ;;
    list)
      case "$2" in
        projects)
          list_projects="y"
          shift ; shift
        ;;
        *)
          echo "amg"
          shift
        ;;
      esac
    ;;
    *)
      logger_debug "SHIFTING"
      shift
    ;;
  esac
done

# Get the project to work on
if [ -z "$uninstall" ]; then
  k=$(is_program_inited)
  if [ $? -eq 1 ]; then init_program; fi

  logger_debug "Project input: $proj_name"
  proj_name=$(get_project $proj_name)
  logger_debug "Project is set as $proj_name"
  get_all_projects
fi

if [ ! -z "$list_projects" ]; then
    if [ ! -z "$all_projects" ]; then
      echo "The projects are:"
      echo "$all_projects"
    else
      echo "No projects!"
    fi
    exit 0
fi

if [ ! -z "$delete_project" ];
then
  delete_project
  exit 0
elif [ ! -z $start_time ]; then
  if [ -z "$proj_name" ]; then
    if [ ! -z "$all_projects" ]; then
      echo "You did not specify a project to log time for."
      echo "Here are the projects you have created:"
      echo "$all_projects"
      echo "What project are you trying to log time for?"
      read prompt_new_proj_name
      proj_name=$prompt_new_proj_name
      proj_name=$(get_project_from_all_projects $prompt_new_proj_name)
    else
      echo "No projects. Please create a project."
      exit 1
    fi
  fi
  calculate_time_with_parameters $start_time $stop_time $break_minutes $proj_name
fi

