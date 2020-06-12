################### Stage: Prepare the sources to compile ######################
FROM cgdoc/mingw-w64-multilib:latest AS builder


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


COPY Makefile.libgnurx $SRC

RUN cd $SRC \
\
	&& curl -L -O https://sourceforge.net/projects/lzmautils/files/xz-5.2.5.tar.bz2 \
	&& curl -L -O https://sourceware.org/pub/bzip2/bzip2-1.0.6.tar.gz \
	&& curl -L -O https://zlib.net/zlib-1.2.11.tar.xz \
	&& curl -L -O https://sourceforge.net/projects/expat/files/expat/2.2.6/expat-2.2.6.tar.bz2 \
	&& curl -L -O https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz \
	&& curl -L -O https://sourceforge.net/projects/boost/files/boost/1.73.0/boost_1_73_0.tar.bz2 \
	&& curl -L -O https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.4.tar.xz \
	&& curl -L -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.6.tar.xz \
	&& curl -L -O https://ftp.osuosl.org/pub/xiph/releases/flac/flac-1.3.3.tar.xz \
	&& curl -L -o mingw-libgnurx-2.5.1.tar.gz https://sourceforge.net/projects/mingw/files/Other/UserContributed/regex/mingw-regex-2.5.1/mingw-libgnurx-2.5.1-src.tar.gz \
	&& curl -L -o file-5.11.tar.gz https://github.com/file/file/archive/FILE5_11.tar.gz \
	&& curl -L -O https://github.com/zeux/pugixml/releases/download/v1.10/pugixml-1.10.tar.gz \
	&& curl -L -o fmt-6.2.1.tar.gz https://github.com/fmtlib/fmt/archive/6.2.1.tar.gz \
	&& curl -L -O https://dl.matroska.org/downloads/libebml/libebml-1.3.9.tar.xz \
	&& curl -L -O https://dl.matroska.org/downloads/libmatroska/libmatroska-1.5.2.tar.xz \
	&& curl -L -O https://ftp.gnu.org/pub/gnu/gettext/gettext-0.20.2.tar.gz \
	&& curl -L -o nlohmann-json-3.7.3.zip https://github.com/nlohmann/json/releases/download/v3.7.3/include.zip \
\
	&& tar jxvf xz-5.2.5.tar.bz2 \
	&& tar zxvf bzip2-1.0.6.tar.gz \
	&& tar Jxvf zlib-1.2.11.tar.xz \
	&& tar jxvf expat-2.2.6.tar.bz2 \
	&& tar zxvf libiconv-1.16.tar.gz \
	&& tar jxvf boost_1_73_0.tar.bz2 \
	&& tar Jxvf libogg-1.3.4.tar.xz \
	&& tar Jxvf libvorbis-1.3.6.tar.xz \
	&& tar Jxvf flac-1.3.3.tar.xz \
	&& tar zxvf mingw-libgnurx-2.5.1.tar.gz \
	&& mkdir file-5.11 && tar zxvf file-5.11.tar.gz -C file-5.11 --strip-components=1 \
	&& tar zxvf pugixml-1.10.tar.gz \
	&& tar zxvf fmt-6.2.1.tar.gz \
	&& tar Jxvf libebml-1.3.9.tar.xz \
	&& tar Jxvf libmatroska-1.5.2.tar.xz \
	&& tar zxvf gettext-0.20.2.tar.gz \
	&& unzip nlohmann-json-3.7.3.zip -d nlohmann-json-3.7.3


################### Stage: build the i686 version of the libs ######################
FROM builder AS build_i686

ARG HOST=i686-w64-mingw32
ARG ARCH=i686

ARG CFLAGS="-m32"
ARG CXXFLAGS="-m32"
ARG LDFLAGS="-m32"

ARG WINDRES_FLAGS="-F pe-i386"
ARG DLLTOOL_FLAGS="-m i386"

ENV WINDRES "${MINGW32}-windres ${WINDRES_FLAGS}"
ENV RC $WINDRES
ENV DLLTOOL "${MINGW32}-dlltool ${DLLTOOL_FLAGS}"


ARG MINGW32_SEARCH_PATH=/opt/mingw32/$HOST
ARG PKG_CONFIG_PATH=${MINGW32_SEARCH_PATH}/lib/pkgconfig/

ARG CFLAGS="${CFLAGS} -I${MINGW32_SEARCH_PATH}/include"
ARG CXXFLAGS="${CXXFLAGS} -I${MINGW32_SEARCH_PATH}/include"
ARG LDFLAGS="${LDFLAGS} -L${MINGW32_SEARCH_PATH}/lib"

