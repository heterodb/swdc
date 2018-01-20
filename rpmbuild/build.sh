#!/bin/sh

# ----------------------------------------------------------------
# This script build RPM package related to PG-Strom.
# We assume both of 'pg-strom' and 'nvme-strom' repositories, which have no
# local modification, are cloned under the '<gitroot>/rpmbuild' directory.
# ----------------------------------------------------------------
cd `dirname $0`

test -e pg-strom/.git || (echo "no pg-strom git repository"; exit 1)
test -e nvme-strom/.git || (echo "no nvme-strom git repository"; exit 1)

# ensure repository is up-to-data
test `(cd pg-strom; git diff) | wc -l` -lt 0 && (echo "pg-strom repository has local changes"; exit 1)
test `(cd nvme-strom; git diff) | wc -l` -lt 0 && (echo "nvme-strom repository has local changes"; exit 1)
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
PG_VERS="9.6 10"
CUDA_VERS="9.1"
SRCDIR=`rpmbuild -E %{_sourcedir}`
RPMDIR=`rpmbuild -E %{_rpmdir}`

# cleanup
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}

# heterodb-swdc package
cp -f heterodb-swdc.repo RPM-GPG-KEY-HETERODB ${SRCDIR}
rpmbuild -ba heterodb-swdc.spec

exit 1

# pgstrom-PGxx package
make -C pg-strom tarball
cp pg-strom/pg_strom-${STROM_VERSION}.tar.gz ${SRCDIR}
(cd nvme-strom; git archive --format=tar.gz --prefix=nvme_strom-${STROM_VERSION}/ \
                            -o ${SRCDIR}/nvme_strom-${STROM_VERSION}.tar.gz \
                            HEAD kmod utils)

for cv in $CUDA_VERS;
do
  for pv in $PG_VERS;
  do
    rpmbuild -D "strom_version ${STROM_VERSION}" \
             -D "strom_release ${STROM_RELEASE}" \
             -D "pgsql_version ${pv}" \
             -D "cuda_version  ${cv}" \
             -D "strom_commit  ${STROM_COMMIT}" \
             -D "nvme_commit   ${NVME_COMMIT}"  \
             -ba pgstrom-v2.spec
  done
done

echo $STROM_COMMIT
echo $NVME_COMMIT
