################### Stage: Prepare the sources to compile ######################
FROM cgdoc/mingw-w64-multilib:posix-v1.1 AS builder


ENV BUILD=x86_64-unknown-linux-gnu

ENV MINGW32=x86_64-w64-mingw32

ENV CC $MINGW32-gcc
ENV CXX $MINGW32-g++
ENV AR $MINGW32-ar
ENV RANLIB $MINGW32-ranlib
ENV STRIP $MINGW32-strip
ENV LD $MINGW32-ld

ENV OBJDUMP $MINGW32-objdump
ENV AS $MINGW32-as
ENV NM $MINGW32-nm

ENV SRC=/opt/_src/


ENV XZ_VER=5.2.5
ENV BZIP2_VER=1.0.6
ENV ZLIB_VER=1.2.11
ENV EXPAT_VER=2.2.9
ENV LIBICONV_VER=1.16
ENV BOOST_VER=1.60.0
ENV OGG_VER=1.3.4
ENV VORBIS_VER=1.3.6
ENV FLAC_VER=1.3.3
ENV LIBGNURX_VER=2.5.1
ENV FILE_VER=5.24
ENV PUGIXML_VER=1.9
ENV FMT_VER=6.2.1

# libmatroska v1.5.2 requires libebml >= v1.3.9
ENV LIBEBML_VER=1.3.10
ENV LIBMATROSKA_VER=1.5.2

ENV GETTEXT_VER=0.20.2
ENV NLOHMANN_VER=3.8.0


COPY Makefile.libgnurx boost-1.60.0.patch gettext-0.20.2.conf.patch file-5.24.patch $SRC

RUN cd $SRC \
\
	&& curl -L -O https://sourceforge.net/projects/lzmautils/files/xz-$XZ_VER.tar.bz2 \
	&& curl -L -O https://sourceware.org/pub/bzip2/bzip2-$BZIP2_VER.tar.gz \
	&& curl -L -O https://zlib.net/zlib-$ZLIB_VER.tar.xz \
	&& curl -L -O https://sourceforge.net/projects/expat/files/expat/$EXPAT_VER/expat-$EXPAT_VER.tar.bz2 \
	&& curl -L -O https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$LIBICONV_VER.tar.gz \
	&& curl -L -o boost-$BOOST_VER.tar.bz2 https://sourceforge.net/projects/boost/files/boost/$BOOST_VER/boost_$(echo $BOOST_VER|sed 's/\./_/g').tar.bz2 \
	&& curl -L -O https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-$OGG_VER.tar.xz \
	&& curl -L -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-$VORBIS_VER.tar.xz \
	&& curl -L -O https://ftp.osuosl.org/pub/xiph/releases/flac/flac-$FLAC_VER.tar.xz \
	&& curl -L -o mingw-libgnurx-$LIBGNURX_VER.tar.gz https://sourceforge.net/projects/mingw/files/Other/UserContributed/regex/mingw-regex-$LIBGNURX_VER/mingw-libgnurx-$LIBGNURX_VER-src.tar.gz \
	&& curl -L -o file-$FILE_VER.tar.gz https://github.com/file/file/archive/FILE$(echo $FILE_VER|sed 's/\./_/g').tar.gz \
	&& curl -L -O https://github.com/zeux/pugixml/releases/download/v$PUGIXML_VER/pugixml-$PUGIXML_VER.tar.gz \
	&& curl -L -o fmt-$FMT_VER.tar.gz https://github.com/fmtlib/fmt/archive/$FMT_VER.tar.gz \
	&& curl -L -O https://dl.matroska.org/downloads/libebml/libebml-$LIBEBML_VER.tar.xz \
	&& curl -L -O https://dl.matroska.org/downloads/libmatroska/libmatroska-$LIBMATROSKA_VER.tar.xz \
	&& curl -L -O https://ftp.gnu.org/pub/gnu/gettext/gettext-$GETTEXT_VER.tar.gz \
	&& curl -L -o nlohmann-json-$NLOHMANN_VER.zip https://github.com/nlohmann/json/releases/download/v$NLOHMANN_VER/include.zip \
