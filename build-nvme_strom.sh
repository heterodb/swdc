#!/bin/sh
#
# Build script for nvme_strom
#
cd `dirname $0`
. ./build-common.sh

VERSION="$1"
GITHASH="$2"
GITDIR="nvme-strom"

test -n "$VERSION" -a -n "$GITHASH" || abort "VERSION and GITHASH are missing"
test -e "$GITDIR/.git" || abort "'$GITDIR' is not git repository"
(cd "$GITDIR"; git pull) || abort "failed on git pull"
[ `(cd "$GITDIR"; git diff) | wc -l` -eq 0 ] || abort "$GITDIR has local changes"

#--------------------------------
mkdir -p ${SRCDIR}
rm -rf ${RPMDIR}/*

set -- `echo "$VERSION" | tr '-' ' '`
NVME_VERSION=$1
NVME_RELEASE=$2
test -n "$NVME_VERSION" -a -n "$NVME_RELEASE" || \
    abort "nvme_strom: wrong version(${NVME_VERSION}) and release(${NVME_RELEASE})"

if [ ${#NVME_RELEASE} -le 1 ]; then
  NVME_TARBALL="${NVME_VERSION}"
else
  NVME_TARBALL="${NVME_VERSION}-${NVME_RELEASE}"
fi

(cat files/nvme_strom.spec | \
     sed -e "s/@@NVME_VERSION@@/${NVME_VERSION}/g" \
         -e "s/@@NVME_RELEASE@@/${NVME_RELEASE}/g" \
         -e "s/@@NVME_TARBALL@@/${NVME_TARBALL}/g";
 cd $GITDIR; git show ${GITHASH}:CHANGELOG) > ${SPECDIR}/nvme_strom.spec

RPMFILES=`rpmspec --rpms -q ${SPECDIR}/nvme_strom.spec`

(cd "$GITDIR"; \
 git archive --format=tar.gz \
             --prefix=nvme_strom-${NVME_TARBALL}/ \
             -o ${SRCDIR}/nvme_strom-${NVME_TARBALL}.tar.gz \
             ${GITHASH} kmod rdmax utils MASTER_LICENSE_KEY LICENSE)
cat files/strom.dkms.conf | \
  sed -e "s/@@NVME_STROM_VERSION@@/${NVME_VERSION}/g" > ${SRCDIR}/strom.dkms.conf
cat files/rdmax.dkms.conf | \
  sed -e "s/@@NVME_STROM_VERSION@@/${NVME_VERSION}/g" > ${SRCDIR}/rdmax.dkms.conf
rpmbuild -ba ${SPECDIR}/nvme_strom.spec || abort "rpmbuild failed"
for f in $RPMFILES;
do
  test -e "$RPMDIR/${ARCH}/${f}.rpm" || abort "missing RPM file"
  if [ -x ~/rpmsign.sh ]; then
    ~/rpmsign.sh "$RPMDIR/${ARCH}/${f}.rpm" || abort "failed on rpmsign.sh"
  fi
  if [ "$INSTALL" -ne 0 ]; then
    if echo "$f" | grep -q 'debuginfo'; then
      DEST="docs/yum/${DISTRO}-debuginfo"
    else
      DEST="docs/yum/${DISTRO}-${ARCH}"
    fi
    cp -f $RPMDIR/${ARCH}/${f}.rpm ${DEST} || exit 1
    git add ${DEST}/${f}.rpm || exit 1
  fi
done
exit 0
