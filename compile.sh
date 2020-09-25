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
  [-h] [--asan] [--bear] [--doc] [--fpm] [--grpc] [--help] [--jobs=NUMBER]
  [--minimal] [--scan-build] [--snmp] [--systemd]

Options:
  --asan: build FRR with address sanitizer.
  --bear: use 'bear' to generate compile_commands.json database.
  --doc: configure FRR to enable documentation builds (requires sphinx).
  --fpm: build FRR with forwarding plane manager.
  --grpc: enable gRPC support.
  --help or -h: this help message.
  --jobs: amount of parallel build jobs (defaults to $jobs).
  --minimal: don't build `babeld`, `eigrpd`, `ldpd`, `nhrpd`, `pbrd`, `ripd`,
             `ripngd` and `vrrpd`.
  --scan-build: use clang static analyzer (compilation is way slower).
  --snmp: build FRR with SNMP support.
  --systemd: build FRR with systemd support.
EOF
  exit 1
}

# Quit on errors.
set -e

# Set variables.
bear=no
flags=()
jobs=2
scan_build=no

longopts='asan,bear,doc,fpm,grpc,help,jobs:,minimal,scan-build,snmp,systemd'
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
    --bear)
      bear=yes
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
    --grpc)
      flags+=(--enable-grpc)
      shift
      ;;
    --jobs)
      jobs="$2"
      shift 2
      ;;
    --minimal)
      flags+=(--disable-babel)
      flags+=(--disable-eigrpd)
      flags+=(--disable-ldpd)
      flags+=(--disable-nhrpd)
      flags+=(--disable-pbrd)
      flags+=(--disable-ripd)
      flags+=(--disable-ripngd)
      flags+=(--disable-vrrpd)
      shift
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

if [ $bear = 'yes' -a $scan_build = 'yes' ]; then
  echo "'bear' at the same time as 'scan-build'."
  exit 1
fi

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
  if [ $bear = 'no' ]; then
    make --jobs=$jobs --load-average=$jobs
  else
    bear make --jobs=$jobs --load-average=$jobs
  fi
else
  scan-build -maxloop 128 make --jobs=$jobs
fi

exit 0
