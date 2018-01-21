#!/bin/sh

# ----------------------------------------------------------------
# This script build RPM package related to PG-Strom.
# We assume both of 'pg-strom' and 'nvme-strom' repositories, which have no
# local modification, are cloned under the '<gitroot>/rpmbuild' directory.
# ----------------------------------------------------------------
cd `dirname $0`
git clean -fdx

STROM_DIR="pg-strom"
NVME_DIR="nvme-strom"
PGSQL_VERSIONS="9.6 10"

ANY_NEW_PACKAGES=0

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
(cd pg-strom; git pull)  || (echo "failed on git-pull (pg-strom)"; exit 1)
(cd nvme-strom; git pull)  || (echo "failed on git-pull (nvme-strom)"; exit 1)

# get version information
STROM_VERSION=`cat pg-strom/Makefile |     \
               grep '^PGSTROM_VERSION=' |  \
               sed 's/^PGSTROM_VERSION=//g'`
if [ "_$1" = "_STABLE" ]; then
  STROM_RELEASE=1
else
  STROM_RELEASE="`date +%y%m%d`"
fi

STROM_VERSIONS_LIST=`cd pg-strom; git tag -l | grep '^v[0-9]*\.[0-9]*\(\-[0-9]\+\)\?$'`
NVME_VERSIONS_LIST=`cd nvme-strom; git tag -l | grep '^v[0-9]*\.[0-9]*\(\-[0-9]\+\)\?$'`

# get rpmbuild working directory
SPECDIR=`rpmbuild -E %{_specdir}`
SRCDIR=`rpmbuild -E %{_sourcedir}`
RPMDIR=`rpmbuild -E %{_rpmdir}`
SRPMDIR=`rpmbuild -E '%{_srcrpmdir}'`

PUBLIC_TGZDIR="docs/tgz"

#
# Build heterodb-swdc package
# -------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*

ARCH="noarch"
SWDC_VERSION=`rpmspec --qf %{version} -q files/heterodb-swdc.spec`
SWDC_RELEASE=`rpmspec --qf %{release} -q files/heterodb-swdc.spec`
RPMFILE="heterodb-swdc-${SWDC_VERSION}-${SWDC_RELEASE}.${ARCH}.rpm"
SRPMFILE="heterodb-swdc-${SWDC_VERSION}-${SWDC_RELEASE}.src.rpm"
if [ "`git ls-files docs/yum/${DISTRO}-${ARCH}/${RPMFILE} | wc -l`" -eq 0 ] && \
   [ "`git ls-files docs/yum/${DISTRO}-source/${SRPMFILE} | wc -l`" -eq 0 ];
then
  cp -f files/heterodb-swdc.repo files/RPM-GPG-KEY-HETERODB ${SRCDIR}
  cp -f files/heterodb-swdc.spec ${SPECDIR}
  SPECFILE=${SPECDIR}/heterodb-swdc.spec

  rpmbuild -ba ${SPECFILE} || (echo "filed on rpmbuild"; exit 1)
  if [ -e "$SRPMDIR/${SRPMFILE}" -a \
       -e "$RPMDIR/${ARCH}/${RPMFILE}" ];
  then
    if [ -x ~/rpmsign.sh ];
    then
      ~/rpmsign.sh "$SRPMDIR/${SRPMFILE}" || exit 1
      ~/rpmsign.sh "$RPMDIR/${ARCH}/${RPMFILE}" || exit 1
    fi
    cp -f "$SRPMDIR/${SRPMFILE}"       "docs/yum/${DISTRO}-source/" || exit 1
    cp -f "$RPMDIR/${ARCH}/${RPMFILE}" "docs/yum/${DISTRO}-${ARCH}/" || exit 1
    git add "docs/yum/${DISTRO}-source/${SRPMFILE}" \
            "docs/yum/${DISTRO}-${ARCH}/${RPMFILE}" || exit 1
    ANY_NEW_PACKAGES=1
  else
    echo "RPM files missing. Build failed?"
    exit 1
  fi
