# mingw-w64-libs
Common static libs prebuilt by the cross-compilation toolchain docker images [`cgdoc/mingw-w64-multilib`](https://hub.docker.com/repository/docker/cgdoc/mingw-w64-multilib)
## [Libs Docker Images](https://hub.docker.com/repository/docker/cgdoc/mingw-w64-libs)
* `cgdoc/mingw-w64-libs:win32v1.4-v1.0`
    * Source
        * [Dockerfile](https://github.com/Jesseatgao/mingw-w64-libs/releases/tag/win32v1.4-v1.0)
    * Base Docker Image
        * `alpine:latest`
    * Builder Docker Image
        * `cgdoc/mingw-w64-multilib:win32-v1.4`
* `cgdoc/mingw-w64-libs:posixv1.4-v1.0`
    * Source
        * [Dockerfile](https://github.com/Jesseatgao/mingw-w64-libs/releases/tag/posixv1.4-v1.0)
    * Base Docker Image
        * `alpine:latest`
    * Builder Docker Image
        * `cgdoc/mingw-w64-multilib:posix-v1.4`
## Index
* boost-1.79.0
* bzip2-1.0.8
* expat-2.4.8
* file-5.40
* fmt-8.1.1
* flac-1.3.4
* libiconv-1.17
* libogg-1.3.5
* libvorbis-1.3.7
* libebml-1.4.2
* libmatroska-1.6.3
* libintl-0.20.2 (gettext-0.20.2)
* mingw-libgnurx-2.6.1
* nlohmann-json-3.10.5
* pugixml-1.12.1
* xz-5.2.5
* zlib-1.2.12
## Libs Location
* i686 version
    * individually packed headers and libs (.i686.tar.xz) - 32-bit:
    
        `/opt/mingw32/i686-w64-mingw32/packages/`
    
* x86_64 version
    * individually packed headers and libs (.x86_64.tar.xz) - 64-bit:
    
        `/opt/mingw32/x86_64-w64-mingw32/packages/`
## Expected Installation Location
* i686 version

    `/opt/mingw32/i686-w64-mingw32/`
* x86_64 version

    `/opt/mingw32/x86_64-w64-mingw32/`
## Example Usage
* [Build MKVToolNix using `cgdoc/mingw-w64-libs`](https://github.com/Jesseatgao/MKVToolNix-static-builds/blob/master/Dockerfile.mingw)

