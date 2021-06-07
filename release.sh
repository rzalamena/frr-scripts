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
Usage: $0 [-h] [--help] [--jobs=NUMBER]

Options:
  --help or -h: this help message.
  --jobs: amount of parallel build jobs (defaults to $jobs).
EOF
  exit 1
}

# Quit on errors.
set -e

current_dir=$(pwd)
build_dir="$current_dir/release"

# Set variables.
flags=()
jobs=$(expr $(nproc) + 1)
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
  --enable-doc
  --enable-doc-html
  --enable-fpm
  --enable-configfile-mask=0640
  --enable-logfile-mask=0640
  --with-pkg-git-version
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
    --systemd)
      flags+=(--enable-systemd=yes)
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
  echo "=> bootstrap ..."
  ./bootstrap.sh >/dev/null
fi

# Get into build outside of the source directory.
if [ ! -d "$build_dir" ]; then
  mkdir -p "$build_dir"
fi

cd "$build_dir"

# Configure if not configured.
if [ ! -f Makefile ]; then
  echo "=> configure ..."
  ../configure ${flags[@]} >/dev/null
fi

# Build.
echo "=> make --jobs=$jobs ..."
make --jobs=$jobs --load-average=$jobs >/dev/null

# Install in temporary directory.
install_dir=$(mktemp -d)
sudo make DESTDIR="$install_dir" install
if [ -f "$build_dir/tools/frr.service" ]; then
  echo '=> systemd unit file exists, adding it to installation'
  sudo install -o root -g root -m 0644 -D -v \
    "$build_dir/tools/frr.service" \
    "$install_dir/etc/systemd/system/frr.service"
fi

# Generate tarball
tar -czf frr-$(git rev-parse --short HEAD).tgz -C "$install_dir" etc usr

exit 0
