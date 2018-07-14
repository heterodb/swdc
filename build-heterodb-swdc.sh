#!/bin/sh
#
# Build script for heterodb-swdc
#
cd `dirname $0`
. ./build-common.sh
#--------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*
SWDC_VERSION=`rpmspec --qf %{version} -q files/heterodb-swdc.spec`
SWDC_RELEASE=`rpmspec --qf %{release} -q files/heterodb-swdc.spec`
RPMFILE="`rpmspec --rpms -q files/heterodb-swdc.spec`.rpm"

cp -f files/heterodb-swdc.repo files/RPM-GPG-KEY-HETERODB ${SRCDIR}
cp -f files/heterodb-swdc.spec ${SPECDIR}
SPECFILE=heterodb-swdc.spec

rpmbuild -ba ${SPECDIR}/${SPECFILE} || (echo "filed on rpmbuild"; exit 1)
test -e "$RPMDIR/noarch/${RPMFILE}" || (echo "RPM files missing"; exit 1)
if [ -x ~/rpmsign.sh ];
then
  ~/rpmsign.sh "$RPMDIR/noarch/${RPMFILE}" || (echo "failed on rpmsign.sh"; exit 1)
fi
if [ "$INSTALL" -ne 0 ]; then
  cp -f "$RPMDIR/noarch/${RPMFILE}" "docs/yum/${DISTRO}-${ARCH}/" || exit 1
  git add "docs/yum/${DISTRO}-${ARCH}/${RPMFILE}" || exit 1
else
  echo "NOTICE: installation onto docs/ was skipped"
fi
exit 0
