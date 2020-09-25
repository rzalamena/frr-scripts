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

rm -rf Makefile Makefile.in aclocal.m4 alpine/APKBUILD autom4te.cache/ \
  */.deps/ */.dirstamp */.libs/ */*.{a,la,o} */*_clippy.c \
  bgpd/rfp-example/rfptest/*.o \
  bgpd/rfp-example/rfptest/{.deps,.libs,.dirstamp} \
  bgpd/rfp-example/librfp/*.{a,o} bgpd/rfp-example/librfp/{.deps,.dirstamp} \
  changelog-auto compile config.guess config.h config.h.in config.log \
  config.status config.sub config.version configure depcomp \
  doc/manpages/_build/ doc/user/_build/ install-sh libtool libtool.orig \
  ltmain.sh m4/libtool.m4 m4/ltoptions.m4 m4/ltsugar.m4 m4/ltversion.m4 \
  m4/lt~obsolete.m4 missing pkgsrc/*.sh python/__pycache__/ \
  python/clippy/__pycache__/ redhat/frr.spec snapcraft/snapcraft.yaml \
  solaris/Makefile stamp-h1 tools/frr tools/frrcommon.sh tools/frrinit.sh \
  tools/gen_northbound_callbacks tools/gen_yang_deviations \
  tools/permutations tools/watchfrr.sh \
  yang/ietf/{.deps,.dirstamp,.libs} yang/ietf/*.yang.{c,lo,o} \
  yang/*.yang.{c,lo} ylwrap

exit 0