fi

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
    NVME_TARBALL="${NVME_VERSION}"
  else
    NVME_TARBALL="${NVME_VERSION}-${NVME_RELEASE}"
  fi
  RPMFILE=`rpmspec -D "nvme_version ${NVME_VERSION}" \
                   -D "nvme_release ${NVME_RELEASE}" \
                   --rpms -q files/nvme-strom.spec | grep -v debuginfo`.rpm
  DEBUGINFO=`rpmspec -D "nvme_version ${NVME_VERSION}" \
                     -D "nvme_release ${NVME_RELEASE}" \
                     --rpms -q files/nvme-strom.spec | grep debuginfo`.rpm
  if [ "`git ls-files docs/yum/${DISTRO}-${ARCH}/${RPMFILE} | wc -l`" -gt 0 ] && \
     [ "`git ls-files docs/yum/${DISTRO}-debuginfo/${DEBUGINFO} | wc -l`" -gt 0 ]
  then
    continue;
  fi
  # OK, build a package
  (cd nvme-strom; git archive --format=tar.gz \
                              --prefix=nvme-strom-${NVME_TARBALL}/ \
                              -o ${SRCDIR}/nvme-strom-${NVME_TARBALL}.tar.gz \
                              $v kmod utils)
  cp -f files/nvme-strom.spec ${SPECDIR}
  cat files/nvme-strom.dkms.conf | \
    sed -e "s/%%NVME_STROM_VERSION%%/${NVME_VERSION}/g" > ${SRCDIR}/dkms.conf

  rpmbuild -D "nvme_version ${NVME_VERSION}" \
           -D "nvme_release ${NVME_RELEASE}" \
           -D "nvme_tarball ${NVME_TARBALL}" \
           -ba ${SPECDIR}/nvme-strom.spec || (echo "rpmbuild failed"; exit 1)

  if [ -e "$RPMDIR/${ARCH}/${RPMFILE}" -a \
       -e "$RPMDIR/${ARCH}/${DEBUGINFO}" ];
  then
    if [ -x ~/rpmsign.sh ];
    then
      ~/rpmsign.sh "$RPMDIR/${ARCH}/${RPMFILE}" || exit 1
      ~/rpmsign.sh "$RPMDIR/${ARCH}/${DEBUGINFO}" || exit 1
    fi
    cp -f "$RPMDIR/${ARCH}/${RPMFILE}"   "docs/yum/${DISTRO}-${ARCH}/"   || exit 1
    cp -f "$RPMDIR/${ARCH}/${DEBUGINFO}" "docs/yum/${DISTRO}-debuginfo/" || exit 1
    git add "docs/yum/${DISTRO}-${ARCH}/${RPMFILE}"  \
            "docs/yum/${DISTRO}-debuginfo/${DEBUGINFO}" || exit 1
    ANY_NEW_PACKAGES=1
  else
    echo "RPM File Missing. Build Failed?"
    exit 1
  fi
done