ARG BUILDROOT=/opt/mingw32/_buildroot
ARG PREFIX=/opt/mingw32/_pkgs


RUN mkdir -p ${MINGW32_SEARCH_PATH} $PREFIX $BUILDROOT \
\
	&& mkdir -p $BUILDROOT/xz-5.2.5 && cd $BUILDROOT/xz-5.2.5 \
	&& $SRC/xz-5.2.5/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf xz-5.2.5.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/bzip2-1.0.6 && cd $BUILDROOT/bzip2-1.0.6 \
	&& sed -i 's/sys\\stat\.h/sys\/stat\.h/' $SRC/bzip2-1.0.6/bzip2.c \
	&& make -C $SRC/bzip2-1.0.6 PREFIX=$PREFIX CC=$CC AR=$AR RANLIB=$RANLIB CFLAGS="${CFLAGS} -Wall -Winline -O2 -D_FILE_OFFSET_BITS=64" libbz2.a \
	&& install -d $PREFIX/include $PREFIX/lib && install -m644 $SRC/bzip2-1.0.6/bzlib.h $PREFIX/include/ && install -m644 $SRC/bzip2-1.0.6/libbz2.a $PREFIX/lib/ \
	&& cd $PREFIX && tar Jcvf bzip2-1.0.6.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/zlib-1.2.11 && cd $BUILDROOT/zlib-1.2.11 \
	&& $SRC/zlib-1.2.11/configure --prefix=$PREFIX --static \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf zlib-1.2.11.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/expat-2.2.6 && cd $BUILDROOT/expat-2.2.6 \
	&& $SRC/expat-2.2.6/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf expat-2.2.6.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libiconv-1.16 && cd $BUILDROOT/libiconv-1.16 \
	&& $SRC/libiconv-1.16/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --enable-shared=no --disable-nls \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libiconv-1.16.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& cd $SRC/boost_1_73_0 \
	&& echo "using gcc : mingw : ${MINGW32}-g++ : <rc>${MINGW32}-windres <archiver>${MINGW32}-ar <ranlib>${MINGW32}-ranlib <cxxflags>\"${CXXFLAGS}\" <linkflags>\"${LDFLAGS}\" ;" > user-config.jam \
	&& cd tools/build && CXX=g++ CXXFLAGS= LDFLAGS= ./bootstrap.sh \
	&& cd ../../ && ./tools/build/b2 \
        -a \
        -q \
        -j `nproc` \
        --ignore-site-config \
        --user-config=user-config.jam \
		-sBOOST_ROOT=$SRC/boost_1_73_0 \
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
	&& cd $PREFIX && tar Jcvf boost_1_73_0.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libogg-1.3.4 && cd $BUILDROOT/libogg-1.3.4 \
	&& $SRC/libogg-1.3.4/configure --prefix=$PREFIX --host=$HOST --enable-static \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libogg-1.3.4.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libvorbis-1.3.6 && cd $BUILDROOT/libvorbis-1.3.6 \
	&& $SRC/libvorbis-1.3.6/configure --prefix=$PREFIX --host=$HOST --enable-static \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libvorbis-1.3.6.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/flac-1.3.3 && cd $BUILDROOT/flac-1.3.3 \
	&& $SRC/flac-1.3.3/configure --prefix=$PREFIX --host=$HOST --enable-static=yes \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf flac-1.3.3.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& cd $SRC/mingw-libgnurx-2.5.1 \
	&& cp -f $SRC/Makefile.libgnurx . \
	&& ./configure --prefix=$PREFIX --host=$HOST --build=$BUILD \
	&& make -f Makefile.libgnurx -j `nproc` install-static MINGW32=$MINGW32 \
	&& cd $PREFIX && tar Jcvf mingw-libgnurx-2.5.1.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/file-5.11 && cd $BUILDROOT/file-5.11 \
	&& autoreconf -f -i $SRC/file-5.11 && CFLAGS="${CFLAGS} -DHAVE_PREAD" LDFLAGS="${LDFLAGS}" $SRC/file-5.11/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --disable-silent-rules \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf file-5.11.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/pugixml-1.10 && cd $BUILDROOT/pugixml-1.10 \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC/pugixml-1.10 \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf pugixml-1.10.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/fmt-6.2.1 && cd $BUILDROOT/fmt-6.2.1 \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX -DFMT_DOC=OFF -DFMT_TEST=OFF $SRC/fmt-6.2.1 \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf fmt-6.2.1.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libebml-1.3.9 && cd $BUILDROOT/libebml-1.3.9 \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC/libebml-1.3.9 \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libebml-1.3.9.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libmatroska-1.5.2 && cd $BUILDROOT/libmatroska-1.5.2 \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX  -DCMAKE_PREFIX_PATH=${MINGW32_SEARCH_PATH} $SRC/libmatroska-1.5.2 \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libmatroska-1.5.2.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/gettext-0.20.2 && cd $BUILDROOT/gettext-0.20.2 \
	&& $SRC/gettext-0.20.2/gettext-runtime/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --enable-threads=win32 --without-libexpat-prefix  --without-libxml2-prefix \
	&& make -C intl -j `nproc` && make -C intl install \
	&& cd $PREFIX && tar Jcvf libintl-0.20.2.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& cd $SRC/nlohmann-json-3.7.3 \
	## Use native C++ compiler to circumvent Meson's sanity check.
	&& CXX=g++ AR=ar STRIP=strip CXXFLAGS= LDFLAGS= meson --prefix=$PREFIX --libdir=lib builddir \
	&& ninja -C builddir install \
	&& cd $PREFIX && tar Jcvf nlohmann-json-3.7.3.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/


