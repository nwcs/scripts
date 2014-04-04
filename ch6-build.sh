#!/bin/bash
#
# PiLFS Build Script SVN-20140331 v1.0
# Builds chapters 6.7 - Raspberry Pi Linux API Headers to 6.71 - Vim
# http://www.intestinate.com/pilfs
#
# Optional parameteres below:

LOCAL_TIMEZONE=Europe/London    # Use this timezone from /usr/share/zoneinfo/ to set /etc/localtime. See "6.9.2. Configuring Glibc".
GROFF_PAPER_SIZE=A4             # Use this default paper size for Groff. See "6.52. Groff-1.22.2".
INSTALL_OPTIONAL_DOCS=1         # Install optional documentation when given a choice?
INSTALL_ALL_LOCALES=0           # Install all glibc locales? By default only en_US.ISO-8859-1 and en_US.UTF-8 are installed.

# End of optional parameters

set -o nounset
set -o errexit

function prebuild_sanity_check {
    if [[ $(whoami) != "root" ]] ; then
        echo "You should be running as root for chapter 6!"
        exit 1
    fi

    if ! [[ -d /sources ]] ; then
        echo "Can't find your sources directory! Did you forget to chroot?"
        exit 1
    fi

    if ! [[ -d /tools ]] ; then
        echo "Can't find your tools directory! Did you forget to chroot?"
        exit 1
    fi
}

function check_tarballs {
LIST_OF_TARBALLS="
rpi-3.10.y.tar.gz
man-pages-3.63.tar.xz
glibc-2.19.tar.xz
glibc-2.19-fhs-1.patch
tzdata2014a.tar.gz
zlib-1.2.8.tar.xz
file-5.17.tar.gz
binutils-2.24.tar.bz2
gmp-5.1.3.tar.xz
mpfr-3.1.2.tar.xz
mpc-1.0.2.tar.gz
gcc-4.8.2.tar.bz2
gcc-4.8.0-pi-cpu-default.patch
sed-4.2.2.tar.bz2
bzip2-1.0.6.tar.gz
bzip2-1.0.6-install_docs-1.patch
pkg-config-0.28.tar.gz
ncurses-5.9.tar.gz
attr-2.4.47.src.tar.gz
acl-2.2.52.src.tar.gz
libcap-2.24.tar.xz
shadow_4.1.5.1.orig.tar.gz
psmisc-22.21.tar.gz
procps-ng-3.3.9.tar.xz
e2fsprogs-1.42.9.tar.gz
coreutils-8.22.tar.xz
coreutils-8.22-i18n-4.patch
iana-etc-2.30.tar.bz2
m4-1.4.17.tar.xz
flex-2.5.38.tar.bz2
bison-3.0.2.tar.xz
grep-2.18.tar.xz
readline-6.3.tar.gz
bash-4.3.tar.gz
bc-1.06.95.tar.bz2
libtool-2.4.2.tar.gz
gdbm-1.11.tar.gz
expat-2.1.0.tar.gz
inetutils-1.9.2.tar.gz
perl-5.18.2.tar.bz2
XML-Parser-2.42_01.tar.gz
autoconf-2.69.tar.xz
automake-1.14.1.tar.xz
diffutils-3.3.tar.xz
gawk-4.1.0.tar.xz
findutils-4.4.2.tar.gz
gettext-0.18.3.2.tar.gz
intltool-0.50.2.tar.gz
gperf-3.0.4.tar.gz
groff-1.22.2.tar.gz
xz-5.0.5.tar.xz
less-458.tar.gz
gzip-1.6.tar.xz
iproute2-3.12.0.tar.xz
kbd-2.0.1.tar.gz
kbd-2.0.1-backspace-1.patch
kmod-16.tar.xz
libpipeline-1.2.6.tar.gz
make-4.0.tar.bz2
man-db-2.6.6.tar.xz
patch-2.7.1.tar.xz
sysklogd-1.5.tar.gz
sysvinit-2.88dsf.tar.bz2
sysvinit-2.88dsf-consolidated-1.patch
tar-1.27.1.tar.xz
tar-1.27.1-manpage-1.patch
texinfo-5.2.tar.xz
eudev-1.5.3.tar.gz
eudev-1.5.3-manpages.tar.bz2
util-linux-2.24.1.tar.xz
vim-7.4.tar.bz2
master.tar.gz
"

for tarball in $LIST_OF_TARBALLS ; do
    if ! [[ -f /sources/$tarball ]] ; then
        echo "Can't find /sources/$tarball!"
        exit 1
    fi
done
}

