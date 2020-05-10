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

# Quit on errors.
set -e

# Set variables.
JOBS=${JOBS:-2}
ASAN=${ASAN:-no}
DOC=${DOC:-no}
FPM=${FPM:-no}
SNMP=${SNMP:-no}
SYSTEMD=${SYSTEMD:-no}
SCAN_BUILD=${SCAN_BUILD:-no}

# Bootstrap the configure file.
if [ ! -f configure ]; then
  ./bootstrap.sh
fi

# Configure FRR build.
FLAGS=()
if [ $ASAN = 'yes' ]; then
  FLAGS+=(--enable-address-sanitizer)
fi

if [ $DOC = 'yes' ]; then
  FLAGS+=(--enable-doc)
fi

if [ $FPM = 'yes' ]; then
  FLAGS+=(--enable-fpm)
fi

if [ $SNMP = 'yes' ]; then
  FLAGS+=(--enable-snmp=agentx)
fi

if [ $SYSTEMD = 'yes' ]; then
  FLAGS+=(--enable-systemd)
else
  FLAGS+=(--enable-systemd=no)
fi

if [ ! -f Makefile ]; then
  ./configure \
    ${FLAGS[@]} \
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

if [ $SCAN_BUILD = 'no' ]; then
  make -j$JOBS
else
  scan-build -maxloop 128 make -j$JOBS
fi
