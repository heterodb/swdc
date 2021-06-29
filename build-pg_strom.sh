#!/bin/sh
#
# Build script for nvme_strom
#
cd `dirname $0`
. ./build-common.sh

VERSION="$1"
GITHASH="$2"
GITDIR="pg-strom"

test -n "$VERSION" -a -n "$GITHASH" || abort "VERSION and GITHASH are missing"
test -e "$GITDIR/.git" || abort "'$GITDIR' is not git repository"
(cd "$GITDIR"; git pull) || abort "failed on git pull"
[ `(cd "$GITDIR"; git diff) | wc -l` -eq 0 ] || abort "$GITDIR has local changes"
(cd "$GITDIR"; git clean -fdx)
__PGSQL_VERSIONS=`(cd "$GITDIR"; git show $GITHASH:PG_VERSIONS)`
if [ -n "$__PGSQL_VERSIONS" ]; then
  PGSQL_VERSIONS="$__PGSQL_VERSIONS"
fi

mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*

set -- `echo "$VERSION" | tr '-' ' '`
STROM_VERSION=$1
STROM_RELEASE=$2
NO_DEBUG_SOURCE="--undefine=_debugsource_packages"

# xxx2arrow
SPECFILES="${SPECDIR}/pg2arrow.spec ${SPECDIR}/mysql2arrow.spec ${SPECDIR}/pcap2arrow.spec"

make -C "${GITDIR}" \
     PGSTROM_VERSION=${STROM_VERSION} \
     PGSTROM_RELEASE=${STROM_RELEASE} \
     PGSTROM_GITHASH=${GITHASH} rpm-arrow
RPMFILES=`rpmspec -q --rpms ${NO_DEBUG_SOURCE} ${SPECFILES}`
SRPMFILE=`rpmspec -q --srpm ${NO_DEBUG_SOURCE} ${SPECFILES} | sed "s/${ARCH}\$/src/g"`

for f in $RPMFILES
do
    FILE="$RPMDIR/${ARCH}/${f}.rpm"
    test -e "$FILE" || abort "missing RPM file ($FILE)"
    if [ -x ~/rpmsign.sh ]; then
      ~/rpmsign.sh "$FILE" || abort "failed on rpmsign.sh ($FILE)"
    fi
    if [ "$INSTALL" -ne 0 ]; then
        if echo "$f" | grep -q 'debuginfo'; then
            DEST="docs/yum/${DISTRO}-debuginfo"
	else
            DEST="docs/yum/${DISTRO}-${ARCH}"
	fi
	cp -f "$FILE" "$DEST"  || abort "failed on copy"
	git add "$DEST/$f.rpm" || abort "failed on git add"
    fi
done

for f in $SRPMFILE
do
    FILE="$SRPMDIR/${f}.rpm"
    test -e "$FILE" || abort "missing SRPM file ($FILE)"
    if [ -x ~/rpmsign.sh ]; then
      ~/rpmsign.sh "$FILE" || "failed on rpmsign.sh"
    fi
    if [ "$INSTALL" -ne 0 ]; then
	DEST="docs/yum/${DISTRO}-source"
	cp -f "$FILE" "$DEST"  || abort "failed on copy"
	git add "$DEST/$f.rpm" || abort "failed on git add"
    fi
done

# pg_strom module for each PG version
for PVER in $PGSQL_VERSIONS
do
  SPECFILE="${SPECDIR}/pg_strom-PG${PVER}.spec"
  make -C "${GITDIR}" \
      PG_CONFIG=/usr/pgsql-${PVER}/bin/pg_config \
      PGSTROM_VERSION=${STROM_VERSION} \
      PGSTROM_RELEASE=${STROM_RELEASE} \
      PGSTROM_GITHASH=${GITHASH} rpm

  RPMFILES=`rpmspec -q --rpms ${NO_DEBUG_SOURCE} ${SPECFILE}`
  SRPMFILE=`rpmspec -q --srpm ${NO_DEBUG_SOURCE} ${SPECFILE} | sed "s/${ARCH}\$/src/g"`
  for f in $RPMFILES;
  do
      FILE="$RPMDIR/${ARCH}/${f}.rpm"
      test -e "$FILE" || abort "missing RPM file ($FILE)"
      if [ -x ~/rpmsign.sh ]; then
	  ~/rpmsign.sh "$FILE" || abort "failed on rpmsign.sh"
      fi
      if [ "$INSTALL" -ne 0 ]; then
	  if echo "$f" | grep -q 'debuginfo'; then
              DEST="docs/yum/${DISTRO}-debuginfo"
	  else
              DEST="docs/yum/${DISTRO}-${ARCH}"
	  fi
	  cp -f "$FILE" "$DEST"  || abort "failed on copy"
	  git add "$DEST/$f.rpm" || abort "failed on git add"
      fi
  done

  for f in $SRPMFILE;
  do
      FILE="$SRPMDIR/${f}.rpm"
      test -e "$FILE" || abort "missing SRPM file"
      if [ -x ~/rpmsign.sh ]; then
	  ~/rpmsign.sh "$FILE" || "failed on rpmsign.sh"
      fi
      if [ "$INSTALL" -ne 0 ]; then
	  DEST="docs/yum/${DISTRO}-source"
	  cp -f "$FILE" "$DEST"  || abort "failed on copy"
	  git add "$DEST/$f.rpm" || abort "failed on git add"
      fi
  done

  if [ "${STROM_RELEASE}" -le 1 ]; then
      TARBALL="pg_strom-${STROM_VERSION}.tar.gz"
  else
      TARBALL="pg_strom-${STROM_VERSION}-${STROM_RELEASE}.tar.gz"
  fi
  cp -f ${SRCDIR}/${TARBALL} docs/tgz || abort "failed on copy"
  git add docs/tgz/${TARBALL} || "failed on git add"
done

exit 0
