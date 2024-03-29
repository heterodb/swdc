#!/bin/sh
#
# Build script for heterodb-swdc
#
cd `dirname $0`
. ./build-common.sh
#--------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*
RPMFILE="`rpmspec --rpms -q files/heterodb-swdc.spec`.rpm"
ARCH_LIST=x86_64

mkdir -p ${SRCDIR} && cp -f files/heterodb-swdc.repo \
			    files/RPM-GPG-KEY-HETERODB ${SRCDIR}
mkdir -p ${SPECDIR} && cp -f files/heterodb-swdc.spec ${SPECDIR}
SPECFILE=heterodb-swdc.spec

rpmbuild -ba ${SPECDIR}/${SPECFILE} || (echo "filed on rpmbuild"; exit 1)
test -e "$RPMDIR/noarch/${RPMFILE}" || (echo "RPM files missing"; exit 1)
rpm --addsign "$RPMDIR/noarch/${RPMFILE}" || (echo "unable to add signature"; exit 1)

if [ "$INSTALL" -ne 0 ]; then
  cp -f "$RPMDIR/noarch/${RPMFILE}" "docs/yum/${DISTRO}-noarch/" || exit 1
  git add "docs/yum/${DISTRO}-noarch/${RPMFILE}" || exit 1
else
  echo "NOTICE: installation onto docs/ was skipped"
fi
exit 0
