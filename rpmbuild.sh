#!/bin/sh

# ----------------------------------------------------------------
# This script build RPM package related to PG-Strom.
# We assume both of 'pg-strom' and 'nvme-strom' repositories, which have no
# local modification, are cloned under the '<gitroot>/rpmbuild' directory.
# ----------------------------------------------------------------
cd `dirname $0`
git clean -fdx

if [ "$1" = "--all" ]; then
  REBUILD_ALL=1
else
  REBUILD_ALL=0
fi

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
test -e ${STROM_DIR}/.git || (echo "no $STROM_DIR git repository"; exit 1)
test -e ${NVME_DIR}/.git  || (echo "no $NVME_DIR git repository"; exit 1)
if [ `(cd $STROM_DIR; git diff) | wc -l` -lt 0 ]; then
  echo "$STROM_DIR has local changes"
  exit 1
fi
if [ `(cd $NVME_DIR; git diff) | wc -l` -lt 0 ]; then
  echo "$NVME_DIR has local changes"
  exit 1
fi
# remove all the local tags, then pull upstream
(cd $STROM_DIR;
 for v in `git tag -l`; do git tag -d $v; done;
 git pull) || (echo "failed on git-pull ($STROM_DIR)"; exit 1)
(cd $NVME_DIR;
 for v in `git tag -l`; do git tag -d $v; done;
 git pull) || (echo "failed on git-pull ($NVME_DIR)"; exit 1)

# get version information
STROM_VERSIONS_LIST=`(cd $STROM_DIR; git tag -l)                      \
                     | grep '^v[0-9]*\.[0-9]*\(\-[0-9]\+\)\?$'        \
                     | sed -e 's/^v//g' -e 's/-/ /g'                  \
                     | while read STROM_VERSION STROM_RELEASE;        \
                       do                                             \
                         test -z "$STROM_RELEASE" && STROM_RELEASE=1; \
                         echo "${STROM_VERSION}:${STROM_RELEASE}";    \
                       done`

NVME_VERSIONS_LIST=`(cd $NVME_DIR;  git tag -l)                       \
                    | grep '^v[0-9]*\.[0-9]*\(\-[0-9]\+\)\?$'         \
                    | sed -e 's/^v//g' -e 's/-/ /g'                   \
                    | while read NVME_VERSION NVME_RELEASE;           \
                      do                                              \
                        test -z "$NVME_RELEASE" && NVME_RELEASE=1;    \
                        echo "${NVME_VERSION}:${NVME_RELEASE}";       \
                      done`

# remove packages already deprecated

# pg-strom (tgz)
for f in `git ls-files 'docs/tgz/pg_strom-*.tar.gz'`;
do
  fver=`basename $f | sed -e 's/^pg_strom-//g' -e 's/\.tar\.gz$//g'`
  FOUND=0
  for sv in $STROM_VERSIONS_LIST;
  do
    sig=`echo $sv | tr ':' '-'`
    if [ "$fver" = "$sig" ]; then
      FOUND=1
      break
    fi
  done

  if [ $FOUND -eq 0 ]; then
    git rm $f
    ANY_NEW_PACKAGES=1
  fi
done

# pg-strom (rpm)
for f in `git ls-files 'docs/yum/*/pg_strom-*.rpm'`;
do
  fver=`rpm -qp --queryformat='%{version}-%{release}' $f`
  FOUND=0
  for sv in $STROM_VERSIONS_LIST;
  do
    sig=`echo $sv | tr ':' '-'`
    if (echo $fver | grep -q "^$sig"); then
      FOUND=1
      break
    fi
  done

  if [ $FOUND -eq 0 ]; then
    git rm $f
    ANY_NEW_PACKAGES=1
  fi
done

# nvme-strom (rpm)
for f in `git ls-files 'docs/yum/*/nvme_strom-*.rpm'`;
do
  fver=`rpm -qp --queryformat='%{version}-%{release}' $f`
  FOUND=0
  for nv in $NVME_VERSIONS_LIST;
  do
    sig=`echo $nv | tr ':' '-'`
    if (echo $fver | grep -q "^$sig"); then
      FOUND=1
      break;
    fi
  done

  if [ $FOUND -eq 0 ]; then
    git rm $f
    ANY_NEW_PACKAGES=1
  fi
done

# get rpmbuild working directory
SPECDIR=`rpmbuild -E %{_specdir}`
SRCDIR=`rpmbuild -E %{_sourcedir}`
RPMDIR=`rpmbuild -E %{_rpmdir}`
SRPMDIR=`rpmbuild -E '%{_srcrpmdir}'`
DIST=`rpmbuild -E '%{dist}'`
ARCH=x86_64

PUBLIC_TGZDIR="docs/tgz"