#
# Build pgstrom-PGxx packages
# -----------------------------
ARCH=`uname -m`
for sv in $STROM_VERSIONS_LIST
do
  STROM_VERSION=`echo $sv | sed -e 's/^v//g' -e 's/\-/ /g' | awk '{print $1}'`
  STROM_RELEASE=`echo $sv | sed -e 's/^v//g' -e 's/\-/ /g' | awk '{print $2}'`
  if [ -z "$STROM_RELEASE" ]; then
    STROM_RELEASE=1
    STROM_TARBALL="pg-strom-${STROM_VERSION}"
  else
    STROM_TARBALL="pg-strom-${STROM_VERSION}-${STROM_RELEASE}"
  fi
  EXTRA=`rpmbuild -E '%{dist}'`

  for pv in $PGSQL_VERSIONS
  do
    PVNUM=`echo $pv | sed 's/\.//g'`
    RPMFILE=`rpmspec -D "strom_version ${STROM_VERSION}" \
                     -D "strom_release ${STROM_RELEASE}" \
                     -D "pgsql_version ${pv}" \
                     --rpms -q files/pgstrom-v2.spec | grep -v debuginfo`.rpm
    DEBUGINFO=`rpmspec -D "strom_version ${STROM_VERSION}" \
                       -D "strom_release ${STROM_RELEASE}" \
                       -D "pgsql_version ${pv}" \
                       --rpms -q files/pgstrom-v2.spec | grep debuginfo`.rpm
    SRPMFILE=`rpmspec -D "strom_version ${STROM_VERSION}" \
                      -D "strom_release ${STROM_RELEASE}" \
                      -D "pgsql_version ${pv}" \
                      --srpm -q files/pgstrom-v2.spec | sed "s/\\.${ARCH}\\\$/.src/g"`.rpm
    if [ "`git ls-files docs/yum/${DISTRO}-${ARCH}/${RPMFILE} | wc -l`" -gt 0 ] && \
       [ "`git ls-files docs/yum/${DISTRO}-debuginfo/${DEBUGINFO} | wc -l`" -gt 0 ] && \
       [ "`git ls-files docs/yum/${DISTRO}-source/${SRPMFILE} | wc -l`" -gt 0 ];
    then
      continue;
    fi
    # OK, build a package
    make -C pg-strom tarball PGSTROM_VERSION=$sv
    cp -f "pg-strom/${STROM_TARBALL}.tar.gz" ${SRCDIR}
    cp -f "files/pgstrom-v2.spec" "${SPECDIR}/pgstrom-PG${PVNUM}.spec"
    rpmbuild -D "strom_version ${STROM_VERSION}" \
             -D "strom_release ${STROM_RELEASE}" \
             -D "strom_tarball ${STROM_TARBALL}" \
             -D "pgsql_version ${pv}" \
             -ba ${SPECDIR}/pgstrom-PG${PVNUM}.spec || (echo "rpmbuild failed"; exit 1)
    echo "$SRPMDIR/${SRPMFILE}"
    echo "$RPMDIR/${ARCH}/${RPMFILE}"
    echo "$RPMDIR/${ARCH}/${DEBUGINFO}"

    if [ -e "$SRPMDIR/${SRPMFILE}" -a \
         -e "$RPMDIR/${ARCH}/${RPMFILE}" -a \
         -e "$RPMDIR/${ARCH}/${DEBUGINFO}" ];
    then
      if [ -x ~/rpmsign.sh ]; then
        ~/rpmsign.sh "$SRPMDIR/${SRPMFILE}"         || exit 1
        ~/rpmsign.sh "$RPMDIR/${ARCH}/${RPMFILE}"   || exit 1
        ~/rpmsign.sh "$RPMDIR/${ARCH}/${DEBUGINFO}" || exit 1
      fi
      cp -f "$SRPMDIR/${SRPMFILE}"         "docs/yum/${DISTRO}-source/"    || exit 1
      cp -f "$RPMDIR/${ARCH}/${RPMFILE}"   "docs/yum/${DISTRO}-${ARCH}/"   || exit 1
      cp -f "$RPMDIR/${ARCH}/${DEBUGINFO}" "docs/yum/${DISTRO}-debuginfo/" || exit 1
      cp -f "${SRCDIR}/${STROM_TARBALL}.tar.gz" "${PUBLIC_TGZDIR}" || exit 1
      git add "docs/yum/${DISTRO}-source/${SRPMFILE}"  \
              "docs/yum/${DISTRO}-${ARCH}/${RPMFILE}"  \
              "docs/yum/${DISTRO}-debuginfo/${DEBUGINFO}" \
              "${PUBLIC_TGZDIR}/${STROM_TARBALL}.tar.gz" || exit 1
      ANY_NEW_PACKAGES=1
    else
      echo "RPM File Missing. Build Failed?"
      exit 1
    fi
  done
done

#
# Post rpmbuild steps
#
if [ $ANY_NEW_PACKAGES -ne 0 ]; then
  # update yum repository
  for d in docs/yum/*/repodata;
  do
    createrepo --simple-md-filenames --update `dirname $d`
  done

  HTML=`mktemp`
  cat<<EOF>>$HTML
<html>
<head>
<title>HeteroDB Software Distribution Center</title>
</head>
<body>
<h1>HeteroDB Software Distribution Center</h1>
<hr>
<h2>yum repository configurations</h2>
<ul>
EOF
  # update index file (heterodb-swdc)
  for x in `ls docs/yum/*-noarch/heterodb-swdc-*.noarch.rpm`
  do
    ALINK=`echo $x | sed 's/^docs/./g'`
    FNAME=`basename $x`
    echo "<li><a href=\"$ALINK\">$FNAME</a></li>" >> $HTML
  done

  (echo "</ul>"
   echo "<h2>PG-Strom Source Tarball</h2>"
   echo "<ul>") >> $HTML

  # update index file (pg-strom)
  for x in `ls docs/tgz/pg-strom-*.tar.gz`
  do
    ALINK=`echo $x | sed 's/^docs/./g'`
    FNAME=`basename $x`
    echo "<li><a href=\"$ALINK\">$FNAME</a></li>" >> $HTML
  done
  (echo "</ul>"
   echo "<h2>RPM Files</h2>"
   echo "<ul>") >> $HTML

  for dir in `ls -dr docs/yum/*`
  do
    (echo "<li><b>`basename $dir`</b>"
     echo "  <ul>") >> $HTML
    for x in `ls $dir/*.rpm`
    do
      ALINK=`echo $x | sed 's/^docs/./g'`
      FNAME=`basename $x`
      echo "  <li><a href=\"$ALINK\">$FNAME</a></li>" >> $HTML
    done
    (echo "  </ul>"
     echo "</li>") >> $HTML
  done

  (echo "</ul>"
   echo "</body>"
   echo "</html>") >> $HTML
  cp $HTML docs/index.html
  rm $HTML
fi
exit 0