function timer {
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local stime=$1
        etime=$(date '+%s')
        if [[ -z "$stime" ]]; then stime=$etime; fi
        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%02d:%02d:%02d' $dh $dm $ds
    fi
}

prebuild_sanity_check
check_tarballs

echo -e "\nThis is your last chance to quit before we start building... continue?"
echo "(Note that if anything goes wrong during the build, the script will abort mission)"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

total_time=$(timer)

echo "# 6.7. Raspberry Pi Linux API Headers"
cd /sources
if ! [[ -d /sources/linux-rpi-3.10.y ]] ; then
    tar -zxf rpi-3.10.y.tar.gz
fi
cd linux-rpi-3.10.y
make mrproper
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include
cd /sources

echo "# 6.8. Man-pages-3.63"
tar -Jxf man-pages-3.63.tar.xz
cd man-pages-3.63
make install
cd /sources
rm -rf man-pages-3.63

echo "# 6.9. Glibc-2.19"
tar -Jxf glibc-2.19.tar.xz
cd glibc-2.19
sed -i 's/\\$$(pwd)/`pwd`/' timezone/Makefile
patch -Np1 -i ../glibc-2.19-fhs-1.patch
mkdir -v ../glibc-build
cd ../glibc-build
../glibc-2.19/configure    \
    --prefix=/usr          \
    --disable-profile      \
    --enable-kernel=2.6.32 \
    --enable-obsolete-rpc
make
touch /etc/ld.so.conf
make install
cp -v ../glibc-2.19/nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
if [[ $INSTALL_ALL_LOCALES = 1 ]] ; then
    make localedata/install-locales
else
    mkdir -pv /usr/lib/locale
    localedef -i en_US -f ISO-8859-1 en_US
    localedef -i en_US -f UTF-8 en_US.UTF-8
fi
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
tar -zxf ../tzdata2014a.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done
cp -v zone.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
if ! [[ -f /usr/share/zoneinfo/$LOCAL_TIMEZONE ]] ; then
    echo "Seems like your timezone won't work out. Defaulting to London. Either fix it yourself later or consider moving there :)"
    cp -v --remove-destination /usr/share/zoneinfo/Europe/London /etc/localtime
else
    cp -v --remove-destination /usr/share/zoneinfo/$LOCAL_TIMEZONE /etc/localtime
fi
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d
# Compatibility symlink for non ld-linux-armhf awareness
ln -sv ld-2.19.so /lib/ld-linux.so.3
cd /sources
rm -rf glibc-build glibc-2.19

echo "# 6.10. Adjusting the Toolchain"
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs

echo "# 6.11. Zlib-1.2.8"
tar -Jxf zlib-1.2.8.tar.xz
cd zlib-1.2.8
./configure --prefix=/usr
make
make install
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
cd /sources
rm -rf zlib-1.2.8

echo "# 6.12. File-5.17"
tar -zxf file-5.17.tar.gz
cd file-5.17
./configure --prefix=/usr
make
make install
cd /sources
rm -rf file-5.17

echo "# 6.13. Binutils-2.24"
tar -jxf binutils-2.24.tar.bz2
cd binutils-2.24
rm -fv etc/standards.info
sed -i.bak '/^INFO/s/standards.info //' etc/Makefile.in
mkdir -v ../binutils-build
cd ../binutils-build
../binutils-2.24/configure --prefix=/usr --enable-shared
make tooldir=/usr
make tooldir=/usr install
cd /sources
rm -rf binutils-build binutils-2.24