\
	&& /bin/bash -c \
	'\
	cd $SRC; pkgs=$(ls|grep -e "\.gz$\|\.xz$\|\.bz2$\|\.zip$"); \
	for pkg in $pkgs; \
	do \
	    pkg_name=$(echo $pkg|sed -n "s/\(.\+\)\(\.tar\.gz\|\.tar\.xz\|\.tar\.bz2\|\.zip\)$/\1/p"); \
	    mkdir -p $pkg_name; \
	    case $pkg in \
	        *\.gz) \
	        tar zxvf $pkg -C $pkg_name --strip-components=1;; \
	        *\.xz) \
	        tar Jxvf $pkg -C $pkg_name --strip-components=1;; \
	        *\.bz2) \
	        tar jxvf $pkg -C $pkg_name --strip-components=1;; \
	        *\.zip) \
	        unzip $pkg -d $pkg_name;; \
	    esac; \
	done; \
	patches=$(ls|grep -e \.patch$); for patch in $patches; \
	do \
	    if [[ $patch =~ \.conf\.patch$ ]]; then \
	        patch_name=$(echo $patch|sed -n "s/\(.\+\)\.conf\.patch$/\1/p"); \
	        [[ -d $patch_name ]] && cd $patch_name && \
	        git apply -v -p1 < ../$patch && \
	        autoreconf -if && \
	        cd ..; \
	    else \
	        patch_name=$(echo $patch|sed -n "s/\(.\+\)\.patch$/\1/p"); \
	        [[ -d $patch_name ]] && cd $patch_name && \
	        git apply -v -p1 < ../$patch && \
	        cd ..; \
	    fi; \
	done\
	'


################### Stage: build the i686 version of the libs ######################
FROM builder AS build_i686

ARG HOST=i686-w64-mingw32
ARG ARCH=i686

ARG CFLAGS="-m32 -march=i686 -mno-ms-bitfields -DWINVER=0x0601 -D_WIN32_WINNT=0x0601  -D_FILE_OFFSET_BITS=64 -fstack-protector-strong"
ARG CXXFLAGS="-m32 -march=i686 -mno-ms-bitfields -DWINVER=0x0601 -D_WIN32_WINNT=0x0601  -D_FILE_OFFSET_BITS=64 -fstack-protector-strong"
ARG LDFLAGS="-m32 -march=i686 -fstack-protector-strong"

ARG WINDRES_FLAGS="-F pe-i386"
ARG DLLTOOL_FLAGS="-m i386"

ENV WINDRES "${MINGW32}-windres ${WINDRES_FLAGS}"
ENV RC $WINDRES
ENV DLLTOOL "${MINGW32}-dlltool ${DLLTOOL_FLAGS}"


ARG MINGW32_SEARCH_PATH=/opt/mingw32


ARG BUILDROOT=/opt/mingw32/_buildroot
ARG PREFIX=${MINGW32_SEARCH_PATH}/$HOST


#ARG PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig/

ARG CFLAGS="${CFLAGS} -I${PREFIX}/include"
ARG CXXFLAGS="${CXXFLAGS} -I${PREFIX}/include"
ARG LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"


