#!/bin/sh

#
# This script build RPM package related to PG-Strom.
# We assume both of 'pg-strom' and 'nvme-strom' repositories, which have no
# local modification, are cloned under the '<gitroot>/rpmbuild' directory.
#
cd `dirname $0`

test -e pg-strom/.git || (echo "no pg-strom git repository"; exit 1)
test -e nvme-strom/.git || (echo "no nvme-strom git repository"; exit 1)

PG_COMMIT=`cd pg-strom; git log | head -1 | awk '{print $2}'`
NVME_COMMIT=`cd nvme-strom; git log | head -1 | awk '{print $2}'`


echo $PG_COMMIT
echo $NVME_COMMIT
