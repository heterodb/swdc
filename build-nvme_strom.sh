#!/bin/sh
#
# Build script for nvme_strom
#
cd `dirname $0`
. ./build-common.sh

VERSION="$1"
GITHASH="$2"
GITDIR="nvme-strom"

test -n "$VERSION" -a -n "$GITHASH" || abort "VERSION and GITHASH are missing"
test -e "$GITDIR/.git" || abort "'$GITDIR' is not git repository"
(cd "$GITDIR"; git pull) || abort "failed on git pull"
[ `(cd "$GITDIR"; git diff) | wc -l` -eq 0 ] || abort "$GITDIR has local changes"
(cd "$GITDIR"; git clean -fdx)

#--------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*

set -- `echo "$VERSION" | tr '-' ' '`
STROM_VERSION=$1
STROM_RELEASE=$2

make -C "$GITDIR" \
    STROM_VERSION=${STROM_VERSION} \
    STROM_RELEASE=${STROM_RELEASE} \
    STROM_GITHASH=${GITHASH} rpm || \
    abort "failed on 'make rpm' for '${STROM_VERSION}-${STROM_RELEASE}' on '${GITHASH}'"

RPMFILES=`rpmspec --rpms -q ${SPECDIR}/nvme_strom.spec`
for f in $RPMFILES;
do
  test -e "$RPMDIR/${ARCH}/${f}.rpm" || abort "missing RPM file"
  if [ -x ~/rpmsign.sh ]; then
    ~/rpmsign.sh "$RPMDIR/${ARCH}/${f}.rpm" || abort "failed on rpmsign.sh"
  fi
  if [ "$INSTALL" -ne 0 ]; then
    if echo "$f" | grep -q 'debuginfo'; then
      DEST="docs/yum/${DISTRO}-debuginfo"
    else
      DEST="docs/yum/${DISTRO}-${ARCH}"
    fi
    cp -f $RPMDIR/${ARCH}/${f}.rpm ${DEST} || exit 1
    git add ${DEST}/${f}.rpm || exit 1
  fi
done
exit 0
