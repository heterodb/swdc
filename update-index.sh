#!/bin/sh

# update yum repository
for d in docs/yum/rhel*-*/repodata;
do
  createrepo --simple-md-filenames --update `dirname $d`
done

DIST_LIST="rhel10 rhel9 rhel8"

TEMP=`mktemp -d`
# time to update
HTML="$TEMP/last_update.list"
echo "Last Update: `env LANG=C date`" > $HTML

# update index file (heterodb-swdc)
HTML="$TEMP/rpm_heterodb-swdc.list"
echo "<ul>" > $HTML
for dist in ${DIST_LIST}
do
    for x in `ls docs/yum/${dist}-noarch/heterodb-swdc-*.noarch.rpm`
    do
	ALINK=`echo $x | sed 's/^docs/./g'`
	FNAME=`basename $x`
	echo "<li><a href=\"$ALINK\">$FNAME</a></li>" >> $HTML
    done
done
echo "</ul>" >> $HTML

# update index file (pg-strom)
HTML="$TEMP/tgz_pg-strom.list"
echo "<ul>" > $HTML
for x in `ls docs/tgz/pg_strom-*.tar.gz | sort -Vr`
do
    ALINK=`echo $x | sed 's/^docs/./g'`
    FNAME=`basename $x`
    echo "<li><a href=\"$ALINK\">$FNAME</a></li>" >> $HTML
done
echo "</ul>" >> $HTML

# update index files (all RPM files)
HTML="$TEMP/all_rpm_files.list"
echo "<ul>" > $HTML
for dist in ${DIST_LIST}
do
    for dir in `ls -dr docs/yum/${dist}-*/`
    do
	(echo $dir | grep -q '\-noarch/$') && continue;

	(echo "<li><b>`basename $dir`</b>"
	 echo "  <ul>") >> $HTML
	for x in `ls ${dir}*.rpm 2>/dev/null`
	do
	    ALINK=`echo $x | sed -e 's|^docs/|./|g'`
	    FNAME=`basename $x`
	    echo "  <li><a href=\"$ALINK\">$FNAME</a></li>" >> $HTML
	done
	(echo "  </ul>"
	 echo "</li>") >> $HTML
    done
done
echo "</ul>" >> $HTML

# update Debian/Ubuntu files
HTML="$TEMP/debian_packages.list"
echo "<ul>" > $HTML
for x in `ls -d docs/deb/*.deb | sort -Vr`
do
  ALINK=`echo $x | sed -e 's|^docs/|./|g'`
  FNAME=`basename $x`
  echo "  <li><a href=\"$ALINK\">$FNAME</a></li>" >> $HTML
done
echo "</ul>" >> $HTML

cpp -I $TEMP -E files/index.html.template | grep -v ^# > docs/index.html
rm -rf $TEMP

exit 0
