#!/bin/sh

# ----------------------------------------------------------------
# This script build RPM package related to PG-Strom.
# We assume both of 'pg-strom' and 'nvme-strom' repositories, which have no
# local modification, are cloned under the '<gitroot>/rpmbuild' directory.
# ----------------------------------------------------------------
cd `dirname $0`

STROM_DIR="pg-strom"
NVME_DIR="nvme-strom"
PGSQL_VERS="9.6 10"

if rpmbuild -E '%{dist}' | grep -q '^\.el7'; then
  DISTRO="rhel7"
else
  echo "unknown Linux distribution"
  exit 1
fi

# ensure Git repository exists and up-to-date, with no local changes
test -e ${STROM_DIR}/.git || (echo "no pg-strom git repository"; exit 1)
test -e ${NVME_DIR}/.git  || (echo "no nvme-strom git repository"; exit 1)
if [ `(cd $STROM_DIR; git diff) | wc -l` -lt 0 ]; then
  echo "$STROM_DIR has local changes"
  exit 1
fi
if [ `(cd $NVME_DIR; git diff) | wc -l` -lt 0 ]; then
  echo "$NVME_DIR has local changes"
  exit 1
fi
#(cd pg-strom; git pull)  || (echo "failed on git-pull (pg-strom)"; exit 1)
#(cd nvme-strom; git pull)  || (echo "failed on git-pull (nvme-strom)"; exit 1)

# get version information
STROM_COMMIT=`cd pg-strom; git log | head -1 | awk '{print $2}'`
NVME_COMMIT=`cd nvme-strom; git log | head -1 | awk '{print $2}'`
STROM_VERSION=`cat pg-strom/Makefile |     \
               grep '^PGSTROM_VERSION=' |  \
               sed 's/^PGSTROM_VERSION=//g'`
if [ "_$1" = "_STABLE" ]; then
  STROM_RELEASE=1
else
  STROM_RELEASE="`date +%y%m%d`"
fi

NVME_VERSIONS_LIST=`cd nvme-strom; git tag -l | grep '^v[0-9]*\.[0-9]*\(\-[0-9]\+\)\?$'`

# get rpmbuild working directory
SPECDIR=`rpmbuild -E %{_specdir}`
SRCDIR=`rpmbuild -E %{_sourcedir}`
RPMDIR=`rpmbuild -E %{_rpmdir}`
SRPMDIR=`rpmbuild -E '%{_srcrpmdir}'`

#
# Build heterodb-swdc package
# -------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*

ARCH="noarch"
RPMFILE=`rpmspec -q files/heterodb-swdc.spec`.rpm
SRPMFILE=`echo $RPMFILE | sed "s/\.$ARCH\.rpm/.src.rpm/g"`
if [ "`git ls-files docs/yum/${DISTRO}-${ARCH}/${RPMFILE} | wc -l`" -eq 0 ] && \
   [ "`git ls-files docs/yum/${DISTRO}-source/${SRPMFILE} | wc -l`" -eq 0 ];
then
  cp -f files/heterodb-swdc.repo files/RPM-GPG-KEY-HETERODB ${SRCDIR}
  cp -f files/heterodb-swdc.spec ${SPECDIR}
  SPECFILE=${SPECDIR}/heterodb-swdc.spec

  rpmbuild -ba ${SPECFILE} || (echo "filed on rpmbuild"; exit 1)
  if [ -e "$SRPMDIR/${SRPMFILE}" -a -e "$RPMDIR/${ARCH}/${RPMFILE}" ];
  then
    cp -f "$SRPMDIR/${SRPMFILE}"       "docs/yum/${DISTRO}-source/" || exit 1
    cp -f "$RPMDIR/${ARCH}/${RPMFILE}" "docs/yum/${DISTRO}-${ARCH}/" || exit 1
    git add "docs/yum/${DISTRO}-source/" \
            "docs/yum/${DISTRO}-${ARCH}/" || exit 1
  else
    echo "RPM files missing. Build failed?"
    exit 1
  fi
