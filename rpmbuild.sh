#!/bin/sh

cd `dirname $0`
. ./build-common.sh
git clean -fdx

REBUILD_ALL=0	# set '1' if you want to rebuild all
UPDATE_INDEX=0	# set '1' if you want to update web-site

#
# Package Build
#
REBUILD_ALL=1	# set '1' if you want to rebuild all
grep -v '^#'  RPMVERSIONS| while read NAME PKGVER PKGHASH
do
  if [ "$NAME" = "nvme_strom" ]; then
    NFILES=`git ls-files docs/yum/*/nvme_strom-${PKGVER}${DIST}.${ARCH}.rpm 2>/dev/null | wc -l`
    if [ "$REBUILD_ALL" -ne 0 -o "$NFILES" -eq 0 ]; then
      ./build-nvme_strom.sh -i ${PKGVER} ${PKGHASH}
    fi
  elif [ "$NAME" = "pg_strom" ]; then
    NFILES=`git ls-files docs/yum/*/pg_strom-PG*-${PKGVER}${DIST}.${ARCH}.rpm 2>/dev/null | wc -l`
    if [ "$REBUILD_ALL" -ne 0 -o "$NFILES" -eq 0 ]; then
      ./build-pg_strom.sh -i ${PKGVER} ${PKGHASH}
    fi
  fi
done

#
# Update Web Site
#
if [ "$UPDATE_INDEX" -ne 0 ]; then
  ./update-index.sh
fi
exit 0