echo "# 6.14. GMP-5.1.3"
tar -Jxf gmp-5.1.3.tar.xz
cd gmp-5.1.3
./configure --prefix=/usr --enable-cxx
make
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    mkdir -v /usr/share/doc/gmp-5.1.3
    cp    -v doc/{isa_abi_headache,configuration} doc/*.html \
             /usr/share/doc/gmp-5.1.3
fi
cd /sources
rm -rf gmp-5.1.3

echo "# 6.15. MPFR-3.1.2"
tar -Jxf mpfr-3.1.2.tar.xz
cd mpfr-3.1.2
./configure  --prefix=/usr        \
             --enable-thread-safe \
             --docdir=/usr/share/doc/mpfr-3.1.2
make
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    make html
    make install-html
fi
cd /sources
rm -rf mpfr-3.1.2

echo "# 6.16. MPC-1.0.2"
tar -zxf mpc-1.0.2.tar.gz
cd mpc-1.0.2
./configure --prefix=/usr
make
make install
cd /sources
rm -rf mpc-1.0.2

echo "# 6.17. GCC-4.8.2"
tar -jxf gcc-4.8.2.tar.bz2
cd gcc-4.8.2
patch -Np1 -i ../gcc-4.8.0-pi-cpu-default.patch
sed -i 's/^T_CFLAGS =$/& -fomit-frame-pointer/' gcc/Makefile.in
sed -i -e /autogen/d -e /check.sh/d fixincludes/Makefile.in
mv -v libmudflap/testsuite/libmudflap.c++/pass41-frag.cxx{,.disable}
mkdir -v ../gcc-build
cd ../gcc-build
SED=sed                          \
../gcc-4.8.2/configure           \
     --prefix=/usr               \
     --enable-shared             \
     --enable-threads=posix      \
     --enable-__cxa_atexit       \
     --enable-clocale=gnu        \
     --enable-languages=c,c++    \
     --disable-multilib          \
     --disable-bootstrap         \
     --with-system-zlib
make
make install
ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd /sources
rm -rf gcc-build gcc-4.8.2

echo "# 6.18. Sed-4.2.2"
tar -jxf sed-4.2.2.tar.bz2
cd sed-4.2.2
./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed-4.2.2
make
make html
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    make -C doc install-html
fi
cd /sources
rm -rf sed-4.2.2

echo "# 6.19. Bzip2-1.0.6"
tar -zxf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat
cd /sources
rm -rf bzip2-1.0.6

echo "# 6.20. Pkg-config-0.28"
tar -zxf pkg-config-0.28.tar.gz
cd pkg-config-0.28
./configure --prefix=/usr         \
            --with-internal-glib  \
            --disable-host-tool   \
            --docdir=/usr/share/doc/pkg-config-0.28
make
make install
cd /sources
rm -rf pkg-config-0.28

echo "# 6.21. Ncurses-5.9"
tar -zxf ncurses-5.9.tar.gz
cd ncurses-5.9
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --enable-pc-files       \
            --enable-widec
make
make install
mv -v /usr/lib/libncursesw.so.5* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv lib${lib}w.a      /usr/lib/lib${lib}.a
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
ln -sfv libncurses++w.a /usr/lib/libncurses++.a
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
ln -sfv libncursesw.a      /usr/lib/libcursesw.a
ln -sfv libncurses.a       /usr/lib/libcurses.a
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    mkdir -v       /usr/share/doc/ncurses-5.9
    cp -v -R doc/* /usr/share/doc/ncurses-5.9
fi
cd /sources
rm -rf ncurses-5.9

echo "6.22. Attr-2.4.47"
tar -zxf attr-2.4.47.src.tar.gz
cd attr-2.4.47
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
./configure --prefix=/usr --bindir=/bin
make
make install install-dev install-lib
chmod -v 755 /usr/lib/libattr.so
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
cd /sources
rm -rf attr-2.4.47

echo "6.23. Acl-2.2.52"
tar -zxf acl-2.2.52.src.tar.gz
cd acl-2.2.52
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
./configure --prefix=/usr \
            --bindir=/bin \
            --libexecdir=/usr/lib
make
make install install-dev install-lib
chmod -v 755 /usr/lib/libacl.so
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
cd /sources
rm -rf acl-2.2.52

echo "6.24. Libcap-2.24"
tar -Jxf libcap-2.24.tar.xz
cd libcap-2.24
make
make RAISE_SETFCAP=no prefix=/usr install
chmod -v 755 /usr/lib/libcap.so
mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
cd /sources
rm -rf libcap-2.24

echo "# 6.25. Shadow-4.1.5.1"
tar -zxf shadow_4.1.5.1.orig.tar.gz
cd shadow-4.1.5.1
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs
./configure --sysconfdir=/etc
make
make install
mv -v /usr/bin/passwd /bin
pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd
# passwd root
# Root password will be set at the end of the script to prevent a stop here
cd /sources
rm -rf shadow-4.1.5.1

echo "# 6.26. Psmisc-22.21"
tar -zxf psmisc-22.21.tar.gz
cd psmisc-22.21
./configure --prefix=/usr
make
make install
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin
cd /sources
rm -rf psmisc-22.21

echo "# 6.27. Procps-ng-3.3.9"
tar -Jxf procps-ng-3.3.9.tar.xz
cd procps-ng-3.3.9
./configure --prefix=/usr                           \
            --exec-prefix=                          \
            --libdir=/usr/lib                       \
            --docdir=/usr/share/doc/procps-ng-3.3.9 \
            --disable-static                        \
            --disable-kill
make
make install
mv -v /usr/bin/pidof /bin
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
cd /sources
rm -rf procps-ng-3.3.9

echo "# 6.28. E2fsprogs-1.42.9"
tar -zxf e2fsprogs-1.42.9.tar.gz
cd e2fsprogs-1.42.9
sed -i -e 's|^LD_LIBRARY_PATH.*|&:/tools/lib|' tests/test_config
mkdir -v build
cd build
LIBS=-L/tools/lib                    \
CFLAGS=-I/tools/include              \
PKG_CONFIG_PATH=/tools/lib/pkgconfig \
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
make install
make install-libs
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    gunzip -v /usr/share/info/libext2fs.info.gz
    install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
    makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
    install -v -m644 doc/com_err.info /usr/share/info
    install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
fi
cd /sources
rm -rf e2fsprogs-1.42.9

echo "# 6.29. Coreutils-8.22"
tar -Jxf coreutils-8.22.tar.xz
cd coreutils-8.22
patch -Np1 -i ../coreutils-8.22-i18n-4.patch
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make
make install
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
# Found a problem here where the moved mv binary from the line above can't be found by the next line.
# Inserting a sync as a workaround.
sync
mv -v /usr/bin/{rmdir,stty,sync,true,uname,test,[} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,sleep,nice} /bin
cd /sources
rm -rf coreutils-8.22

echo "# 6.30. Iana-Etc-2.30"
tar -jxf iana-etc-2.30.tar.bz2
cd iana-etc-2.30
make
make install
cd /sources
rm -rf iana-etc-2.30

echo "# 6.31. M4-1.4.17"
tar -Jxf m4-1.4.17.tar.xz
cd m4-1.4.17
./configure --prefix=/usr
make
make install
cd /sources
rm -rf m4-1.4.17

echo "# 6.32. Flex-2.5.38"
tar -jxf flex-2.5.38.tar.bz2
cd flex-2.5.38
sed -i -e '/test-bison/d' tests/Makefile.in
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.5.38
make
make install
cat > /usr/bin/lex << "EOF"
#!/bin/sh
# Begin /usr/bin/lex

exec /usr/bin/flex -l "$@"

# End /usr/bin/lex
EOF
chmod -v 755 /usr/bin/lex
cd /sources
rm -rf flex-2.5.38

echo "# 6.33. Bison-3.0.2"
tar -Jxf bison-3.0.2.tar.xz
cd bison-3.0.2
./configure --prefix=/usr
make
make install
cd /sources
rm -rf bison-3.0.2

echo "# 6.34. Grep-2.18"
tar -Jxf grep-2.18.tar.xz
cd grep-2.18
./configure --prefix=/usr --bindir=/bin
make
make install
cd /sources
rm -rf grep-2.18

echo "# 6.35. Readline-6.3"
tar -zxf readline-6.3.tar.gz
cd readline-6.3
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr --docdir=/usr/share/doc/readline-6.3 
make SHLIB_LIBS=-lncurses
make install
mv -v /usr/lib/lib{readline,history}.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-6.3
fi
cd /sources
rm -rf readline-6.3

echo "# 6.36. Bash-4.3"
tar -zxf bash-4.3.tar.gz
cd bash-4.3
./configure --prefix=/usr                     \
            --bindir=/bin                     \
            --htmldir=/usr/share/doc/bash-4.3 \
            --without-bash-malloc             \
            --with-installed-readline
make
make install
# exec /bin/bash --login +h
# Don't know of a good way to keep running the script after entering bash here.
cd /sources
rm -rf bash-4.3

echo "# 6.37. Bc-1.06.95"
tar -jxf bc-1.06.95.tar.bz2
cd bc-1.06.95
./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info
make
make install
cd /sources
rm -rf bc-1.06.95

echo "# 6.38. Libtool-2.4.2"
tar -zxf libtool-2.4.2.tar.gz
cd libtool-2.4.2
./configure --prefix=/usr
make
make install
cd /sources
rm -rf libtool-2.4.2

echo "# 6.39. GDBM-1.11"
tar -zxf gdbm-1.11.tar.gz
cd gdbm-1.11
./configure --prefix=/usr --enable-libgdbm-compat
make
make install
cd /sources
rm -rf gdbm-1.11

echo "6.40. Expat-2.1.0"
tar -zxf expat-2.1.0.tar.gz
cd expat-2.1.0
./configure --prefix=/usr
make
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    install -v -dm755 /usr/share/doc/expat-2.1.0
    install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.1.0
fi
cd /sources
rm -rf expat-2.1.0

echo "# 6.41. Inetutils-1.9.2"
tar -zxf inetutils-1.9.2.tar.gz
cd inetutils-1.9.2
echo '#define PATH_PROCNET_DEV "/proc/net/dev"' >> ifconfig/system/linux.h 
./configure --prefix=/usr  \
    --localstatedir=/var   \
    --disable-logger       \
    --disable-syslogd      \
    --disable-whois        \
    --disable-servers
make
make install
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin
cd /sources
rm -rf inetutils-1.9.2

echo "# 6.42. Perl-5.18.2"
tar -jxf perl-5.18.2.tar.bz2
cd perl-5.18.2
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
sed -i -e "s|BUILD_ZLIB\s*= True|BUILD_ZLIB = False|"           \
       -e "s|INCLUDE\s*= ./zlib-src|INCLUDE    = /usr/include|" \
       -e "s|LIB\s*= ./zlib-src|LIB        = /usr/lib|"         \
    cpan/Compress-Raw-Zlib/config.in
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib
make
make install
cd /sources
rm -rf perl-5.18.2

echo "6.43. XML::Parser-2.42_01"
tar -zxf XML-Parser-2.42_01.tar.gz
cd XML-Parser-2.42_01
perl Makefile.PL
make
make install
cd /sources
rm -rf XML-Parser-2.42_01

echo "# 6.44. Autoconf-2.69"
tar -Jxf autoconf-2.69.tar.xz
cd autoconf-2.69
./configure --prefix=/usr
make
make install
cd /sources
rm -rf autoconf-2.69

echo "# 6.45. Automake-1.14.1"
tar -Jxf automake-1.14.1.tar.xz
cd automake-1.14.1
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.14.1
make
make install
cd /sources
rm -rf automake-1.14.1

echo "# 6.46. Diffutils-3.3"
tar -Jxf diffutils-3.3.tar.xz
cd diffutils-3.3
sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in
./configure --prefix=/usr
make
make install
cd /sources
rm -rf diffutils-3.3

echo "# 6.47. Gawk-4.1.0"
tar -Jxf gawk-4.1.0.tar.xz
cd gawk-4.1.0
./configure --prefix=/usr
make
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    mkdir -v /usr/share/doc/gawk-4.1.0
    cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.1.0
fi
cd /sources
rm -rf gawk-4.1.0

echo "# 6.48. Findutils-4.4.2"
tar -zxf findutils-4.4.2.tar.gz
cd findutils-4.4.2
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
make install
mv -v /usr/bin/find /bin
sed -i 's/find:=${BINDIR}/find:=\/bin/' /usr/bin/updatedb
cd /sources
rm -rf findutils-4.4.2

echo "# 6.49. Gettext-0.18.3.2"
tar -zxf gettext-0.18.3.2.tar.gz
cd gettext-0.18.3.2
./configure --prefix=/usr --docdir=/usr/share/doc/gettext-0.18.3.2
make
make install
cd /sources
rm -rf gettext-0.18.3.2

echo "6.50. Intltool-0.50.2"
tar -zxf intltool-0.50.2.tar.gz
cd intltool-0.50.2
./configure --prefix=/usr
make
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.50.2/I18N-HOWTO
fi
cd /sources
rm -rf intltool-0.50.2

echo "6.51. Gperf-3.0.4"
tar -zxf gperf-3.0.4.tar.gz
cd gperf-3.0.4
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.0.4
make
make install
cd /sources
rm -rf gperf-3.0.4

echo "# 6.52. Groff-1.22.2"
tar -zxf groff-1.22.2.tar.gz
cd groff-1.22.2
PAGE=$GROFF_PAPER_SIZE ./configure --prefix=/usr
make
make install
ln -sv eqn /usr/bin/geqn
ln -sv tbl /usr/bin/gtbl
cd /sources
rm -rf groff-1.22.2

echo "# 6.53. Xz-5.0.5"
tar -Jxf xz-5.0.5.tar.xz
cd xz-5.0.5
./configure --prefix=/usr --docdir=/usr/share/doc/xz-5.0.5
make
make install
mv -v /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
cd /sources
rm -rf xz-5.0.5

# 6.54. GRUB-2.00
# We don't use GRUB on ARM

echo "# 6.55. Less-458"
tar -zxf less-458.tar.gz
cd less-458
./configure --prefix=/usr --sysconfdir=/etc
make
make install
cd /sources
rm -rf less-458

echo "# 6.56. Gzip-1.6"
tar -Jxf gzip-1.6.tar.xz
cd gzip-1.6
./configure --prefix=/usr --bindir=/bin
make
make install
mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin
mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin
cd /sources
rm -rf gzip-1.6

echo "# 6.57. IPRoute2-3.12.0"
tar -Jxf iproute2-3.12.0.tar.xz
cd iproute2-3.12.0
sed -i '/^TARGETS/s@arpd@@g' misc/Makefile
sed -i /ARPD/d Makefile
sed -i 's/arpd.8//' man/man8/Makefile
make DESTDIR=
make DESTDIR=              \
     MANDIR=/usr/share/man \
     DOCDIR=/usr/share/doc/iproute2-3.12.0 install
cd /sources
rm -rf iproute2-3.12.0

echo "# 6.58. Kbd-2.0.1"
tar -zxf kbd-2.0.1.tar.gz
cd kbd-2.0.1
patch -Np1 -i ../kbd-2.0.1-backspace-1.patch
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
make
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    mkdir -v /usr/share/doc/kbd-2.0.1
    cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.1
fi
cd /sources
rm -rf kbd-2.0.1

echo "# 6.59. Kmod-16"
tar -Jxf kmod-16.tar.xz
cd kmod-16
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --disable-manpages     \
            --with-xz              \
            --with-zlib
make
make install
make -C man install
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sv ../bin/kmod /sbin/$target
done
ln -sv kmod /bin/lsmod
cd /sources
rm -rf kmod-16

echo "# 6.60. Libpipeline-1.2.6"
tar -zxf libpipeline-1.2.6.tar.gz
cd libpipeline-1.2.6
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr
make
make install
cd /sources
rm -rf libpipeline-1.2.6

echo "# 6.61. Make-4.0"
tar -jxf make-4.0.tar.bz2
cd make-4.0
./configure --prefix=/usr
make
make install
cd /sources
rm -rf make-4.0

echo "# 6.62. Patch-2.7.1"
tar -Jxf patch-2.7.1.tar.xz
cd patch-2.7.1
./configure --prefix=/usr
make
make install
cd /sources
rm -rf patch-2.7.1

echo "# 6.63. Sysklogd-1.5"
tar -zxf sysklogd-1.5.tar.gz
cd sysklogd-1.5
make
make BINDIR=/sbin install
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
cd /sources
rm -rf sysklogd-1.5

echo "# 6.65. Sysvinit-2.88dsf"
tar -jxf sysvinit-2.88dsf.tar.bz2
cd sysvinit-2.88dsf
patch -Np1 -i ../sysvinit-2.88dsf-consolidated-1.patch
make -C src
make -C src install
cd /sources
rm -rf sysvinit-2.88dsf

echo "# 6.66. Tar-1.27.1"
tar -Jxf tar-1.27.1.tar.xz
cd tar-1.27.1
patch -Np1 -i ../tar-1.27.1-manpage-1.patch
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make
make install
if [[ $INSTALL_OPTIONAL_DOCS = 1 ]] ; then
    make -C doc install-html docdir=/usr/share/doc/tar-1.27.1
fi
perl tarman > /usr/share/man/man1/tar.1
cd /sources
rm -rf tar-1.27.1

echo "# 6.67. Texinfo-5.2"
tar -Jxf texinfo-5.2.tar.xz
cd texinfo-5.2
./configure --prefix=/usr
make
make install
# I don't know anybody who wants this... prove me wrong!
# make TEXMF=/usr/share/texmf install-tex
cd /sources
rm -rf texinfo-5.2

echo "# 6.68. Eudev-1.5.3"
tar -zxf eudev-1.5.3.tar.gz
cd eudev-1.5.3
sed -i '/struct ucred/i struct ucred;' src/libudev/util.h
sed -r -i 's|/usr(/bin/test)|\1|' test/udev-test.pl
BLKID_CFLAGS=-I/tools/include       \
BLKID_LIBS='-L/tools/lib -lblkid'   \
./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-split-usr      \
            --enable-libkmod        \
            --enable-rule_generator \
            --disable-introspection \
            --disable-keymap        \
            --disable-gudev         \
            --disable-gtk-doc-html  \
            --with-firmware-path=/lib/firmware
make
mkdir -pv /lib/{firmware,udev/devices/pts}
mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d
make install
tar -jxf ../eudev-1.5.3-manpages.tar.bz2 -C /usr/share
cat > /etc/udev/rules.d/55-lfs.rules << "EOF"
# /etc/udev/rules.d/55-lfs.rules: Rule definitions for LFS.

# Core kernel devices

# This causes the system clock to be set as soon as /dev/rtc becomes available.
SUBSYSTEM=="rtc", ACTION=="add", MODE="0644", RUN+="/etc/rc.d/init.d/setclock start"
KERNEL=="rtc", ACTION=="add", MODE="0644", RUN+="/etc/rc.d/init.d/setclock start"

# Comms devices

KERNEL=="ippp[0-9]*",       GROUP="dialout"
KERNEL=="isdn[0-9]*",       GROUP="dialout"
KERNEL=="isdnctrl[0-9]*",   GROUP="dialout"
KERNEL=="dcbri[0-9]*",      GROUP="dialout"
EOF
cd /sources
rm -rf eudev-1.5.3

echo "# 6.69. Util-linux-2.24.1"
tar -Jxf util-linux-2.24.1.tar.xz
cd util-linux-2.24.1
sed -i -e 's@etc/adjtime@var/lib/hwclock/adjtime@g' \
          $(grep -rl '/etc/adjtime' .)
mkdir -pv /var/lib/hwclock
./configure
make
make install
cd /sources
rm -rf util-linux-2.24.1

echo "# 6.70. Man-DB-2.6.6"
tar -Jxf man-db-2.6.6.tar.xz
cd man-db-2.6.6
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.6.6 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap
make
make install
cd /sources
rm -rf man-db-2.6.6

echo "# 6.71. Vim-7.4"
tar -jxf vim-7.4.tar.bz2
cd vim74
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr --enable-multibyte
make
make install
ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim74/doc /usr/share/doc/vim-7.4
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
syntax on
if (&term == "iterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
cd /sources
rm -rf vim74

echo -e "--------------------------------------------------------------------"
echo -e "\nYou made it! Now there are just a few things left to take care of..."
printf 'Total script time: %s\n' $(timer $total_time)
echo -e "\nYou have not set a root password yet. Go ahead, I'll wait here.\n"
passwd root

echo -e "\nNow about the firmware..."
echo "You probably want to copy the supplied Broadcom libraries to /opt/vc?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) tar -zxf master.tar.gz && cp -rv /sources/firmware-master/hardfp/opt/vc /opt && echo "/opt/vc/lib" >> /etc/ld.so.conf.d/broadcom.conf && ldconfig; break;;
        No ) break;;
    esac
done

echo -e "\nIf you're not going to compile your own kernel you probably want to copy the kernel modules from the firmware package to /lib/modules?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) cp -rv /sources/firmware-master/modules /lib; break;;
        No ) break;;
    esac
done

echo -e "\nLast question, if you want I can mount the boot partition and overwrite the kernel and bootloader with the one you downloaded?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) mount /dev/mmcblk0p1 /boot && cp -rv /sources/firmware-master/boot / && umount /boot; break;;
        No ) break;;
    esac
done

echo -e "\nThere, all done! Now continue reading from \"6.72. About Debugging Symbols\" to make your system bootable."
echo "And don't forget to check out http://www.intestinate.com/pilfs/beyond.html when you're done with your build!"
