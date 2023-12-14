#!/usr/bin/env bash

TOP="$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

PROJECT="libndofdev"
VERSION=$(gawk 'END{print MAJOR"."MINOR} /NDOFDEV_MAJOR/{MAJOR=$3} /NDOFDEV_MINOR/{MINOR=$3}' ${TOP}/${PROJECT}/ndofdev_version.h)
SOURCE_DIR="$PROJECT"

if [ -z "$AUTOBUILD" ] ; then 
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

stage="$(pwd)"

if [ ! -d "$stage/include" ]
then
    mkdir -p "$stage/include"
fi

"$autobuild" source_environment > "$stage/variables_setup.sh" || exit 1
. "$stage/variables_setup.sh"


build=${AUTOBUILD_BUILD_ID:=0}
echo "${VERSION}.${build}" > "${stage}/VERSION.txt"

case "$AUTOBUILD_PLATFORM" in
    windows*|darwin*)
        # Given forking and future development work, it seems unwise to
        # hardcode the actual URL of the current project's libndofdev
        # repository in this message. Try to determine the URL of this
        # open-libndofdev repository and remove "open-" as a suggestion.
        echo "Windows/Mac libndofdev is in a separate bitbucket repository \
-- try $(hg paths default | sed -E 's/open-(libndofdev)/\1/')" 1>&2 ; exit 1
		;;
	linux)
		echo "Platform linux is unsupported"
		exit 1
		;;
    linux64)
        opts="-DTARGET_OS_LINUX -m$AUTOBUILD_ADDRSIZE $LL_BUILD_RELEASE"
	#Dumb - $LL_BUILD_RELEASE contains c++ standard flags which are meaningful to the c++
	#compiler only, SDL is written in C and polluting CFLAGS with that nonsense just makes
	#the compiler spew out a whole load of noise, so lets strip that junk out from CFLAGS
	opts=$(echo "$opts" | sed 's/-std=c++[0-9][0-9]*//')
        cmake ../libndofdev -DCMAKE_CXX_FLAGS="$opts" -DCMAKE_C_FLAGS="$opts" \
            -DCMAKE_OSX_ARCHITECTURES="$AUTOBUILD_CONFIGURE_ARCH" \
            -DCMAKE_BUILD_TYPE:STRING=Release
        make
	cp -a ../libndofdev/*.h $stage/include
	cp -a ../libndofdev/LICENSES LICENSES
    ;;
esac