################# Stage: build the x86_64 version of the libs ######################
FROM builder AS build_x86_64

ARG HOST=x86_64-w64-mingw32
ARG ARCH=x86_64

ARG CFLAGS="-m64"
ARG CXXFLAGS="-m64"
ARG LDFLAGS="-m64"

ARG WINDRES_FLAGS="-F pe-x86-64"
ARG DLLTOOL_FLAGS="-m x86-64"

ENV WINDRES "${MINGW32}-windres ${WINDRES_FLAGS}"
ENV RC $WINDRES
ENV DLLTOOL "${MINGW32}-dlltool ${DLLTOOL_FLAGS}"


ARG MINGW32_SEARCH_PATH=/opt/mingw32/$HOST
ARG PKG_CONFIG_PATH=${MINGW32_SEARCH_PATH}/lib/pkgconfig/

ARG CFLAGS="${CFLAGS} -I${MINGW32_SEARCH_PATH}/include"
ARG CXXFLAGS="${CXXFLAGS} -I${MINGW32_SEARCH_PATH}/include"
ARG LDFLAGS="${LDFLAGS} -L${MINGW32_SEARCH_PATH}/lib"

ARG BUILDROOT=/opt/mingw32/_buildroot
ARG PREFIX=/opt/mingw32/_pkgs


