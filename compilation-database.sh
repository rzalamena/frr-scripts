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

currentdir=$(pwd)
build_dir="$currentdir/build-dev"

# Set variables.
flags=()
jobs=$(nproc)
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
  --enable-fpm
  --enable-grpc
)

longopts='help,jobs:'
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
    -h | --help)
      usage
      shift
      ;;

    --) shift ;;
    *) echo "unhandled argument '$1'" 2>&1 ; exit 1 ;;
  esac
done

bear_bin=$(which bear)
if [ -z $bear_bin ]; then
  echo "'bear' was not found in your PATH"
  exit 1
fi

# Include the defaults.
flags+=" ${default_flags[@]}"

# Bootstrap the configure file.
if [ ! -f configure ]; then
  ./bootstrap.sh
fi

# Always build out-of-tree.
if [ "$build_dir" ]; then
  mkdir -p $build_dir
fi

cd $build_dir

# Configure if not configured.
if [ ! -f Makefile ]; then
  echo "=> configure..."
  ../configure ${flags[@]} >/dev/null || \
    log_fatal "failed to configure"
fi

# Build.
echo "=> make clean ..."
make clean >/dev/null

cd ..
echo "=> make --jobs=$jobs ..."
bear make -C $build_dir --jobs=$jobs || \
  log_fatal "failed to compile"

exit 0