RUN mkdir -p ${MINGW32_SEARCH_PATH} $PREFIX $BUILDROOT \
\
	&& mkdir -p $BUILDROOT/xz-$XZ_VER && cd $BUILDROOT/xz-$XZ_VER \
	&& $SRC/xz-$XZ_VER/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes \
	&& make -C src/liblzma -j `nproc` install \
	&& cd $PREFIX && tar Jcvf xz-$XZ_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/bzip2-$BZIP2_VER && cd $BUILDROOT/bzip2-$BZIP2_VER \
	&& sed -i 's/sys\\stat\.h/sys\/stat\.h/' $SRC/bzip2-$BZIP2_VER/bzip2.c \
	&& make -C $SRC/bzip2-$BZIP2_VER PREFIX=$PREFIX CC=$CC AR=$AR RANLIB=$RANLIB CFLAGS="${CFLAGS} -Wall -Winline -O2 -D_FILE_OFFSET_BITS=64" libbz2.a \
	&& install -d $PREFIX/include $PREFIX/lib && install -m644 $SRC/bzip2-$BZIP2_VER/bzlib.h $PREFIX/include/ && install -m644 $SRC/bzip2-$BZIP2_VER/libbz2.a $PREFIX/lib/ \
	&& cd $PREFIX && tar Jcvf bzip2-$BZIP2_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/zlib-$ZLIB_VER && cd $BUILDROOT/zlib-$ZLIB_VER \
	&& $SRC/zlib-$ZLIB_VER/configure --prefix=$PREFIX --static \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf zlib-$ZLIB_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/expat-$EXPAT_VER && cd $BUILDROOT/expat-$EXPAT_VER \
	&& $SRC/expat-$EXPAT_VER/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no --without-docbook \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf expat-$EXPAT_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libiconv-$LIBICONV_VER && cd $BUILDROOT/libiconv-$LIBICONV_VER \
	&& $SRC/libiconv-$LIBICONV_VER/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --enable-shared=no --disable-nls \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libiconv-$LIBICONV_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& cd $SRC/boost-$BOOST_VER \
	&& echo "using gcc : mingw : ${MINGW32}-g++ : <rc>\"$WINDRES\" <archiver>${MINGW32}-ar <ranlib>${MINGW32}-ranlib <cxxflags>\"${CXXFLAGS}\" <linkflags>\"${LDFLAGS}\" ;" > user-config.jam \
	&& cd tools/build && CXX=g++ CXXFLAGS= LDFLAGS= ./bootstrap.sh \
	&& cd ../../ && ./tools/build/b2 \
        -a \
        -q \
        -j `nproc` \
        --ignore-site-config \
        --user-config=user-config.jam \
		-sBOOST_ROOT=$SRC/boost-$BOOST_VER \
        abi=ms \
        address-model=$([[ "$HOST" =~ "x86_64" ]] && echo "64" || echo "32") \
        architecture=x86 \
        binary-format=pe \
        link=static \
        target-os=windows \
        threadapi=win32 \
        threading=multi \
		runtime-link=static \
        variant=release \
        toolset=gcc-mingw \
        optimization=speed \
        --layout=tagged \
        --disable-icu \
		boost.locale.iconv=on \
        --without-mpi \
        --without-python \
        --prefix=$PREFIX \
        --exec-prefix=$PREFIX/bin \
        --libdir=$PREFIX/lib \
        --includedir=$PREFIX/include \
        -sEXPAT_INCLUDE=${MINGW32_SEARCH_PATH}/include \
        -sEXPAT_LIBPATH=${MINGW32_SEARCH_PATH}/lib \
		-sZLIB_INCLUDE=${MINGW32_SEARCH_PATH}/include \
		-sZLIB_LIBPATH=${MINGW32_SEARCH_PATH}/lib \
		-sBZIP2_INCLUDE=${MINGW32_SEARCH_PATH}/include \
		-sBZIP2_LIBPATH=${MINGW32_SEARCH_PATH}/lib \
		-sLZMA_INCLUDE=${MINGW32_SEARCH_PATH}/include \
		-sLZMA_LIBPATH=${MINGW32_SEARCH_PATH}/lib \
		-sICONV_PATH=${MINGW32_SEARCH_PATH} \
        install \
	&& cd $PREFIX && tar Jcvf boost-$BOOST_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libogg-$OGG_VER && cd $BUILDROOT/libogg-$OGG_VER \
	&& $SRC/libogg-$OGG_VER/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libogg-$OGG_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libvorbis-$VORBIS_VER && cd $BUILDROOT/libvorbis-$VORBIS_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX \
	&& $SRC/libvorbis-$VORBIS_VER/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no \
		--with-ogg=$PREFIX --enable-docs=no \
	&& make -j `nproc` \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make install \
	&& cd $PREFIX && tar Jcvf libvorbis-$VORBIS_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/flac-$FLAC_VER && cd $BUILDROOT/flac-$FLAC_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX \
	&& $SRC/flac-$FLAC_VER/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no \
		--enable-ogg --with-ogg=$PREFIX --disable-doxygen-docs --disable-xmms-plugin \
	&& make -j `nproc` \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make install \
	&& cd $PREFIX && tar Jcvf flac-$FLAC_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& cd $SRC/mingw-libgnurx-$LIBGNURX_VER \
	&& cp -f $SRC/Makefile.libgnurx . \
	&& ./configure --prefix=$PREFIX --host=$HOST --build=$BUILD \
	&& make -f Makefile.libgnurx -j `nproc` install-static MINGW32=$MINGW32 \
	&& cd $PREFIX && tar Jcvf mingw-libgnurx-$LIBGNURX_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/file-$FILE_VER && cd $BUILDROOT/file-$FILE_VER \
	&& autoreconf -if $SRC/file-$FILE_VER \
	&& cp -rp $SRC/file-$FILE_VER file-$FILE_VER.native \
	&& cd file-$FILE_VER.native && CC=gcc AR=ar RANLIB=ranlib LD=ld CFLAGS= LDFLAGS= ./configure --disable-shared \
	&& make -j `nproc` \
	&& cd $BUILDROOT/file-$FILE_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX/ && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX/ \
	&& CFLAGS="${CFLAGS} -DHAVE_PREAD" LDFLAGS="${LDFLAGS}" $SRC/file-$FILE_VER/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --disable-silent-rules --disable-shared \
	&& make -j `nproc` FILE_COMPILE="$BUILDROOT/file-$FILE_VER/file-$FILE_VER.native/src/file" \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make install \
	&& cd $PREFIX && tar Jcvf file-$FILE_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/pugixml-$PUGIXML_VER && cd $BUILDROOT/pugixml-$PUGIXML_VER \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC/pugixml-$PUGIXML_VER \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf pugixml-$PUGIXML_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/fmt-$FMT_VER && cd $BUILDROOT/fmt-$FMT_VER \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX -DFMT_DOC=OFF -DFMT_TEST=OFF $SRC/fmt-$FMT_VER \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf fmt-$FMT_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libebml-$LIBEBML_VER && cd $BUILDROOT/libebml-$LIBEBML_VER \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DWIN32=ON -DENABLE_WIN32_IO=ON -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC/libebml-$LIBEBML_VER \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libebml-$LIBEBML_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libmatroska-$LIBMATROSKA_VER && cd $BUILDROOT/libmatroska-$LIBMATROSKA_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX  -DCMAKE_PREFIX_PATH=${MINGW32_SEARCH_PATH} $SRC/libmatroska-$LIBMATROSKA_VER \
	&& make -j `nproc` \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make install \
	&& cd $PREFIX && tar Jcvf libmatroska-$LIBMATROSKA_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/gettext-$GETTEXT_VER && cd $BUILDROOT/gettext-$GETTEXT_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX \
	&& $SRC/gettext-$GETTEXT_VER/gettext-runtime/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --enable-shared=no --enable-threads=windows \
	&& make -C intl -j `nproc` \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make -C intl install \
	&& cd $PREFIX && tar Jcvf libintl-$GETTEXT_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& cd $SRC/nlohmann-json-$NLOHMANN_VER \
	## Use native C++ compiler to circumvent Meson's sanity check.
	&& CXX=g++ AR=ar STRIP=strip CXXFLAGS= LDFLAGS= meson --prefix=$PREFIX --libdir=lib builddir \
	&& ninja -C builddir install \
	&& cd $PREFIX && tar Jcvf nlohmann-json-$NLOHMANN_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/


