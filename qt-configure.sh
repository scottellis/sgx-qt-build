#!/bin/bash

./configure -prefix /opt/qte \
  -embedded arm \
  -xplatform qws/linux-overo-storm-g++ \
  -no-glib -no-cups -no-nis -no-largefile -no-accessibility 
  -no-openssl -no-gtkstyle \
  -no-3dnow -no-avx -no-mmx -no-sse -no-sse2 -no-sse3 -no-sse4.1 -no-sse4.2 \
  -little-endian -no-qt3support \
  -opensource -confirm-license \
  -D QT_NO_QWS_CURSOR -D QT_QWS_CLIENTBLIT \
  -depths 16,24,32 \
  -qt-mouse-pc -plugin-mouse-pc \
  -qt-mouse-tslib -plugin-mouse-tslib \
  -opengl es2 \
  -qt-gfx-linuxfb -plugin-gfx-powervr

