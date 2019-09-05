#!/bin/sh
#
# Build script for heterodb-swdc
#
cd `dirname $0`
. ./build-common.sh
#--------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*
__SPECFILE=files/postgresql-alternatives.spec
VERSION=`rpmspec --qf %{version} -q ${__SPECFILE}`
RELEASE=`rpmspec --qf %{release} -q ${__SPECFILE}`
RPMFILE=`rpmspec --rpms -q ${__SPECFILE}`.rpm
SRPMFILE=`rpmspec --srpm -q ${__SPECFILE} | sed "s/\.noarch\$/\.src.rpm/g"`

ARCH_LIST=x86_64

SPECFILE=postgresql-alternatives.spec
cp -f files/${SPECFILE} ${SPECDIR}

rpmbuild -ba ${SPECDIR}/${SPECFILE} || (echo "filed on rpmbuild"; exit 1)
test -e "$RPMDIR/noarch/${RPMFILE}" || (echo "RPM files missing"; exit 1)
if [ -x ~/rpmsign.sh ];
then
  ~/rpmsign.sh "$RPMDIR/noarch/${RPMFILE}" || (echo "failed on rpmsign.sh"; exit 1)
  ~/rpmsign.sh "$SRPMDIR/${SRPMFILE}" || (echo "failed on rpmsign.sh"; exit 1)
fi
if [ "$INSTALL" -ne 0 ]; then
  for ARCH in ${ARCH_LIST}
  do
    cp -f "$RPMDIR/noarch/${RPMFILE}" "docs/yum/${DISTRO}-${ARCH}" || exit 1
    git add "docs/yum/${DISTRO}-${ARCH}/${RPMFILE}" || exit 1
    cp -f "$SRPMDIR/${SRPMFILE}" "docs/yum/${DISTRO}-source" || exit 1
    git add "docs/yum/${DISTRO}-source/${SRPMFILE}" || exit 1
  done
else
  echo "NOTICE: installation onto docs/ was skipped"
fi
exit 0