#
# Build heterodb-swdc package
# -------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*
SWDC_VERSION=`rpmspec --qf %{version} -q files/heterodb-swdc.spec`
SWDC_RELEASE=`rpmspec --qf %{release} -q files/heterodb-swdc.spec`
RPMFILE="`rpmspec --rpms -q files/heterodb-swdc.spec`.rpm"
if [ "$REBUILD_ALL" -ne 0 ] || \
   [ "`git ls-files docs/yum/${DISTRO}-${ARCH}/${RPMFILE} | wc -l`" -eq 0 ];
then
  echo hgoehoge
  cp -f files/heterodb-swdc.repo files/RPM-GPG-KEY-HETERODB ${SRCDIR}
  cp -f files/heterodb-swdc.spec ${SPECDIR}
  SPECFILE=heterodb-swdc.spec

  rpmbuild -ba ${SPECDIR}/${SPECFILE} || (echo "filed on rpmbuild"; exit 1)
  if [ -e "$RPMDIR/noarch/${RPMFILE}" ];
  then
    if [ -x ~/rpmsign.sh ];
    then
      ~/rpmsign.sh "$RPMDIR/noarch/${RPMFILE}" || exit 1
    fi
    cp -f "$RPMDIR/noarch/${RPMFILE}" "docs/yum/${DISTRO}-${ARCH}/" || exit 1
    git add "docs/yum/${DISTRO}-${ARCH}/${RPMFILE}" || exit 1
    ANY_NEW_PACKAGES=1
  else
    echo "RPM files missing. Build failed?"
    exit 1
  fi
fi

#
# Build postgresXX-alternatives package
# -------------------------------------
PGALT_VERSION=1.0
PGALT_RELEASE=1
for x in $PGSQL_VERSIONS
do
  PKGVER=`echo $x | sed 's/\\.//g'`
  PRIORITY=`echo $x | awk '{print $1 * 10}'`
  cat files/postgres-alternatives.spec | \
    sed -e "s/@@PGSQL_VERSION@@/$x/g"    \
        -e "s/@@PKGVER@@/$PKGVER/g"      \
        -e "s/@@PRIORITY@@/$PRIORITY/g" > ${SPECDIR}/postgres${PKGVER}-alternatives.spec
  SPECFILE=${SPECDIR}/postgres${PKGVER}-alternatives.spec
  RPMFILE=`rpmspec --rpms -q $SPECFILE`.rpm
  if [ "$REBUILD_ALL" -ne 0 ] || \
     [ "`git ls-files docs/yum/${DISTRO}-${ARCH}/${RPMFILE} | wc -l`" -eq 0 ];
  then
    rpmbuild -ba ${SPECFILE} || (echo "filed on rpmbuild"; exit 1)
    if [ -e "$RPMDIR/noarch/${RPMFILE}" ];
    then
      if [ -x ~/rpmsign.sh ];
      then
        ~/rpmsign.sh "$RPMDIR/noarch/${RPMFILE}" || exit 1
      fi
      cp -f "$RPMDIR/noarch/${RPMFILE}"   "docs/yum/${DISTRO}-${ARCH}/"   || exit 1
      git add "docs/yum/${DISTRO}-${ARCH}/${RPMFILE}"  || exit 1
      ANY_NEW_PACKAGES=1
    else
      echo "RPM File Missing. Build Failed?"
      exit 1
    fi
  fi
done

#
# Build nvme_strom package
# -------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*

