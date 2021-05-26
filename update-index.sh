#!/bin/sh

# update yum repository
for d in docs/yum/rhel?-*/repodata;
do
  createrepo --simple-md-filenames --update `dirname $d`
done

TEMP=`mktemp -d`
# time to update
HTML="$TEMP/last_update.list"
env LANG=C date > $HTML

# update index file (heterodb-swdc)
HTML="$TEMP/rpm_heterodb-swdc.list"
echo "<ul>" > $HTML
for x in `ls docs/yum/rhel?-*/heterodb-swdc-*.noarch.rpm`
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
for dir in `ls -dr docs/yum/rhel?-*/`
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
