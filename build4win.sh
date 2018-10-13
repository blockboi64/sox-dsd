#!/bin/bash

# Pro-memoria:
#
# install required build tools:
#
# apt install pkg-config libtool-bin autoconf-archive colormake colorgcc colordiff mingw32 mingw-w64 gfortran-mingw-w64 binutils-mingw-w64
#
# get source files:
#
# git clone https://github.com/mansr/sox.git
# git clone -b Play_DSD_decoded_by_Mansr_sox https://github.com/marcoc1712/squeezelite-R2.git
# ecc.

[[ "$1" == "64" ]] && taBit=64 || taBit=32

if [ "$taBit" == "32" ]; then
  host=i686-w64-mingw32
  target=i686-w64-mingw32
else
  host=x86_64-w64-mingw32
  target=x86_64-w64-mingw32
fi

echo -e "\nBuilding for: $target using host=$host\n"

export PREFIX="/var/tmp/sox-dsd-win/win${taBit}"

# required for zlib (see zlib*/win32/Makefile.gcc)
export BINARY_PATH="${PREFIX}/bin"
export INCLUDE_PATH="${PREFIX}/include"
export LIBRARY_PATH="${PREFIX}/lib"

export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

#export CC="gcc -mno-cygwin"
export CPPFLAGS="-I${PREFIX}/include"
export CFLAGS="-O3 -static -mmmx -msse -msse2 -msse3"
export CXXFLAGS="-O3 -static -mmmx -msse -msse2 -msse3"
export LDFLAGS="-static -L${PREFIX}/lib"

export SNDFILE_LIBS="-lsndfile -lFLAC -lvorbisenc -lvorbisfile -lvorbis -logg"


function doinstall() {
  [[ "$1" == "--uninstall" ]] && ( UNINSTALL="true" ; shift ) || unset UNINSTALL
  pckg="$1"
  shift
  options=$@
  cat <<-EOF
	
	########################################################################
	# Now processing: $pckg
	########################################################################
EOF
  pushd "$pckg"* 
  if [ $? -gt 0 ]; then
    echo -e "\nERROR: sources dir for $pckg not found!"
    exit 1
  fi
  echo
  read -t 10 -p "Press enter to clean-up and CONFIGURE, Ctrl+C to quit."
  echo -e "\nCleaning-up $pckg...\n"
  [[ -v UNINSTALL ]] && colormake -s uninstall
  colormake -s clean
  colormake -s distclean
  echo -e "\nPreparing $pckg...\n"
  case pckg in
    sox)
	autoreconf -Wall --prepend-include=${PREFIX}/include -i
	#autoreconf --include=${PREFIX}/include -i
    ;;
    alsa-lib|sox)
	libtoolize --force --copy --automake
	aclocal
	autoheader
	automake --foreign --copy --add-missing
	autoconf
    ;;
  esac
  echo -e "\nConfiguring $pckg...\n"
  ./configure --host=$host --target=$target --prefix=${PREFIX} ${options}
  [ $? -eq 0 ] || exit 2
  echo -e "\n########################################################################\n"
  read -t 10 -p "Press enter to BUILD and INSTALL '$pckg', Ctrl+C to quit."
  echo -e "\nBuilding $pckg...\n"
  colormake -s || exit 3
  echo -e "\n########################################################################"
  echo -e "\nInstalling $pckg...\n"
  colormake -s install || exit 4
  echo -e "\n########################################################################"
  echo -e "${pckg}: all done."
  popd
}

# faad & mpg123 are required only for squeezelite.

function dozlib() {
  pushd zlib*
  if [ $? -gt 0 ]; then
    echo -e "\nERROR: sources dir for $pckg not found!"
    exit 1
  fi
  if [ "$taBit" == "32" ]; then
    sed -i 's#^PREFIX =.*#PREFIX = i686-w64-mingw32-#' win32/Makefile.gcc
  else
    sed -i 's#^PREFIX =.*#PREFIX = x86_64-w64-mingw32-#' win32/Makefile.gcc
  fi
  colormake -f win32/Makefile.gcc clean
  colormake distclean
  colormake -f win32/Makefile.gcc || exit 2
  colormake -f win32/Makefile.gcc install || exit 3
  popd
}

#if false ; then
#else
  ##doinstall zlib		--static
  dozlib
  ##doinstall file		--enable-shared=no --enable-static=yes
  ##doinstall fftw3 		--enable-shared=no --enable-static=yes --enable-openmp=no --enable-sse2 --enable-threads
  ##doinstall faad2 		--enable-shared=no --enable-static=yes
  ##doinstall mpg123		--enable-shared=no --enable-static=yes
  ##doinstall alsa-lib		--enable-shared=no --enable-static=yes --enable-pcm --with-pcm-plugins=plug
  ##doinstall libao 		--enable-shared=no --enable-static=yes --enable-static=alsa --enable-alsa --enable-alsa-mmap
  doinstall libpng		--enable-shared=no --enable-static=yes
  doinstall libogg		--enable-shared=no --enable-static=yes
  doinstall libvorbis		--enable-shared=no --enable-static=yes
  doinstall libmad		--enable-shared=no --enable-static=yes
  doinstall speex		--enable-shared=no --enable-static=yes
  doinstall flac		--enable-shared=no --enable-static=yes --enable-sse
  doinstall wavpack		--enable-shared=no --enable-static=yes --enable-mmx
  doinstall libsndfile		--enable-shared=no --enable-static=yes
  ##doinstall libsamplerate	--enable-shared=no --enable-static=yes --enable-sndfile
  doinstall libid3tag		--enable-shared=no --enable-static=yes
  ##doinstall twolame		--enable-shared=no --enable-static=yes
  doinstall lame		--enable-shared=no --enable-static=yes
  doinstall sox			--disable-shared   --enable-static=yes --disable-openmp --enable-stack-protector=no --without-libltdl --with-pkgconfigdir=${PREFIX}/lib/pkgconfig
#fi
exit
