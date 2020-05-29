#!/bin/bash
#
# Copyright 2020 Rafael F. Zalamena
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

usage() {
  cat <<EOF
Usage: $0 [-hj] [--help] [--json] node command arg...

Options:
  --help or -h: this help message.
  --json or -j: JSON format the output using 'python -m json.tool'.

Examples:
  $0 r1 vtysh -c 'show running-config'
  $0 --json r1 vtysh -c 'show bfd peers json'
EOF
  exit 1
}

# Quit on errors.
set -e

# Variables.
sudo=
if [ $(id -u) -ne 0 ]; then
  sudo=sudo
fi

# Handle arguments.
longopts='help,json'
shortopts='hj'

args=''
parameters=''
json_format=''

# Filter arguments: they are only valid in the beginning.
while [ $# -ne 0 ]; do
  case $1 in
    -*)
      args="$args $1"
      shift
      ;;
    *)
      for arg in $(seq 1 $#); do
        var=$(eval echo \$$arg)
        case $var in
          *\ *)
            parameters="$parameters '$var'"
            ;;

          *)
            parameters="$parameters $var"
            ;;
        esac
      done
      break
      ;;
  esac
done

# Process options.
options=$(getopt -u --longoptions "$longopts" "$shortopts" $args)
if [ $? -ne 0 ]; then
  usage
  exit 1
fi

# Put parameters back.
options="$options $parameters"

set -- $options
while [ $# -ne 0 ]; do
  case "$1" in
    -j | --json)
      json_format='| python -m json.tool'
      shift
      ;;
    -h | --help)
      usage
      shift
      ;;

    --) shift ; break ;;
    *) echo "unhandled argument '$1'" 2>&1 ; exit 1 ;;
  esac
done

if [ $# -lt 2 ]; then
  usage
fi

node=$1
shift

target=$( \
  $sudo lsns --type net \
  | grep 'mininet' \
  | grep "$node" \
  | sed -r 's/ +/ /g' \
  | cut -d ' ' -f 4)

if [ -z $target ]; then
  echo "No namespaces with node '$node' found"
  exit 1
fi

$sudo nsenter --target $target --net --mount -- sh -c "$* $json_format"

exit 0