fi
exit 

#
# Build pgstrom-kmod package
# ---------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*

ARCH=`uname -m`
for v in $NVME_VERSIONS_LIST;
do
  NVME_VERSION=`echo $v | sed -e 's/v//g' -e 's/-/ /g' | awk '{print $1}'`
  NVME_RELEASE=`echo $v | sed -e 's/v//g' -e 's/-/ /g' | awk '{print $2}'`
  if [ -z "$NVME_RELEASE" ]; then
    NVME_RELEASE=1
  fi
  RPMFILE="pgstrom-kmod-${NVME_VERSION}-${NVME_RELEASE}.${ARCH}.rpm"
  SRPMFILE="pgstrom-kmod-${NVME_VERSION}-${NVME_RELEASE}.src.rpm"
  DEBUGINFO="pgstrom-kmod-debuginfo-${NVME_VERSION}-${NVME_RELEASE}.${ARCH}.rpm"
  if [ "`git ls-files docs/yum/${DISTRO}-source/${SRPMFILE} | wc -l`" -gt 0 ] && \
     [ "`git ls-files docs/yum/${DISTRO}-${ARCH}/${RPMFILE} | wc -l`" -gt 0 ] && \
     [ "`git ls-files docs/yum/${DISTRO}-debuginfo/${DEBUGINFO} | wc -l`" -gt 0 ]
  then
    continue;
  fi

  # OK, build a package
  (cd nvme-strom; git archive --format=tar.gz \
                              --prefix=nvme_strom-${v}/ \
                              -o ${SRCDIR}/nvme_strom-${v}.tar.gr \
                              $v kmod utils)
  cp -f files/pgstrom-kmod.spec ${SPECDIR}

  rpmbuild -D "nvme_version ${NVME_VERSION}" \
           -D "nvme_release ${NVME_RELEASE}" \
           -ba ${SPECDIR}/pgstrom-kmod.spec || (echo "rpmbuild failed"; exit 1)

  if [ -e "$SRPMDIR/${SRPMFILE}" -a \
       -e "$RPMDIR/${ARCH}/${RPMFILE}" -a \
       -e "$RPMDIR/${ARCH}/${DEBUGINFO}" ];
  then
    cp -f "$SRPMDIR/${SRPMFILE}"         "docs/yum/${DISTRO}-source/"    || exit 1
    cp -f "$RPMDIR/${ARCH}/${RPMFILE}"   "docs/yum/${DISTRO}-${ARCH}/"   || exit 1
    cp -f "$RPMDIR/${ARCH}/${DEBUGINFO}" "docs/yum/${DISTRO}-debuginfo/" || exit 1
    git add "docs/yum/${DISTRO}-source/${SRPMFILE}"  \
            "docs/yum/${DISTRO}-${ARCH}/${RPMFILE}"  \
            "docs/yum/${DISTRO}-debuginfo/${DEBUGINFO}" || exit 1
  else
    echo "RPM File Missing. Build Failed?"
    exit 1
  fi
done




# pgstrom-PGxx package
make -C pg-strom tarball
cp pg-strom/pg_strom-${STROM_VERSION}.tar.gz ${SRCDIR}
(cd nvme-strom; git archive --format=tar.gz --prefix=nvme_strom-${STROM_VERSION}/ \
                            -o ${SRCDIR}/nvme_strom-${STROM_VERSION}.tar.gz \
                            HEAD kmod utils)
for pv in $PG_VERS;
do
  cp pgstrom-v2.spec ${SPECDIR}/pgstrom-PG${pv}.spec
  rpmbuild -D "strom_version ${STROM_VERSION}" \
           -D "strom_release ${STROM_RELEASE}" \
           -D "pgsql_version ${pv}" \
           -D "strom_commit  ${STROM_COMMIT}" \
           -D "nvme_commit   ${NVME_COMMIT}"  \
           -ba ${SPECDIR}/pgstrom-PG${pv}.spec
done

echo $STROM_COMMIT
echo $NVME_COMMIT
