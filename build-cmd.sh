#!/usr/bin/env bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

if [ -z "$AUTOBUILD" ] ; then
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi


top="$(pwd)"
stage="$(pwd)/stage"
stage_include="$stage/include/"
stage_release="$stage/lib/release/"

mkdir -p ${stage_include}
mkdir -p ${stage_release}

PROJECT="libndofdev"
# 2nd line of CHANGELOG is most recent version number:
#         * 0.3
# Tease out just the version number from that line.
VERSION=$(gawk 'END{print MAJOR"."MINOR} /NDOFDEV_MAJOR/{MAJOR=$3} /NDOFDEV_MINOR/{MINOR=$3}' ${PROJECT}/ndofdev_version.h)
SOURCE_DIR="$PROJECT"

"$autobuild" source_environment > "$stage/variables_setup.sh" || exit 1
. "$stage/variables_setup.sh"

build=${AUTOBUILD_BUILD_ID:=0}
echo "${VERSION}.${build}" > "${stage}/VERSION.txt"

# remove_cxxstd
source "$(dirname "$AUTOBUILD_VARIABLES_FILE")/functions"

pushd "$SOURCE_DIR"
case "$AUTOBUILD_PLATFORM" in
    windows*|darwin*)
        # Given forking and future development work, it seems unwise to
        # hardcode the actual URL of the current project's libndofdev
        # repository in this message. Try to determine the URL of this
        # open-libndofdev repository and remove "open-" as a suggestion.
        echo "Windows/Mac libndofdev is in a separate GitHub repository" 1>&2 ; exit 1
    ;;
    linux*)
        # Default target per autobuild build --address-size
        opts="-m$AUTOBUILD_ADDRSIZE $LL_BUILD_RELEASE"
        plainopts="$(remove_cxxstd $opts)"

        # release build
        CFLAGS="$plainopts -I${stage}/packages/include -Wl,-L${stage}/packages/lib/release" \
        CXXFLAGS="$opts -I${stage}/packages/include -Wl,-L${stage}/packages/lib/release" \
        LDFLAGS="-L${stage}/packages/lib/release" \
        USE_SDL3=1 \
        make all

        cp libndofdev.a ${stage_release}
        cp ndofdev_external.h ${stage_include}
    ;;
esac

mkdir -p ${stage}/LICENSES
cp LICENSES/libndofdev.txt ${stage}/LICENSES/libndofdev.txt

popd
