#!/bin/bash

# Pro-memoria:
#
# Create chroots with minimal build system:
# debootstrap --arch=i386  --variant=buildd jessie /chroot/deb32 http://mi.mirror.garr.it/mirrors/debian/
# debootstrap --arch=amd64 --variant=buildd jessie /chroot/deb64 http://mi.mirror.garr.it/mirrors/debian/
#
# Download the required source files:
#
# git clone https://github.com/mansr/sox.git
#
# git clone -b Play_DSD_decoded_by_Mansr_sox https://github.com/marcoc1712/squeezelite-R2.git
#
# Hint: you may also use "apt-get source package" to download deps. 
#
# Copy the build dir(s) into the chroot(s).
#
# Enter chroot and install basic tools:
# apt install pkg-config libtool-bin autoconf-archive colormake colorgcc colordiff libasound2
#
# Done. Now you can run this script.


export PREFIX="/usr/local"

export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

export CPPFLAGS="-I${PREFIX}/include"
export CFLAGS="-O3"
export CXXFLAGS="-O3 -static-libstdc++"
export LDFLAGS="-static -static-libstdc++ -L${PREFIX}/lib"

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
  ./configure --prefix=${PREFIX} ${options}
  [ $? -eq 0 ] || exit 1
  echo -e "\n########################################################################\n"
  read -t 10 -p "Press enter to BUILD and INSTALL '$pckg', Ctrl+C to quit."
  echo -e "\nBuilding $pckg...\n"
  colormake -s || exit 2
  echo -e "\n########################################################################"
  echo -e "\nInstalling $pckg...\n"
  colormake -s install || exit 3
  echo -e "\n########################################################################"
  echo -e "${pckg}: all done."
  
  popd 
}

# faad & mpg123 are required only for squeezelite.

doinstall zlib			--static
doinstall file			--enable-shared=no --enable-static=yes
doinstall fftw3 		--enable-shared=no --enable-static=yes --enable-openmp=no --enable-sse2 --enable-threads
#doinstall faad2 		--enable-shared=no --enable-static=yes
#doinstall mpg123		--enable-shared=no --enable-static=yes
doinstall alsa-lib		--enable-shared=no --enable-static=yes --enable-pcm --with-pcm-plugins=plug
doinstall libao 		--enable-shared=no --enable-static=yes --enable-static=alsa --enable-alsa --enable-alsa-mmap
doinstall libpng		--enable-shared=no --enable-static=yes
doinstall libogg		--enable-shared=no --enable-static=yes
doinstall libvorbis		--enable-shared=no --enable-static=yes
doinstall libmad		--enable-shared=no --enable-static=yes
doinstall flac			--enable-shared=no --enable-static=yes --enable-sse
doinstall wavpack		--enable-shared=no --enable-static=yes --enable-mmx
doinstall libsndfile		--enable-shared=no --enable-static=yes
doinstall libsamplerate		--enable-shared=no --enable-static=yes --enable-sndfile
doinstall libid3tag		--enable-shared=no --enable-static=yes
doinstall twolame		--enable-shared=no --enable-static=yes
doinstall lame			--enable-shared=no --enable-static=yes
doinstall sox			--disable-shared   --enable-static=yes --disable-openmp --without-libltdl 

echo -e "\n#########################################################################"
echo -e "\nSqueezelite does not use autotools - wash separately!"
echo -e "#########################################################################\n"
exit
#
# The following must be done by hand:

# Uninstall static copy of alsa and install the system one:
#pushd alsa-lib*
#colormake uninstall
#popd
#apt install libasound2-dev

export PREFIX="/usr/local"
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export CPPFLAGS="-I${PREFIX}/include"
export CFLAGS="-O3"
export CXXFLAGS="-O3"
export LDFLAGS="-L${PREFIX}/lib"
#export OPTS="-DDSD -DFFMPEG -DRESAMPLE -DVISEXPORT -DLINKALL -DIR"
export OPTS="-DDSD" 
pushd squeezelite-R2
colormake
popd
