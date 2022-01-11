#!/bin/sh
#
# Build script for nvme_strom
#
cd `dirname $0`
. ./build-common.sh

VERSION="$1"
GITHASH="$2"
GITDIR="nvme-strom"

test -n "$VERSION" -a -n "$GITHASH" || abort "usage: `basename $0` VERSION GITHASH"
test -e "$GITDIR/.git" || abort "'$GITDIR' is not git repository"
(cd "$GITDIR"; git pull) || abort "failed on git pull"
[ `(cd "$GITDIR"; git diff) | wc -l` -eq 0 ] || abort "$GITDIR has local changes"
(cd "$GITDIR"; git clean -fdx)

#--------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*

set -- `echo "$VERSION" | tr '-' ' '`
KMOD_VERSION=$1
KMOD_RELEASE=$2
test -z "$KMOD_VERSION" && abort "version is missing"
test -z "$KMOD_RELEASE" && KMOD_RELEASE=1

make -C "$GITDIR" \
    HDB_VERSION=${KMOD_VERSION} \
    HDB_RELEASE=${KMOD_RELEASE} \
    HDB_GITHASH=${GITHASH} rpm || \
    abort "failed on 'make rpm' for '${KMOD_VERSION}-${KMOD_RELEASE}' on '${GITHASH}'"

SPECFILES="${SPECDIR}/heterodb-extra.spec ${SPECDIR}/heterodb-kmod.spec"
# if [ "${DISTRO}" = "rhel7" ]; then
#   SPECFILES="$SPECFILES ${SPECDIR}/heterodb-kmod.spec"
# fi

RPMFILES=`rpmspec --rpms -q ${SPECFILES} --undefine=_debugsource_packages`
for f in $RPMFILES;
do
  test -e "$RPMDIR/${ARCH}/${f}.rpm" || abort "missing RPM file"
  if [ -x ~/rpmsign.sh ]; then
    ~/rpmsign.sh "$RPMDIR/${ARCH}/${f}.rpm" || abort "failed on rpmsign.sh"
  fi
  if [ "$INSTALL" -ne 0 ]; then
    if ! echo "$f" | grep -q 'debuginfo'; then
      DEST="docs/yum/${DISTRO}-${ARCH}"
      cp -f $RPMDIR/${ARCH}/${f}.rpm ${DEST} || exit 1
      git add ${DEST}/${f}.rpm || exit 1
      echo "installed '${f}' --> '${DEST}'"
    fi
  fi
done
exit 0