ARCH=`uname -m`
for v in $NVME_VERSIONS_LIST;
do
  set -- `echo $v | tr ':' ' '`
  NVME_VERSION=$1
  NVME_RELEASE=$2
  if [ "$NVME_RELEASE" = "1" ];
  then
    NVME_TAG="v${NVME_VERSION}"
    NVME_TARBALL="${NVME_VERSION}"
  else
    NVME_TAG="v${NVME_VERSION}-${NVME_RELEASE}"
    NVME_TARBALL="${NVME_VERSION}-${NVME_RELEASE}"
  fi
  (cat files/nvme_strom.spec | \
     sed -e "s/@@NVME_VERSION@@/${NVME_VERSION}/g" \
         -e "s/@@NVME_RELEASE@@/${NVME_RELEASE}/g" \
         -e "s/@@NVME_TARBALL@@/${NVME_TARBALL}/g";
   cd $NVME_DIR; git show ${NVME_TAG}:CHANGELOG) > ${SPECDIR}/nvme_strom.spec

  RPMFILE=`rpmspec --rpms -q ${SPECDIR}/nvme_strom.spec | grep -v debuginfo`.rpm
  DEBUGINFO=`rpmspec --rpms -q ${SPECDIR}/nvme_strom.spec | grep debuginfo`.rpm
  if [ "$REBUILD_ALL" -eq 0 ] && \
     [ "`git ls-files docs/yum/${DISTRO}-${ARCH}/${RPMFILE} | wc -l`" -gt 0 ] && \
     [ "`git ls-files docs/yum/${DISTRO}-debuginfo/${DEBUGINFO} | wc -l`" -gt 0 ]
  then
    continue;
  fi
  # OK, build a package
  (cd $NVME_DIR; git archive --format=tar.gz \
                              --prefix=nvme_strom-${NVME_TARBALL}/ \
                              -o ${SRCDIR}/nvme_strom-${NVME_TARBALL}.tar.gz \
                              ${NVME_TAG} kmod utils MASTER_LICENSE_KEY LICENSE)
  cat files/nvme_strom.dkms.conf | \
    sed -e "s/@@NVME_STROM_VERSION@@/${NVME_VERSION}/g" > ${SRCDIR}/dkms.conf

  rpmbuild -ba ${SPECDIR}/nvme_strom.spec || (echo "rpmbuild failed"; exit 1)

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
  set -- `echo $sv | tr ':' ' '`
  STROM_VERSION=$1
  STROM_RELEASE=$2
  if [ "$STROM_RELEASE" = "1" ];
  then
    STROM_TAG="v${STROM_VERSION}"
    STROM_TARBALL="pg_strom-${STROM_VERSION}"
  else
    STROM_TAG="v${STROM_VERSION}-${STROM_RELEASE}"
    STROM_TARBALL="pg_strom-${STROM_VERSION}-${STROM_RELEASE}"
  fi

  for pv in $PGSQL_VERSIONS
  do
    PVNUM=`echo $pv | sed 's/\.//g'`
    SPECFILE=pg_strom-PG${PVNUM}.spec
    (cat files/pgstrom-v2.spec | \
       sed -e "s/@@STROM_VERSION@@/${STROM_VERSION}/g" \
           -e "s/@@STROM_RELEASE@@/${STROM_RELEASE}/g" \
           -e "s/@@STROM_TARBALL@@/${STROM_TARBALL}/g" \
           -e "s/@@PGSQL_VERSION@@/${pv}/g" \
           -e "s/@@PGSQL_PKGVER@@/${PVNUM}/g";
     cd $STROM_DIR; git show ${STROM_TAG}:CHANGELOG) > ${SPECDIR}/${SPECFILE}
    RPMFILE=`rpmspec --rpms   -q ${SPECDIR}/${SPECFILE} | grep -v debuginfo`.rpm
    DEBUGINFO=`rpmspec --rpms -q ${SPECDIR}/${SPECFILE} | grep debuginfo`.rpm
    SRPMFILE=`rpmspec --srpm  -q ${SPECDIR}/${SPECFILE} | sed "s/\\.${ARCH}\\\$/.src/g"`.rpm
    if [ "$REBUILD_ALL" -eq 0 ] && \
       [ "`git ls-files docs/yum/${DISTRO}-${ARCH}/${RPMFILE} | wc -l`" -gt 0 ] && \
       [ "`git ls-files docs/yum/${DISTRO}-debuginfo/${DEBUGINFO} | wc -l`" -gt 0 ] && \
       [ "`git ls-files docs/yum/${DISTRO}-source/${SRPMFILE} | wc -l`" -gt 0 ];
    then
      continue;
    fi
    # OK, build a package
    env PATH=/usr/pgsql-${pv}/bin:$PATH \
      make -C $STROM_DIR tarball PGSTROM_VERSION=${STROM_TAG}
    cp -f "${STROM_DIR}/${STROM_TARBALL}.tar.gz" ${SRCDIR}
    env PATH=/usr/pgsql-${pv}/bin:$PATH \
      rpmbuild -ba ${SPECDIR}/${SPECFILE} || (echo "rpmbuild failed"; exit 1)

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

  TEMP=`mktemp -d`
  # update index file (heterodb-swdc)
  HTML="$TEMP/rpm_heterodb-swdc.list"
  echo "<ul>" > $HTML
  for x in `ls docs/yum/*/heterodb-swdc-*.noarch.rpm`
  do
    ALINK=`echo $x | sed 's/^docs/./g'`
    FNAME=`basename $x`
    echo "<li><a href=\"$ALINK\">$FNAME</a></li>" >> $HTML
  done
  echo "</ul>" >> $HTML

  # update index file (pg-strom)
  HTML="$TEMP/tgz_pg-strom.list"
  echo "<ul>" > $HTML
  for x in `ls docs/tgz/pg_strom-*.tar.gz`
  do
    ALINK=`echo $x | sed 's/^docs/./g'`
    FNAME=`basename $x`
    echo "<li><a href=\"$ALINK\">$FNAME</a></li>" >> $HTML
  done
  echo "</ul>" >> $HTML

  # update index files (all RPM files)
  HTML="$TEMP/all_rpm_files.list"
  echo "<ul>" > $HTML
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
  echo "</ul>" >> $HTML
  cpp -I $TEMP -E files/index.html.template | grep -v ^# > docs/index.html
  rm -rf $TEMP
fi
exit 0
