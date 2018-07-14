#!/bin/sh
#
# Build script for nvme_strom
#
cd `dirname $0`
. ./build-common.sh

VERSION="$1"
GITHASH="$2"
GITDIR="pg-strom"
PGSQL_VERSIONS="9.6 10"

test -n "$VERSION" -a -n "$GITHASH" || abort "VERSION and GITHASH are missing"
test -e "$GITDIR/.git" || abort "'$GITDIR' is not git repository"
(cd "$GITDIR"; git pull) || abort "failed on git pull"
[ `(cd "$GITDIR"; git diff) | wc -l` -eq 0 ] || abort "$GITDIR has local changes"

#--------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*

set -- `echo "$VERSION" | tr '-' ' '`
STROM_VERSION=$1
STROM_RELEASE=$2
test -n "$STROM_VERSION" -a -n "$STROM_RELEASE" || \
    abort "pg_strom: wrong version(${STROM_VERSION}) and release(${STROM_RELEASE})"

if [ ${#STROM_RELEASE} -le 1 ]; then
  TGZ_VERSION="${STROM_VERSION}"
else
  TGZ_VERSION="${STROM_VERSION}-${STROM_RELEASE}"
fi
STROM_TARBALL="pg_strom-${TGZ_VERSION}"

for pgver in $PGSQL_VERSIONS
do
  PVNUM=`echo $pgver | sed 's/\.//g'`
  SPECFILE="pg_strom-PG${PVNUM}.spec"
  (cat files/pgstrom-v2.spec | \
     sed -e "s/@@STROM_VERSION@@/${STROM_VERSION}/g" \
         -e "s/@@STROM_RELEASE@@/${STROM_RELEASE}/g" \
         -e "s/@@STROM_TARBALL@@/${STROM_TARBALL}/g" \
         -e "s/@@PGSQL_VERSION@@/${pgver}/g";
   cd $GITDIR; git show ${GITHASH}:CHANGELOG) > ${SPECDIR}/${SPECFILE}
  cp files/systemd-pg_strom.conf ${SRCDIR}
  RPMFILES=`rpmspec --rpms -q ${SPECDIR}/${SPECFILE}`
  SRPMFILE=`rpmspec --srpm -q ${SPECDIR}/${SPECFILE} | sed "s/${ARCH}\$/src.rpm/g"`

  env PATH=/usr/pgsql-${pgver}/bin:$PATH \
    make -C $GITDIR tarball PGSTROM_VERSION="${TGZ_VERSION}" PGSTROM_GITHASH="${GITHASH}"
  cp -f "$GITDIR/${STROM_TARBALL}.tar.gz" ${SRCDIR}
  env PATH=/usr/pgsql-${pgver}/bin:$PATH \
    rpmbuild -ba ${SPECDIR}/${SPECFILE} || abort "rpmbuild failed"

  for f in $RPMFILES;
  do
    test -e "$RPMDIR/${ARCH}/${f}.rpm" || abort "missing RPM file"
    if [ -x ~/rpmsign.sh ]; then
      ~/rpmsign.sh "$RPMDIR/${ARCH}/${f}.rpm" || abort "failed on rpmsign.sh"
    fi
  done
  test -e "$SRPMDIR/${SRPMFILE}" || abort "missing SRPM file"
  if [ -x ~/rpmsign.sh ]; then
    ~/rpmsign.sh "$SRPMDIR/${SRPMFILE}" || abort "failed on rpmsign.sh"
  fi

  if [ "$INSTALL" -ne 0 ]; then
    for f in $RPMFILES;
    do
      if echo "$f" | grep -q 'debuginfo'; then
	DEST="docs/yum/${DISTRO}-debuginfo"
      else
        DEST="docs/yum/${DISTRO}-${ARCH}"
      fi
      cp -f "$RPMDIR/${ARCH}/${f}.rpm" "$DEST" || abort "failed on copy"
      git add "${DEST}/${f}.rpm" || abort "failed on git add"
    done
    cp -f "$SRPMDIR/${SRPMFILE}" "docs/yum/${DISTRO}-source"
    git add "docs/yum/${DISTRO}-source/${SRPMFILE}"
    cp -f "${SRCDIR}/${STROM_TARBALL}.tar.gz" "docs/tgz"
    git add "docs/tgz/${STROM_TARBALL}.tar.gz"
  fi
done
exit 0