################# Stage: build the x86_64 version of the libs ######################
FROM builder AS build_x86_64

ARG HOST=x86_64-w64-mingw32
ARG ARCH=x86_64

ARG CFLAGS="-m64 -mno-ms-bitfields -DWINVER=0x0601 -D_WIN32_WINNT=0x0601 -D_FILE_OFFSET_BITS=64 -fstack-protector-strong"
ARG CXXFLAGS="-m64 -mno-ms-bitfields -DWINVER=0x0601 -D_WIN32_WINNT=0x0601 -D_FILE_OFFSET_BITS=64 -fstack-protector-strong"
ARG LDFLAGS="-m64 -fstack-protector-strong"

ARG WINDRES_FLAGS="-F pe-x86-64"
ARG DLLTOOL_FLAGS="-m i386:x86-64"

ENV WINDRES "${MINGW32}-windres ${WINDRES_FLAGS}"
ENV RC $WINDRES
ENV DLLTOOL "${MINGW32}-dlltool ${DLLTOOL_FLAGS}"


ARG MINGW32_SEARCH_PATH=/opt/mingw32


ARG BUILDROOT=/opt/mingw32/_buildroot
ARG PREFIX=${MINGW32_SEARCH_PATH}/$HOST


#ARG PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig/

ARG CFLAGS="${CFLAGS} -I${PREFIX}/include"
ARG CXXFLAGS="${CXXFLAGS} -I${PREFIX}/include"
ARG LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"


