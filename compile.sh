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
  [-h] [--asan] [--doc] [--fpm] [--grpc] [--help] [--jobs=NUMBER]
  [--minimal] [--scan-build] [--snmp] [--soft-clean] [--systemd]

Options:
  --asan: build FRR with address sanitizer.
  --tsan: build FRR with thread sanitizer.
  --doc: configure FRR to enable documentation builds (requires sphinx).
  --fpm: build FRR with forwarding plane manager.
  --grpc: enable gRPC support.
  --help or -h: this help message.
  --jobs: amount of parallel build jobs (defaults to $jobs).
  --minimal: don't build 'babeld', 'eigrpd', 'ldpd', 'nhrpd', 'pbrd', 'ripd',
             'ripngd' and 'vrrpd'.
  --scan-build: use clang static analyzer (compilation is way slower).
  --snmp: build FRR with SNMP support.
  --systemd: build FRR with systemd support.
EOF
  exit 1
}

# Quit on errors.
set -e

currentdir=$(pwd)
builddir="$currentdir/build"

# Set variables.
flags=()
jobs=$(expr $(nproc))
scan_build=no
default_flags=(
  --enable-multipath=64
  --prefix=/usr
  --localstatedir=/var/run/frr
  --sysconfdir=/etc/frr
  --sbindir=/usr/lib/frr
  --enable-user=frr
  --enable-group=frr
  --enable-vty-group=frrvty
  --enable-nhrpd
  --enable-sharpd
  --enable-configfile-mask=0640
  --enable-logfile-mask=0640
  --enable-dev-build
  --with-pkg-git-version
)

longopts='asan,doc,fpm,grpc,help,jobs:,minimal,scan-build,snmp,tsan,systemd'
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
      flags+=(--enable-doc-html)
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
      flags+=(--disable-babeld)
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
    --tsan)
      flags+=(--enable-thread-sanitizer);
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

# Include the defaults.
flags+=" ${default_flags[@]}"

# Bootstrap the configure file.
if [ ! -f configure ]; then
  echo "=> Running bootstrap ..."
  ./bootstrap.sh >/dev/null
fi

# Get into build outside of the source directory.
if [ ! -d "$builddir" ]; then
  mkdir -p "$builddir"
fi

cd "$builddir"

# Configure if not configured.
if [ ! -f Makefile ]; then
  echo "=> Running configure ..."
  ../configure 'CXXFLAGS=-O0 -g -ggdb3' ${flags[@]} >/dev/null
fi

# Build.
if [ $scan_build = 'no' ]; then
  make --jobs=$jobs
else
  scan-build make --jobs=$jobs
fi

exit 0
