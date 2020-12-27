#!/bin/bash

# Install vips for image processing
sudo apt -y install libvips42

# Install ffmpeg for video/audio processing
sudo apt -y install ffmpeg

# Install ghostscript for converting PDFs
sudo apt -y install ghostscript

# Install ghostscript for converting office documents and text to PDFs
sudo apt -y install libreoffice

# Uncomment the code below if we want to use a newer version of libreoffice
# LIBREOFFICE_VERSION=7.1.1.2
# LIBREOFFICE_DOWNLOAD_DIR=/tmp/downloads/libreoffice
# # We're caching the libreoffice download because it can be VERY slow (sometimes 8+ minutes for download)
# if [ ! -d "$LIBREOFFICE_DOWNLOAD_DIR" ]; then
#   echo "No cached directory found at: $LIBREOFFICE_DOWNLOAD_DIR"
#   mkdir -p $LIBREOFFICE_DOWNLOAD_DIR
#   cd $LIBREOFFICE_DOWNLOAD_DIR
#   wget "https://downloadarchive.documentfoundation.org/libreoffice/old/${LIBREOFFICE_VERSION}/deb/x86_64/LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_deb.tar.gz"
# fi
# cd $LIBREOFFICE_DOWNLOAD_DIR
# tar -xf "LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_deb.tar.gz"
# cd "LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_deb/DEBS"
# sudo dpkg -i *.deb # this installs soffice binary at /usr/local/bin/libreoffice7.1
# sudo ln -s /usr/local/bin/libreoffice7.1 /usr/local/bin/soffice # put binary named 'soffice' on path

# Download tika for text extraction
TIKA_VERSION=1.25
TIKA_DOWNLOAD_DIR=/tmp/downloads/tika
# We're caching the tika download
if [ ! -d "$TIKA_DOWNLOAD_DIR" ]; then
  echo "No cached directory found at: $TIKA_DOWNLOAD_DIR"
  mkdir -p $TIKA_DOWNLOAD_DIR
  cd $TIKA_DOWNLOAD_DIR
  wget "https://archive.apache.org/dist/tika/tika-app-${TIKA_VERSION}.jar"
  mv tika-app-${TIKA_VERSION}.jar tika-app.jar
fi
