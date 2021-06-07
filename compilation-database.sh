#!/bin/bash
#
# Copyright (C) 2021 Rafael F. Zalamena
# All rights reserved.
# 
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
# 
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

usage() {
  cat <<EOF
Usage: $0
  [-h] [--help] [--jobs=NUMBER] [--soft-clean]

Options:
  --help or -h: this help message.
  --jobs: amount of parallel build jobs (defaults to $jobs).
  --soft-clean: don't clean everything just the necessary to run autotools
EOF
  exit 1
}

log_fatal() {
  local msg="$1"
  echo "$msg" >&2
  exit 1
}

# Quit on errors.
set -e

currentdir=$(pwd)
build_dir="$currentdir/dev"

# Set variables.
flags=()
jobs=$(expr $(nproc) + 1)
scan_build=no
grpc=no
soft_clean=no
default_flags=(
  --enable-multipath=64
  --prefix=/usr
  --localstatedir=/var/run/frr
  --sysconfdir=/etc/frr
  --enable-exampledir=/usr/share/doc/frr/examples
  --sbindir=/usr/lib/frr
  --enable-user=frr
  --enable-group=frr
  --enable-vty-group=frrvty
  --enable-nhrpd
  --enable-sharpd
  --enable-configfile-mask=0640
  --enable-logfile-mask=0640
  --enable-dev-build
)

longopts='help,jobs:,soft-clean'
shortopts='h'
options=$(getopt -u --longoptions "$longopts" "$shortopts" $*)
if [ $? -ne 0 ]; then
  usage
  exit 1
fi

set -- $options
while [ $# -ne 0 ]; do
  case "$1" in
    --jobs)
      jobs="$2"
      shift 2
      ;;
    --soft-clean)
      soft_clean=yes
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

which bear >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  echo "'bear' was not found in your PATH"
  exit 1
fi

# Include the defaults.
flags+=" ${default_flags[@]}"

if [ "$soft_clean" = 'yes' ]; then
  rm -rf aclocal.m4 autom4te.cache compile config.guess config.h.in{,~} \
    config.sub depcomp install-sh ltmain.sh m4/ac m4/libtool.m4 \
    m4/ltoptions.m4 m4/ltsugar.m4 m4/ltversion.m4 m4/lt~obsolete.m4 \
    missing test-driver ylwrap configure Makefile.in $build_dir/Makefile
fi

# Bootstrap the configure file.
if [ ! -f configure ]; then
  ./bootstrap.sh
fi

# Always build out-of-tree.
if [ "$build_dir" ]; then
  mkdir -p "$build_dir"
fi

cd dev

# Configure if not configured.
if [ ! -f Makefile ]; then
  echo "=> configure ..."
  ../configure ${flags[@]} >/dev/null || \
    log_fatal "failed to configure"
fi

# Build.
if [ $scan_build = 'no' ]; then
  echo "=> make clean ..."
  make clean >/dev/null
  echo "=> make --jobs=$jobs --load-average=$jobs ..."
  bear make --jobs=$jobs --load-average=$jobs >/dev/null || \
    log_fatal "failed to compile"
fi

mv -v compile_commands.json ..

exit 0
