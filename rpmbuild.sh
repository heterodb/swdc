#!/bin/sh

cd `dirname $0`
. ./build-common.sh
git clean -fdx

#
# Package Build
#
REBUILD_ALL=0	# set '1' if you want to rebuild all
grep -v '^#'  RPMVERSIONS| while read NAME PKGVER PKGHASH
do
  if [ "$NAME" = "nvme_strom" ]; then
    NFILES=`git ls-files docs/yum/*/nvme_strom-${PKGVER}${DIST}.${ARCH}.rpm 2>/dev/null | wc -l`
    if [ "$REBUILD_ALL" -ne 0 -o "$NFILES" -eq 0 ]; then
      ./build-nvme_strom.sh -i ${PKGVER} ${PKGHASH}
    fi
  elif [ "$NAME" = "pg_strom" ]; then
    NFILES=`git ls-files docs/yum/*/pg_strom-PG*-${PKGVER}${DIST}.${ARCH}.rpm 2>/dev/null | wc -l`
    if [ "$REBUILD_ALL" -ne 0 -o "$NFILES" -eq 0 ]; then
      ./build-pg_strom.sh -i ${PKGVER} ${PKGHASH}
    fi
  fi
done
#
# Remove Obsolete Pakages
#
git ls-files docs/tgz | while read fname
do
  FOUND=`mktemp`
  grep -v '^#'  RPMVERSIONS | while read NAME PKGVER PKGHASH
  do
    test "$NAME" != "pg_strom" && continue;

    set -- `echo "$PKGVER" | tr '-' ' '`
    VERSION=$1
    RELEASE=$2
    if [ ${#RELEASE} -le 1 ]; then
      TGZ_NAME="pg_strom-${VERSION}.tar.gz"
    else
      TGZ_NAME="pg_strom-${VERSION}-${RELEASE}.tar.gz"
    fi
    if [ "`basename $fname`" = "$TGZ_NAME" ]; then
      echo "found" > $FOUND
      break;
    fi
  done
  test "`cat $FOUND`" = "found" || git rm -f "$fname"
  rm -f $FOUND
done

git ls-files docs/yum | grep '\.rpm$' | while read fname
do
  PKGNAME=`rpm -qp --queryformat='%{name}' "$fname" 2>/dev/null`
  if echo $PKGNAME | grep -Eq '^pg_strom-PG[0-9]+'; then
    PKGNAME="pg_strom"
  fi
  PKGVER=`rpm -qp --queryformat='%{version}-%{release}' "$fname" 2>/dev/null`

  FOUND=`mktemp`
  grep -v '^#'  RPMVERSIONS | while read NAME VERSION HASH
  do
    if [ "$PKGNAME" = "$NAME" -a "$PKGVER" = "${VERSION}${DIST}" ]; then
      echo "found" > $FOUND
      break;
    fi
  done
  test "`cat $FOUND`" = "found" || git rm -f "$fname"
  rm -f $FOUND
done

#
# Post rpmbuild steps
#

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
exit 0