RUN mkdir -p ${MINGW32_SEARCH_PATH} $PREFIX $BUILDROOT \
\
	&& mkdir -p $BUILDROOT/xz-$XZ_VER && cd $BUILDROOT/xz-$XZ_VER \
	&& $SRC/xz-$XZ_VER/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes \
	&& make -C src/liblzma -j `nproc` install \
	&& cd $PREFIX && tar Jcvf xz-$XZ_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/bzip2-$BZIP2_VER && cd $BUILDROOT/bzip2-$BZIP2_VER \
	&& sed -i 's/sys\\stat\.h/sys\/stat\.h/' $SRC/bzip2-$BZIP2_VER/bzip2.c \
	&& make -C $SRC/bzip2-$BZIP2_VER PREFIX=$PREFIX CC=$CC AR=$AR RANLIB=$RANLIB CFLAGS="${CFLAGS} -Wall -Winline -O2 -D_FILE_OFFSET_BITS=64" libbz2.a \
	&& install -d $PREFIX/include $PREFIX/lib && install -m644 $SRC/bzip2-$BZIP2_VER/bzlib.h $PREFIX/include/ && install -m644 $SRC/bzip2-$BZIP2_VER/libbz2.a $PREFIX/lib/ \
	&& cd $PREFIX && tar Jcvf bzip2-$BZIP2_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/zlib-$ZLIB_VER && cd $BUILDROOT/zlib-$ZLIB_VER \
	&& $SRC/zlib-$ZLIB_VER/configure --prefix=$PREFIX --static \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf zlib-$ZLIB_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/expat-$EXPAT_VER && cd $BUILDROOT/expat-$EXPAT_VER \
	&& $SRC/expat-$EXPAT_VER/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no --without-docbook \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf expat-$EXPAT_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libiconv-$LIBICONV_VER && cd $BUILDROOT/libiconv-$LIBICONV_VER \
	&& $SRC/libiconv-$LIBICONV_VER/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --enable-shared=no --disable-nls \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libiconv-$LIBICONV_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& cd $SRC/boost-$BOOST_VER \
	&& echo "using gcc : mingw : ${MINGW32}-g++ : <rc>\"$WINDRES\" <archiver>${MINGW32}-ar <ranlib>${MINGW32}-ranlib <cxxflags>\"${CXXFLAGS}\" <linkflags>\"${LDFLAGS}\" ;" > user-config.jam \
	&& cd tools/build && CXX=g++ CXXFLAGS= LDFLAGS= ./bootstrap.sh \
	&& cd ../../ && ./tools/build/b2 \
        -a \
        -q \
        -j `nproc` \
        --ignore-site-config \
        --user-config=user-config.jam \
		-sBOOST_ROOT=$SRC/boost-$BOOST_VER \
        abi=ms \
        address-model=$([[ "$HOST" =~ "x86_64" ]] && echo "64" || echo "32") \
        architecture=x86 \
        binary-format=pe \
        link=static \
        target-os=windows \
        threadapi=win32 \
        threading=multi \
		runtime-link=static \
        variant=release \
        toolset=gcc-mingw \
        optimization=speed \
        --layout=tagged \
        --disable-icu \
		boost.locale.iconv=on \
        --without-mpi \
        --without-python \
        --prefix=$PREFIX \
        --exec-prefix=$PREFIX/bin \
        --libdir=$PREFIX/lib \
        --includedir=$PREFIX/include \
        -sEXPAT_INCLUDE=${MINGW32_SEARCH_PATH}/include \
        -sEXPAT_LIBPATH=${MINGW32_SEARCH_PATH}/lib \
		-sZLIB_INCLUDE=${MINGW32_SEARCH_PATH}/include \
		-sZLIB_LIBPATH=${MINGW32_SEARCH_PATH}/lib \
		-sBZIP2_INCLUDE=${MINGW32_SEARCH_PATH}/include \
		-sBZIP2_LIBPATH=${MINGW32_SEARCH_PATH}/lib \
		-sLZMA_INCLUDE=${MINGW32_SEARCH_PATH}/include \
		-sLZMA_LIBPATH=${MINGW32_SEARCH_PATH}/lib \
		-sICONV_PATH=${MINGW32_SEARCH_PATH} \
        install \
	&& cd $PREFIX && tar Jcvf boost-$BOOST_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libogg-$OGG_VER && cd $BUILDROOT/libogg-$OGG_VER \
	&& $SRC/libogg-$OGG_VER/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libogg-$OGG_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libvorbis-$VORBIS_VER && cd $BUILDROOT/libvorbis-$VORBIS_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX \
	&& $SRC/libvorbis-$VORBIS_VER/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no \
		--with-ogg=$PREFIX --enable-docs=no \
	&& make -j `nproc` \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make install \
	&& cd $PREFIX && tar Jcvf libvorbis-$VORBIS_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/flac-$FLAC_VER && cd $BUILDROOT/flac-$FLAC_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX \
	&& $SRC/flac-$FLAC_VER/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no \
		--enable-ogg --with-ogg=$PREFIX --disable-doxygen-docs --disable-xmms-plugin \
	&& make -j `nproc` \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make install \
	&& cd $PREFIX && tar Jcvf flac-$FLAC_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& cd $SRC/mingw-libgnurx-$LIBGNURX_VER \
	&& cp -f $SRC/Makefile.libgnurx . \
	&& ./configure --prefix=$PREFIX --host=$HOST --build=$BUILD \
	&& make -f Makefile.libgnurx -j `nproc` install-static MINGW32=$MINGW32 \
	&& cd $PREFIX && tar Jcvf mingw-libgnurx-$LIBGNURX_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/file-$FILE_VER && cd $BUILDROOT/file-$FILE_VER \
	&& autoreconf -if $SRC/file-$FILE_VER \
	&& cp -rp $SRC/file-$FILE_VER file-$FILE_VER.native \
	&& cd file-$FILE_VER.native && CC=gcc AR=ar RANLIB=ranlib LD=ld CFLAGS= LDFLAGS= ./configure --disable-shared \
	&& make -j `nproc` \
	&& cd $BUILDROOT/file-$FILE_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX/ && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX/ \
	&& CFLAGS="${CFLAGS} -DHAVE_PREAD" LDFLAGS="${LDFLAGS}" $SRC/file-$FILE_VER/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --disable-silent-rules --disable-shared \
	&& make -j `nproc` FILE_COMPILE="$BUILDROOT/file-$FILE_VER/file-$FILE_VER.native/src/file" \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make install \
	&& cd $PREFIX && tar Jcvf file-$FILE_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/pugixml-$PUGIXML_VER && cd $BUILDROOT/pugixml-$PUGIXML_VER \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC/pugixml-$PUGIXML_VER \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf pugixml-$PUGIXML_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/fmt-$FMT_VER && cd $BUILDROOT/fmt-$FMT_VER \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX -DFMT_DOC=OFF -DFMT_TEST=OFF $SRC/fmt-$FMT_VER \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf fmt-$FMT_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libebml-$LIBEBML_VER && cd $BUILDROOT/libebml-$LIBEBML_VER \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DWIN32=ON -DENABLE_WIN32_IO=ON -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC/libebml-$LIBEBML_VER \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libebml-$LIBEBML_VER.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libmatroska-$LIBMATROSKA_VER && cd $BUILDROOT/libmatroska-$LIBMATROSKA_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX  -DCMAKE_PREFIX_PATH=${MINGW32_SEARCH_PATH} $SRC/libmatroska-$LIBMATROSKA_VER \
	&& make -j `nproc` \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make install \
	&& cd $PREFIX && tar Jcvf libmatroska-$LIBMATROSKA_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/gettext-$GETTEXT_VER && cd $BUILDROOT/gettext-$GETTEXT_VER \
	&& mv ${MINGW32_SEARCH_PATH}/include $PREFIX && mv ${MINGW32_SEARCH_PATH}/lib $PREFIX \
	&& $SRC/gettext-$GETTEXT_VER/gettext-runtime/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --enable-shared=no --enable-threads=windows \
	&& make -C intl -j `nproc` \
	&& mv $PREFIX/include ${MINGW32_SEARCH_PATH} && mv $PREFIX/lib ${MINGW32_SEARCH_PATH} \
	&& make -C intl install \
	&& cd $PREFIX && tar Jcvf libintl-$GETTEXT_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/ \
