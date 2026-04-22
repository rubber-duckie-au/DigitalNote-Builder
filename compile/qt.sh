#! /usr/bin/env bash

cd temp

tar -vxf ../../../download/qt-everywhere-opensource-src-5.15.7.tar.xz -X ../../../patch/exclude_qt.txt

cd qt-everywhere-src-5.15.7

cp ../../../../patch/qfreetypefontdatabase_p.h qtbase/include/QtFontDatabaseSupport/5.15.7/QtFontDatabaseSupport/private
cp ../../../../patch/qwindowsfontdatabase_ft_p.h qtbase/include/QtFontDatabaseSupport/5.15.7/QtFontDatabaseSupport/private
cp ../../../../patch/qwindowsfontdatabase_p.h qtbase/include/QtFontDatabaseSupport/5.15.7/QtFontDatabaseSupport/private
cp ../../../../patch/qfontengine_ft_p.h qtbase/include/QtFontDatabaseSupport/5.15.7/QtFontDatabaseSupport/private
cp ../../../../patch/qwindowsnativeimage_p.h qtbase/include/QtFontDatabaseSupport/5.15.7/QtFontDatabaseSupport/private
cp ../../../../patch/qwindowsfontengine_p.h qtbase/include/QtFontDatabaseSupport/5.15.7/QtFontDatabaseSupport/private

cp ../../../../patch/qwindowsguieventdispatcher_p.h qtbase/include/QtEventDispatcherSupport/5.15.7/QtEventDispatcherSupport/private

cp ../../../../patch/qwindowsuiawrapper_p.h qtbase/include/QtWindowsUIAutomationSupport/5.15.7/QtWindowsUIAutomationSupport/private

cp ../../../../patch/qiosurfacegraphicsbuffer.h qtbase/src/plugins/platforms/cocoa

./configure -static -release -opensource -confirm-license -prefix "$PWD/../../libs/qt-5.15.7" -qt-zlib -qt-libpng -qt-libjpeg -qt-freetype -qt-pcre -no-opengl -skip qtimageformats -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d -skip qtdeclarative -skip qtdoc -skip qtgamepad -skip qtlocation -skip qtlottie -skip qtmacextras -skip qtmultimedia -skip qtnetworkauth -skip qtpurchasing -skip qtquick3d -skip qtquickcontrols -skip qtquickcontrols2 -skip qtquicktimeline -skip qtremoteobjects -skip qtscript -skip qtsensors -skip qtspeech -skip qtsvg -skip qtwayland -skip qtwebglplugin -skip qtvirtualkeyboard -skip qtwebchannel -skip qtwebsockets -skip qtwebview -skip webengine -make libs -nomake tools -nomake examples -nomake tests $1
make $2
make install