RUN mkdir -p ${MINGW32_SEARCH_PATH} $PREFIX $BUILDROOT \
\
	&& mkdir -p $BUILDROOT/xz-5.2.5 && cd $BUILDROOT/xz-5.2.5 \
	&& $SRC/xz-5.2.5/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf xz-5.2.5.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/bzip2-1.0.6 && cd $BUILDROOT/bzip2-1.0.6 \
	&& sed -i 's/sys\\stat\.h/sys\/stat\.h/' $SRC/bzip2-1.0.6/bzip2.c \
	&& make -C $SRC/bzip2-1.0.6 PREFIX=$PREFIX CC=$CC AR=$AR RANLIB=$RANLIB CFLAGS="${CFLAGS} -Wall -Winline -O2 -D_FILE_OFFSET_BITS=64" libbz2.a \
	&& install -d $PREFIX/include $PREFIX/lib && install -m644 $SRC/bzip2-1.0.6/bzlib.h $PREFIX/include/ && install -m644 $SRC/bzip2-1.0.6/libbz2.a $PREFIX/lib/ \
	&& cd $PREFIX && tar Jcvf bzip2-1.0.6.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/zlib-1.2.11 && cd $BUILDROOT/zlib-1.2.11 \
	&& $SRC/zlib-1.2.11/configure --prefix=$PREFIX --static \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf zlib-1.2.11.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/expat-2.2.6 && cd $BUILDROOT/expat-2.2.6 \
	&& $SRC/expat-2.2.6/configure --prefix=$PREFIX --host=$HOST --enable-static=yes --enable-shared=no \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf expat-2.2.6.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libiconv-1.16 && cd $BUILDROOT/libiconv-1.16 \
	&& $SRC/libiconv-1.16/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --enable-shared=no --disable-nls \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libiconv-1.16.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& cd $SRC/boost_1_73_0 \
	&& echo "using gcc : mingw : ${MINGW32}-g++ : <rc>${MINGW32}-windres <archiver>${MINGW32}-ar <ranlib>${MINGW32}-ranlib <cxxflags>\"${CXXFLAGS}\" <linkflags>\"${LDFLAGS}\" ;" > user-config.jam \
	&& cd tools/build && CXX=g++ CXXFLAGS= LDFLAGS= ./bootstrap.sh \
	&& cd ../../ && ./tools/build/b2 \
        -a \
        -q \
        -j `nproc` \
        --ignore-site-config \
        --user-config=user-config.jam \
		-sBOOST_ROOT=$SRC/boost_1_73_0 \
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
	&& cd $PREFIX && tar Jcvf boost_1_73_0.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libogg-1.3.4 && cd $BUILDROOT/libogg-1.3.4 \
	&& $SRC/libogg-1.3.4/configure --prefix=$PREFIX --host=$HOST --enable-static \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libogg-1.3.4.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libvorbis-1.3.6 && cd $BUILDROOT/libvorbis-1.3.6 \
	&& $SRC/libvorbis-1.3.6/configure --prefix=$PREFIX --host=$HOST --enable-static \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libvorbis-1.3.6.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/flac-1.3.3 && cd $BUILDROOT/flac-1.3.3 \
	&& $SRC/flac-1.3.3/configure --prefix=$PREFIX --host=$HOST --enable-static=yes \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf flac-1.3.3.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& cd $SRC/mingw-libgnurx-2.5.1 \
	&& cp -f $SRC/Makefile.libgnurx . \
	&& ./configure --prefix=$PREFIX --host=$HOST --build=$BUILD \
	&& make -f Makefile.libgnurx -j `nproc` install-static MINGW32=$MINGW32 \
	&& cd $PREFIX && tar Jcvf mingw-libgnurx-2.5.1.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/file-5.11 && cd $BUILDROOT/file-5.11 \
	&& autoreconf -f -i $SRC/file-5.11 && CFLAGS="${CFLAGS} -DHAVE_PREAD" LDFLAGS="${LDFLAGS}" $SRC/file-5.11/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --disable-silent-rules \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf file-5.11.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/pugixml-1.10 && cd $BUILDROOT/pugixml-1.10 \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC/pugixml-1.10 \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf pugixml-1.10.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/fmt-6.2.1 && cd $BUILDROOT/fmt-6.2.1 \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX -DFMT_DOC=OFF -DFMT_TEST=OFF $SRC/fmt-6.2.1 \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf fmt-6.2.1.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libebml-1.3.9 && cd $BUILDROOT/libebml-1.3.9 \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX $SRC/libebml-1.3.9 \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libebml-1.3.9.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/libmatroska-1.5.2 && cd $BUILDROOT/libmatroska-1.5.2 \
	&& cmake -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_INSTALL_PREFIX=$PREFIX  -DCMAKE_PREFIX_PATH=${MINGW32_SEARCH_PATH} $SRC/libmatroska-1.5.2 \
	&& make -j `nproc` && make install \
	&& cd $PREFIX && tar Jcvf libmatroska-1.5.2.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& mkdir -p $BUILDROOT/gettext-0.20.2 && cd $BUILDROOT/gettext-0.20.2 \
	&& $SRC/gettext-0.20.2/gettext-runtime/configure --prefix=$PREFIX --host=$HOST --build=$BUILD --enable-static=yes --enable-threads=win32 --without-libexpat-prefix  --without-libxml2-prefix \
	&& make -C intl -j `nproc` && make -C intl install \
	&& cd $PREFIX && tar Jcvf libintl-0.20.2.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/ \
\
	&& cd $SRC/nlohmann-json-3.7.3 \
	## Use native C++ compiler to circumvent Meson's sanity check.
	&& CXX=g++ AR=ar STRIP=strip CXXFLAGS= LDFLAGS= meson --prefix=$PREFIX --libdir=lib builddir \
	&& ninja -C builddir install \
	&& cd $PREFIX && tar Jcvf nlohmann-json-3.7.3.$ARCH.tar.xz include/ lib/ \
	&& cp -rf include/ lib/ ${MINGW32_SEARCH_PATH} && rm -rf include/ lib/
	

################# Stage: collect the artifacts ######################
FROM alpine:latest

## copy unpacked headers and libs (include/ libs/) - 32-bit
COPY --from=build_i686 /opt/mingw32/i686-w64-mingw32/ /opt/mingw32/i686-w64-mingw32/devels/
## copy individually packed headers and libs (.tar.xz) - 32-bit
COPY --from=build_i686 /opt/mingw32/_pkgs/*.i686.tar.xz /opt/mingw32/i686-w64-mingw32/packages/

## copy unpacked headers and libs (include/ libs/) - 64-bit
COPY --from=build_x86_64 /opt/mingw32/x86_64-w64-mingw32/ /opt/mingw32/x86_64-w64-mingw32/devels/
## copy individually packed headers and libs (.tar.xz) - 64-bit
COPY --from=build_x86_64 /opt/mingw32/_pkgs/*.x86_64.tar.xz /opt/mingw32/x86_64-w64-mingw32/packages/
