#!/bin/bash
# Jitsi Meet Arayüz Özelleştirmeleri
# *buntu 16.04+ (LTS) tabanlı sistemler içindir
# © 2020, MUHYAL. https://www.muhyal.com
# GPLv3 ya da sonrası

CSS_FILE="/usr/share/jitsi-meet/css/all.css"
TITLE_FILE="/usr/share/jitsi-meet/title.html"
INT_CONF="/usr/share/jitsi-meet/interface_config.js"
BUNDLE_JS="/usr/share/jitsi-meet/libs/app.bundle.min.js"
#
JM_IMG_PATH="/usr/share/jitsi-meet/images/"
WTM2_PATH="$JM_IMG_PATH/watermark2.png"
FICON_PATH="$JM_IMG_PATH/favicon2.ico"
#
APP_NAME="Konferanslar"
MOBILE_APP_NAME="Konferanslar"
PART_USER="Katılımcı"
LOCAL_USER="Ben"
#
SEC_ROOM="TBD"
echo '
#--------------------------------------------------
# Jitsi Meet Arayüz Özelleştirmeleri
#--------------------------------------------------
'
#Watermark
if [ ! -f $WTM2_PATH ]; then
	cp watermark2.png $WTM2_PATH
else
	echo "watermark2 dosyası zaten mevcut, atlanıyor..."
fi
#Favicon
if [ ! -f $FICON_PATH ]; then
	cp favicon2.ico $FICON_PATH
else
	echo "favicon2 dosyası zaten mevcut, atlanıyor..."
fi

#Özel İkonları Temizle
sed -i "s|watermark.png|watermark2.png|g" $CSS_FILE
sed -i "s|favicon.ico|favicon2.ico|g" $TITLE_FILE
sed -i "s|jitsilogo.png|watermark2.png|g" $TITLE_FILE
sed -i "s|logo-deep-linking.png|watermark2.png|g" $BUNDLE_JS

#Jitsi Meet logosu ve bağlantısını devredışı bırak
if [ -z $(grep -nr ".leftwatermark{display:none" $CSS_FILE) ]; then
sed -i "s|.leftwatermark{|.leftwatermark{display:none;|" $CSS_FILE
fi

#Kanal başlığını özelleştir
sed -i "s|Jitsi Meet|$APP_NAME|g" $TITLE_FILE
sed -i "s| powered by the Jitsi Videobridge||g" $TITLE_FILE
sed -i "21,32 s|Jitsi Meet|$APP_NAME|g" $INT_CONF
sed -i "/appNotInstalled/ s|{{app}}|$MOBILE_APP_NAME|" /usr/share/jitsi-meet/lang/*

#Özel arayüz değişiklikleri
echo "
Bu işlem mevcut destek bağlantılarınız kaldıracaktır.
"
sed -i "s|Fellow Jitster|$PART_USER|g" $INT_CONF
sed -i "s|'me'|'$LOCAL_USER'|" $INT_CONF
sed -i "s|LIVE_STREAMING_HELP_LINK: .*|LIVE_STREAMING_HELP_LINK: '#',|g" $INT_CONF
sed -i "s|SUPPORT_URL: .*|SUPPORT_URL: '#',|g" $INT_CONF
