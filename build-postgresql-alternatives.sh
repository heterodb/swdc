#!/bin/sh
#
# Build script for heterodb-swdc
#
cd `dirname $0`
. ./build-common.sh
#--------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*
VERSION=`rpmspec --qf %{version} -q files/postgresql-alternatives.spec`
RELEASE=`rpmspec --qf %{release} -q files/postgresql-alternatives.spec`
RPMFILE="`rpmspec --rpms -q files/postgresql-alternatives.spec`.rpm"
ARCH_LIST=x86_64

SPECFILE=postgresql-alternatives.spec
cp -f files/${SPECFILE} ${SPECDIR}

rpmbuild -ba ${SPECDIR}/${SPECFILE} || (echo "filed on rpmbuild"; exit 1)
test -e "$RPMDIR/noarch/${RPMFILE}" || (echo "RPM files missing"; exit 1)
if [ -x ~/rpmsign.sh ];
then
  ~/rpmsign.sh "$RPMDIR/noarch/${RPMFILE}" || (echo "failed on rpmsign.sh"; exit 1)
fi
if [ "$INSTALL" -ne 0 ]; then
  for ARCH in ${ARCH_LIST}
  do
    cp -f "$RPMDIR/noarch/${RPMFILE}" "docs/yum/${DISTRO}-${ARCH}/" || exit 1
    git add "docs/yum/${DISTRO}-${ARCH}/${RPMFILE}" || exit 1
  done
else
  echo "NOTICE: installation onto docs/ was skipped"
fi
exit 0
