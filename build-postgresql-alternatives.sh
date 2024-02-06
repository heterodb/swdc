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

SPECFILE=postgresql-alternatives.spec
mkdir -p ${SPECDIR} && cp -f files/${SPECFILE} ${SPECDIR}

rpmbuild -ba ${SPECDIR}/${SPECFILE} || (echo "filed on rpmbuild"; exit 1)
test -e "$RPMDIR/noarch/${RPMFILE}" || (echo "RPM files missing"; exit 1)
rpm --addsign "$RPMDIR/noarch/${RPMFILE}" || (echo "failed on rpmsign"; exit 1)
rpm --addsign "$SRPMDIR/${SRPMFILE}" || (echo "failed on rpmsign"; exit 1)

if [ "$INSTALL" -ne 0 ]; then
  cp -f "$RPMDIR/noarch/${RPMFILE}" "docs/yum/${DISTRO}-noarch" || exit 1
  cp -f "$SRPMDIR/${SRPMFILE}" "docs/yum/${DISTRO}-source" || exit 1
  git add "docs/yum/${DISTRO}-noarch/${RPMFILE}" \
          "docs/yum/${DISTRO}-source/${SRPMFILE}" || exit 1
else
  echo "NOTICE: installation onto docs/ was skipped"
fi
exit 0
