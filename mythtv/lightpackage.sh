#!/bin/bash
set -e
scriptname=`readlink -e "$0"`
scriptpath=`dirname "$scriptname"`
#scriptname=`basename "$scriptname" .sh`
cd $scriptpath
sourcedir=$1
subrelease=$2
if [[ "$sourcedir" == "" ]] ; then
    echo Before running this the latest version must be built
    echo with --prefix=/usr --runprefix=/usr and installed
    echo Parameter 1 = install dir
    echo Parameter 2 = subrelease number
    exit 2
fi
sourcedir=`readlink -f "$sourcedir"`
if [[ "$subrelease" == "" ]] ; then subrelease=0 ; fi
packagever=`git describe --dirty|cut -c2-`-$subrelease
installdir=`readlink -f ../../`
arch=`dpkg-architecture -q DEB_TARGET_ARCH`
codename=`lsb_release -c|cut -f 2`
packagename=mythtv-light_${packagever}_${arch}_$codename
echo Package $packagename
if [[ -d $installdir/$packagename ]] ; then
    ls -l $installdir
    echo $installdir/$packagename already exists - run with a subrelease number
    exit 2
fi
rm -rf $installdir/$packagename $installdir/$packagename.deb
#make install INSTALL_ROOT=$installdir/$packagename |& tee $installdir/makeinstall.out
cp -a "$sourcedir/" "$installdir/$packagename/"
mkdir -p $installdir/$packagename/DEBIAN
strip -g -v `find $installdir/$packagename/usr/bin/ -type f -executable`
strip -g -v `find $installdir/$packagename/usr/lib/ -type f -executable`
cat >$installdir/$packagename/DEBIAN/control <<FINISH
Package: mythtv-light
Version: $packagever
Section: graphics
Priority: optional
Architecture: $arch
Essential: no
Installed-Size: `du -B1024 -d0 $installdir/$packagename | cut  -f1`
Maintainer: Peter Bennett <pgbennett@comcast.net>
Depends: libavahi-compat-libdnssd1, libqt5widgets5, libqt5script5, libqt5sql5-mysql, libqt5xml5, libqt5network5, libqt5webkit5, libexiv2-13 | libexiv2-14, pciutils
Conflicts: mythtv-common, mythtv-frontend, mythtv-backend
Homepage: http://www.mythtv.org
Description: MythTV Light
 Light weight package that installs MythTV in one package, front end
 and backend. Does not install database or services. This package runs 
 the front end successfully on Raspberry Pi 2 or better. Backend 
 programs are not recommended to be run on a Raspberry Pi.
FINISH

mkdir -p $installdir/$packagename/usr/share/applications/
cp -f lightpackage/mythtv.desktop $installdir/$packagename/usr/share/applications/
cp -f lightpackage/mythtv-setup.desktop $installdir/$packagename/usr/share/applications/

mkdir -p $installdir/$packagename/usr/share/pixmaps/
cp -f lightpackage/mythtv.png $installdir/$packagename/usr/share/pixmaps/

mkdir -p $installdir/$packagename/usr/share/menu/
cp -f lightpackage/mythtv-frontend $installdir/$packagename/usr/share/menu/

cd $installdir
fakeroot dpkg-deb --build $packagename
echo $PWD
ls -ld ${packagename}*
