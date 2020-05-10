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
Usage: $0
  [-h] [--asan] [--doc] [--fpm] [--help] [--jobs=NUMBER] [--snmp] [--systemd]

Options:
  --asan: build FRR with address sanitizer.
  --doc: configure FRR to enable documentation builds (requires sphinx).
  --fpm: build FRR with forwarding plane manager.
  --help or -h: this help message.
  --jobs: amount of parallel build jobs (defaults to $jobs).
  --snmp: build FRR with SNMP support.
  --systemd: build FRR with systemd support.
EOF
  exit 1
}

# Quit on errors.
set -e

# Set variables.
flags=()
jobs=2
scan_build=no

longopts='asan,doc,fpm,help,jobs:,scan-build,snmp,systemd'
shortopts='h'
options=$(getopt -u --longoptions "$longopts" "$shortopts" $*)
if [ $? -ne 0 ]; then
  usage
  exit 1
fi

set -- $options
while [ $# -ne 0 ]; do
  case "$1" in
    --asan)
      flags+=(--enable-address-sanitizer);
      shift
      ;;
    --doc)
      flags+=(--enable-doc)
      shift
      ;;
    --fpm)
      flags+=(--enable-fpm)
      shift
      ;;
    --jobs)
      jobs="$2"
      shift 2
      ;;
    --scan-build)
      scan_build=yes
      shift
      ;;
    --snmp)
      flags+=(--enable-snmp=agentx)
      shift
      ;;
    --systemd)
      flags+=(--enable-systemd)
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

# Bootstrap the configure file.
if [ ! -f configure ]; then
  ./bootstrap.sh
fi

if [ ! -f Makefile ]; then
  ./configure \
    ${flags[@]} \
    --enable-multipath=64 \
    --prefix=/usr \
    --localstatedir=/var/run/frr \
    --sysconfdir=/etc/frr \
    --enable-exampledir=/usr/share/doc/frr/examples \
    --sbindir=/usr/lib/frr \
    --enable-user=frr \
    --enable-group=frr \
    --enable-vty-group=frrvty \
    --enable-sharpd \
    --enable-configfile-mask=0640 \
    --enable-logfile-mask=0640 \
    --enable-dev-build \
    --with-pkg-git-version
fi

if [ $scan_build = 'no' ]; then
  make --jobs=$jobs --load-average=$jobs
else
  scan-build -maxloop 128 make --jobs=$jobs
fi

exit 0
