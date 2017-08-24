[![Build Status](https://travis-ci.org/Lilja/timelog.svg?branch=master)](https://travis-ci.org/Lilja/timelog)
[![Stories in Progress](https://img.shields.io/waffle/label/Lilja/timelog/in%20progress.svg](https://waffle.io/Lilja/timelog?utm_source=badge)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/bc1b73b95b364475965ec09b444de618)](https://www.codacy.com/app/Lilja/timelog?utm_source=github.com&utm_medium=referral&utm_content=Lilja/timelog&utm_campaign=badger)
[![codecov](https://codecov.io/gh/Lilja/timelog/branch/master/graph/badge.svg)](https://codecov.io/gh/Lilja/timelog)

# Timelog
CLI Utility to log time for different projects.

## Introduction
`Timelog` is a CLI program to log time for your every day projects. Whether it's for professional use or a hobby project, it's easy to track how many hours and minutes you have logged for different projects of different weeks.

The purpose of this tool is to have a terminal friendly tool that can easily track time(since terminals are fast and easy these days).

`Timelog` used to be a conversion tool that turned military time(`HH:mm`) to decimal time. I([@Lilja](https://github.com/lilja/)) worked for a company that used to log their time in decimal time(where working 8 hours and 30 minutes is not `8:30` but `8.5`. After a couple of iterations it turned from a conversion tool into a time logging tool.

This new repository with a full re-write has more tools and support to log multiple different projects.
### Demo
![ttygif](demo.gif)
This gif shows a simple demonstration that creates a project, logs the time between 08:00-16:00 with 45 minutes of break time, logs time for yesterday with similar times and finally shows a weekly report that shows various statistics.

Created with [ttygif](https://github.com/icholy/ttygif)

### Installation
Clone the repository, then just add the `bin` directory to the `$PATH` by running:

```shell
$ export PATH=$PATH:$PWD/bin/
```

This is only temporary though. For being able to consistent run `timelog` wherever you are on the filesystem, please put the export inside a `.profile` or `.zprofile` if you're running `ZSH`.

### Uninstallation
Run `timelog --purge` and then delete the source files.

### Usage
```
Timelog is a script written for keeping track of time for projects.
It will log time inputed via this CLI to store it to the disk in $HOME/.config/timelog/project_id.log.

Usage: timelog
 - log (project_id) (start time) (end time) (break time) [--note] [--date timestamp]
 - view (project_id) (week) [year] [--raw]
 - project
   - create
   - list
   - delete
 - start (project_id)
 - calc start time, end time, break time
 - --help
 - --version
 - --purge

For debugging, run with -v

To see examples, run timelog --examples
All arguments in parenthesis will be prompted to the user if not supplied
All arguments in brackets are optional
```

### Commands
`timelog project create`

to create a new project(interactively)

`timelog project list`

to list current projects that are configured

`timelog log (project id) (start time) (end time) (break time) [--note] [--date]`

to log project for `project id` using `start time` `end time` `break time`.

It's possible to log a note for the entry with `--note`. A prompt will later let you fill in text.

It's also possible to log something that is different from today. Specify a date with `--date` like `--date 2017-01-01` to log for the `1st of Jan, 2017`.

`timelog view (project id) (week) (year) | [--raw]`

to show logs for a `project id` during `week number` and `year` or specify `--raw` to open up the logs with `less`

`timelog project delete`

to delete a project(interactively)

`timelog calc start time end time [break time]`

to calculate a period between start time, end time and break time

`timelog --purge`

to purge or remove all configuration and logs made

### Dependecies
`sed` tested with `4.4`

`grep` tested with `3.0`

`less` tested with `481`

`bash` tested with `4.4.12(1)-release`

`awk` tested with `4.1.4`

`cut` tested with `8.26`

`tr` tested with `8.26`


shell that can execute `[[ ]]` if-statements



### Examples
Creating a project
```
timelog project create
Creating a new project
What would you like to call it?
  Test
What is an ID that you would call it?
(This is used to specify which project you would like to submit time to)
  ts
What does the project pay(per hour)?
  50
What is the target hours per week?
  40
What is the currency paid?
  kr
```

Listing the projects that are created
```
timelog project list
The projects are:
1: Test [ts]
```

Logging time for a project
```
timelog log ts 08:00 15:30 45
Times: 08:00, 15:30, 45. Decimal time: 6.75 Military time: 06:45
Save this to Test project log? y/n
y
```

Showing logs for a project given a week

```
timelog view ts 28
Days worked for week 28
Monday: 6.75h / 06:45
------
You have worked for 6.75 hours at the following days: Monday
You have 33.25 hours out of 40 hours giving you an estimate of
8.3125 hours for 4 more days.
You have earned 337.5 kr pre-tax!

```

Deleting a project
```
timelog project delete
The projects
1: Test [ts]
Which project do you want deleted?
1
Are you sure you want to delete it? (y/n)
y
```

To purge all configuration
```
timelog --purge
Are you sure that you want to purge timelog? There is no undo in doing this.
Type out: 'timelog' to delete all configuration and logs that you have created."
timelog
Removing ~/.config/timelog
```

### Testing
`timelog` uses [shunit2](https://github.com/kward/shunit2) for unit tests. In order to run the unit tests, please use the `test_dep.sh` script to download the dependency

### Documentation
`log_path=$HOME/.config/timelogs`

The program will default to `$log_path` for init configuration and log storage.

The `def` folder contains project definition which is used as meta-data for the project.

`config` file contains program wide configuration. The program will create a default config-file if it does not exist in `$log_path`

`${project_name}.logs` contains the log entries for the days that the user has created logs.

The program will read from `$log_path` and list the projects that are created if `project id` has not been specified
#### Argument documentation
##### Create project
`timelog project create`

`project create` is keywords.

The program will prompt for input after it has been invoked.

---

##### List projects
`timelog project list`

`project list` is keywords.

---
##### Log project
`timelog log (project id) (start_time) (end time) (break time) [--note]`

`log` is a keyword.

`project id` Optional/prompted. Is an ID that was specified during the creation. No need to specify a `project_id` if there is only one project created.

`start time` Optional/prompted. Is a timestamp to begin logging time from. `8, 8:00, 800, 08:00, 0800` is all valid and mean the same thing.

`end time` Optional/prompted. Is a timestamp to end logging time. `8, 8:00, 800, 08:00, 0800` is all valid and mean the same thing.

`break time` Optional/prompted. Is the total amount of minutes to deduct from the calculation. Enter `0` for no breaks.

`--note` Optional. Able to process text from the prompt to make a note that is visible in the `show logs` command.

`--date` Optional. Possible to log for a different date, specify with `--date timestamp` where `timestamp` is something the program `date` can format.

---
##### View logs
`timelog view (project id) (week) (year) | (--raw)`

`show logs` is keywords.

`project id` Optional/prompted. Is an ID that was specified during the creation.

`week` Optional/prompted. The week to view logs from.

`year` Optional. The year to view logs from. Defaults to the current year.

`--raw` Optional. If the user wants to open the log file for a project in `less`. Mostly used to debug.

---
##### Edit logs
Debug tool

`timelog edit logs`

`edit logs` is keywords.

First, checks if `xdg-open` is a command. If so, will run it. Otherwise, it will check for `$EDITOR`. If neither are present, fall back to `vim`.

---
##### Set start time for log
`timelog start (project_id)`

`start` is a keyword.

`project id` Optional/prompted. Is an ID that was specified during the creation.

Writes the time down onto the filesystem and is later read when logging.

##### Delete project
`timelog project delete`

`project delete` is keywords.

The program will prompt for which project to delete.

---
##### Calculate time duration
`timelog calc start time end time [break time]`

`calc` is a keyword.

`start time` Required. Is a timestamp to begin logging time from. `8, 8:00, 800, 08:00, 0800` is all valid and mean the same thing.

`end time` Required. Is a timestamp to begin logging time from. `8, 8:00, 800, 08:00, 0800` is all valid and mean the same thing.

`break time` Optional. Is the total amount of minutes to deduct from the calculation. Enter `0` for no breaks.

---
##### Purge project
`timelog --purge`

`--purge` is a keyword.

The program will prompt for a string that needs to be typed out, after doing that there is no going back unless you have made backups.
