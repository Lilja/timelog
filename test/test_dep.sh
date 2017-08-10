#!/bin/bash
dir_path=${1:-"$PWD"}
tgz_path=${2:-/tmp/shunit2-2.1.6.tgz}

file_name="shunit2-2.1.6"

if [ ! -d "$dir_path/$file_name" ]; then
  curl -L "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/shunit2/shunit2-2.1.6.tgz" -o "$tgz_path"
  tar zxf "$tgz_path" -C "$dir_path"
fi
