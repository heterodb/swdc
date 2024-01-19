function abort
{
   echo "$@" 1>&2
   exit 1
}

INSTALL=0
while getopts i OPT
do
    case $OPT in
        "i" ) INSTALL=1;;
    esac
done
shift $((OPTIND - 1))

SPECDIR=`rpmbuild -E %{_specdir}`
SRCDIR=`rpmbuild -E %{_sourcedir}`
RPMDIR=`rpmbuild -E %{_rpmdir}`
SRPMDIR=`rpmbuild -E '%{_srcrpmdir}'`
DIST=`rpmbuild -E '%{dist}' | sed 's/\.centos//g'`
ARCH=`uname -m`
if echo "$DIST" | grep -q '^\.el7'; then
  DISTRO="rhel7"
elif echo "$DIST" | grep -q '^\.el8'; then
  DISTRO="rhel8"
elif echo "$DIST" | grep -q '^\.el9'; then
  DISTRO="rhel9"
else
  echo "unknown Linux distribution"
  exit 1
fi
