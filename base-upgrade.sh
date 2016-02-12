#!/bin/sh

BASE_FILES="include/linux/nvme.h drivers/block/nvme-core.c drivers/block/nvme-scsi.c"
BASE_DIR="`dirname \`readlink -e $0\``/base"

SRPM="$1"
if [ -z "$SRPM" -o $# -ne 1 ]; then
    echo "Usage: `basename $0` <kernel srpm>"
    exit 1
fi
if [ ! -r "$SRPM" ]; then
    echo "Error: kernel source rpm \"$SRPM\" not found"
    exit 1
fi
if ! `rpm --quiet -qip $SRPM`; then
    echo "Error: \"$SRPM\" does not a valid source package"
    exit 1
fi
SRPM_BASE=`basename $SRPM`
SRPM_NAME="`rpm --queryformat '%{name}' -qp $SRPM`"
SRPM_VERSION="`rpm --queryformat '%{version}' -qp $SRPM`"
SRPM_RELEASE="`rpm --queryformat '%{release}' -qp $SRPM`"

if [ "$SRPM_NAME" != "kernel" ] || \
   echo "$SRPM_RELEASE" | grep -qvE ".el7$"; then
    echo "Error: \"$SRPM\" is not a valid kernel source package"
    echo "Hint: we assume RHEL7/CentOS7 kernel right now"
    exit 1
fi

TEMP_DIR=`mktemp -d`
mkdir -p $TEMP_DIR/source
mkdir -p $TEMP_DIR/old/base
mkdir -p $TEMP_DIR/new/base

cp -f $SRPM $TEMP_DIR/source
for x in $BASE_FILES
do
    cp -f $BASE_DIR/`basename $x` $TEMP_DIR/old
    cp -f $BASE_DIR/`basename $x` $TEMP_DIR/old/base
done
cp -f $BASE_DIR/VERSION $TEMP_DIR/old/base

# extract kernel source and picks up the original files
pushd $TEMP_DIR/source >/dev/null
rpm2cpio $SRPM_BASE | cpio -idu || exit 1
if [ ! -r linux-${SRPM_VERSION}-${SRPM_RELEASE}.tar.xz ]; then
    echo "Error: linux-${SRPM_VERSION}-${SRPM_RELEASE}.tar.xz not found in $SRPM"
    exit 1
fi
tar Jxf linux-${SRPM_VERSION}-${SRPM_RELEASE}.tar.xz || exit 1
if [ ! -d linux-${SRPM_VERSION}-${SRPM_RELEASE} ]; then
    echo "Error: `pwd`/linux-${SRPM_VERSION}-${SRPM_RELEASE} was not made"
    exit 1
fi

for x in $BASE_FILES;
do
    cp -f linux-${SRPM_VERSION}-${SRPM_RELEASE}/$x $TEMP_DIR/new
    cp -f linux-${SRPM_VERSION}-${SRPM_RELEASE}/$x $TEMP_DIR/new/base
done
echo "${SRPM_VERSION}-${SRPM_RELEASE}" > $TEMP_DIR/new/base/VERSION
cd ..

# make a patch to upgrade the base version
diff -rup old new > $TEMP_DIR/nvme-strom.upgrade.diff
popd >/dev/null

if [ -s "$TEMP_DIR/nvme-strom.upgrade.diff" ]; then
    cp $TEMP_DIR/nvme-strom.upgrade.diff ./
    echo "Info: nvme-strom.upgrade.diff is generated"
    echo "------------------------------------------"
    cat ./nvme-strom.upgrade.diff
else
    echo "Info: we have no difference in this upgrade"
    echo "      No patch shall be generated"
fi
rm -rf $TEMP_DIR
