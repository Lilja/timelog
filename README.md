[![Stories in Ready](https://badge.waffle.io/Lilja/timelog.png?label=ready&title=Ready)](https://waffle.io/Lilja/timelog?utm_source=badge)

# Timelog
CLI Utility to log time for different projects.

## Introduction
`Timelog` is used to as a CLI to log time for projects. The purpose of this tool is to have a terminal friendly tool that can easily track time(since terminals are fast and easy these days).

`Timelog` used to be a conversion tool that turned military time(`HH:mm`) to decimal time. I([@Lilja](https://github.com/lilja/)) worked for a company that used to log their time in decimal time(where working 8 hours and 30 minutes is not `8:30` but `8.5`. After a couple of iterations it turned from a conversion tool into a time logging tool.

This new repository with a full re-write has more tools and support to log multiple different projects.

### Installation
Clone the repository, then just add the `bin` directory to the `$PATH` by running:

`$ export PATH=$PATH:$PWD/bin/`

This is only temporary though. For being able to consistent run `timelog` wherever you are on the filesystem, please put the export inside a `.profile` or `.zprofile` if you're running `ZSH`.

### Usage
```
Timelog is a script written for keeping track of time for projects.
It will log time inputed via this CLI to store it to the disk in $HOME/.config/timelog/project_id.log.

Usage: timelog
 - log (project_id) (start time, end time, break time)
 - list project
 - show logs (project_id) (week)
 - delete project

For debugging, run with -v

To see examples, run timelog --examples
```

### Examples
`timelog create project`

to create a new project(interactively)

`timelog list projects`

to list current projects that are configured

`timelog log project (project id) (start time, end time, break time)`

to log project for `project id` using `start time` `end time` `break time`

`timelog show logs (project id) (week number)`

to show logs for a `project id` during `week number`

`timelog delete project`

to delete a project(interactively)
