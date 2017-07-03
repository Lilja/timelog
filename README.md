[![Stories in Ready](https://badge.waffle.io/Lilja/timelog.png?label=ready&title=Ready)](https://waffle.io/Lilja/timelog?utm_source=badge)

# Timelog
## CLI Utility to log time for different projects.

### Installation
Clone the repository, then just add the `bin` directory to the `$PATH` by running:

`$ cd bin/ && export PATH=$PATH:$PWD/bin/`

This is only temporary though. For being able to consistent run `timelog` wherever you are on the filesystem, please put the export inside a `.profile` or `.zprofile` if you're running `ZSH`.

### Usage
```
Timelog is a script written for keeping track of time for projects.
It will log time inputed via this CLI to store it to the disk in $HOME/.config/timelog/.log.

Usage: timelog
 * log (project_id) (start time, end time, break time)
 * list project
 * show logs (project_id)(week)
 * delete project

To see examples, run $(basename $0) --examples
```

### Examples
`timelog create project`
to create a new project(interactivly)

`timelog list projects`
to list current projects that are configured

`timelog log project (project id) (start time, end time, break time)`
to log project for `project id` using `start time` `end time` `break time`

`timelog show logs (project id) (week number)`
to show logs for a `project id` during `week number`

`timelog delete project`
to delete a project(interactivly)