\
	&& cd $SRC/nlohmann-json-$NLOHMANN_VER \
	## Use native C++ compiler to circumvent Meson's sanity check.
	&& CXX=g++ AR=ar STRIP=strip CXXFLAGS= LDFLAGS= meson --prefix=$PREFIX --libdir=lib builddir \
	&& ninja -C builddir install \
	&& cd $PREFIX && tar Jcvf nlohmann-json-$NLOHMANN_VER.$ARCH.tar.xz include/ lib/ \
	&& rm -rf include/ lib/
	

################# Stage: collect the artifacts ######################
FROM alpine:latest

## copy unpacked headers and libs (include/ libs/) - 32-bit
#COPY --from=build_i686 /opt/mingw32/x86_64-w64-mingw32/ /opt/mingw32/i686-w64-mingw32/devels/
## copy individually packed headers and libs (.tar.xz) - 32-bit
COPY --from=build_i686 /opt/mingw32/i686-w64-mingw32/*.i686.tar.xz /opt/mingw32/i686-w64-mingw32/packages/

## copy unpacked headers and libs (include/ libs/) - 64-bit
#COPY --from=build_x86_64 /opt/mingw32/i686-w64-mingw32/ /opt/mingw32/x86_64-w64-mingw32/devels/
## copy individually packed headers and libs (.tar.xz) - 64-bit
COPY --from=build_x86_64 /opt/mingw32/x86_64-w64-mingw32/*.x86_64.tar.xz /opt/mingw32/x86_64-w64-mingw32/packages/
