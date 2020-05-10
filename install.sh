#!/bin/sh
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
Usage: $0 [-h] [--help] [--systemd]

Options:
  --help or -h: this help message.
  --systemd: install FRR systemd files.
EOF
  exit 1
}

# Quit on errors.
set -e

longopts='help,systemd'
shortopts='h'
options=$(getopt -u --longoptions "$longopts" "$shortopts" $*)
if [ $? -ne 0 ]; then
  usage
  exit 1
fi

systemd=no

set -- $options
while [ $# -ne 0 ]; do
  case "$1" in
    --systemd)
      systemd=yes
      shift
      ;;
    -h | --help)
      usage
      shift
      ;;

    --) shift ;;
    *) echo "unhandled argument '$1'" 2>&1 ; exit 1 ;;
  esac
done

# Install FRR binaries.
make install

# Copy manual part.
if [ ! -d /var/log/frr ]; then
  install -m 775 -o frr -g frr -d /var/log/frr
fi

if [ ! -d /etc/frr ]; then
  install -m 775 -o frr -g frrvty -d /etc/frr
  install -m 640 -o frr -g frrvty tools/etc/frr/vtysh.conf /etc/frr/vtysh.conf
  install -m 640 -o frr -g frr tools/etc/frr/frr.conf /etc/frr/frr.conf
  install -m 640 -o frr -g frr tools/etc/frr/daemons.conf /etc/frr/daemons.conf
  install -m 640 -o frr -g frr tools/etc/frr/daemons /etc/frr/daemons
fi

if [ $systemd = 'yes' -a ! -f /etc/systemd/system/frr.service ]; then
  install -m 644 tools/frr.service /etc/systemd/system/frr.service
fi
