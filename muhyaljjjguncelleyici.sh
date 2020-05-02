#!/bin/bash
# Özel Yükleyiciye Özel Jitsi Meet Güncelleyici
# *buntu 16.04+ (LTS) tabanlı sistemler içindir
# © 2020, MUHYAL - https://www.muhyal.com
# GPLv3 ya da sonrası

Blue='\e[0;34m'
Purple='\e[0;35m'
Green='\e[0;32m'
Yellow='\e[0;33m'
Color_Off='\e[0m'
#Yekileri kontrol et
if ! [ $(id -u) = 0 ]; then
   echo "root ya da sudo yetkilerine sahip bir kullanıcı olmalısınız!"
   exit 0
fi
if [ ! -f muhyaljao.sh ]; then
        echo "Lütfen proje klasöründeyken Jitsi güncelleyicisini çalıştırdığınızdan emin olun"
        echo "güncelleyici hataları ile karşılaşabilirsiniz. Çıkış yapılıyor..."
        exit
fi
support="https://www.muhyal.com"
apt_repo="/etc/apt/sources.list.d"
LOC_REC="TBD"
ENABLE_BLESSM="TBD"
CHD_LST="$(curl -sL https://chromedriver.storage.googleapis.com/LATEST_RELEASE)"
CHDB="$(whereis chromedriver | awk '{print$2}')"
DOMAIN="$(ls /etc/prosody/conf.d/ | grep -v localhost | awk -F'.cfg' '{print $1}' | awk '!NF || !seen[$0]++')"
INT_CONF="/usr/share/jitsi-meet/interface_config.js"
jibri_packages="$(grep Package /var/lib/apt/lists/download.jitsi.org_*_Packages | sort -u | awk '{print $2}' | paste -s -d ' ')"
AVATAR="$(grep -r avatar /etc/nginx/sites-*/ 2>/dev/null)"
if [ -f $apt_repo/google-chrome.list ]; then
    google_package=$(grep Package /var/lib/apt/lists/dl.google.com_linux_chrome_deb_dists_stable_main_binary-amd64_Packages | sort -u | cut -d ' ' -f2 | paste -s -d ' ')
else
    echo "Yüklü Google depoları görünmüyor"
fi
if [ -z $CHDB ]; then
	echo "chromedriver yüklü görünmüyor"
else
    CHD_AVB=$(chromedriver -v | awk '{print $2}')
fi

version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

check_jibri() {
if [ "$(dpkg-query -W -f='${Status}' "jibri" 2>/dev/null | grep -c "ok installed")" == "1" ]
then
	systemctl restart jibri
	systemctl restart jibri-icewm
	systemctl restart jibri-xorg
else
	echo "Jibri hizmeti yüklenmemiş"
fi
}

# Hizmetler yeniden başlatılıyor
restart_services() {
	systemctl restart jitsi-videobridge2
	systemctl restart jicofo
	check_jibri
	systemctl restart prosody
}

upgrade_cd() {
if version_gt $CHD_LST $CHD_AVB
then
	echo "Güncelleniyor ..."
	wget https://chromedriver.storage.googleapis.com/$CHD_LST/chromedriver_linux64.zip
	unzip chromedriver_linux64.zip
	sudo cp chromedriver $CHDB
	rm -rf chromedriver chromedriver_linux64.zip
	chromedriver -v
else
	echo "Chromedriver için güncelleme gerekmiyor"
	printf "Mevcut versiyon: ${Green} $CHD_AVB ${Color_Off}\n"
fi
}

update_jitsi_repo() {
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/jitsi-$1.list" \
        -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
    apt-get install -qq --only-upgrade $jibri_packages
}

update_google_repo() {
	if [ -f $apt_repo/google-chrome.list ]; then
    apt-get update -o Dir::Etc::sourcelist="sources.list.d/google-chrome.list" \
        -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
    apt-get install -qq --only-upgrade $google_package
    else
		echo "Google yazılım deposu bulunamadı"
	fi
}

check_lst_cd() {
printf "${Purple}Son Chromedriver sürümü kontrol ediliyor...${Color_Off}\n"
if [ -f $CHDB ]; then
        printf "Mevcut Chromedriver sürümü: ${Yellow} $CHD_AVB ${Color_Off}\n"
        printf "Kullanılabilir Chromedriver sürümü: ${Green} $CHD_LST ${Color_Off}\n"
        upgrade_cd
else
	printf "${Yellow} -> Chromedriver yüklenmemiş görünüyor${Color_Off}\n"
fi
}

printf "${Blue}Jitsi ve bileşenleri güncelleme ve yükseltme${Color_Off}\n"
if [ -f $apt_repo/jitsi-unstable.list ]; then
	update_jitsi_repo unstable
	update_google_repo
	check_lst_cd
elif [ -f $apt_repo/jitsi-stable.list ]; then
	update_jitsi_repo stable
	update_google_repo
	check_lst_cd
else
	echo "Lütfen yazılım depolarınızı kontrol edin, bir şeyler doğru değil."
	exit 1
fi
########################################################################
#                         Değişiklikleri korunuyor                     #
########################################################################
printf "${Purple}========== Statik Avatar  ==========${Color_Off}\n"
if [[ -z $AVATAR ]]; then
	echo "Taşınıyor..."
	
else
	echo "Statik avatar ayarlanıyor..."
	sed -i "/RANDOM_AVATAR_URL_PREFIX/ s|false|\'http://$DOMAIN/avatar/\'|" $INT_CONF
	sed -i "/RANDOM_AVATAR_URL_SUFFIX/ s|false|\'.png\'|" $INT_CONF
fi

printf "${Purple}========== Destek bağlantısı  ==========${Color_Off}\n"
if [[ -z $support ]]; then
	echo "Taşınıyor..."
else
	echo "Destek özel bağlantısı ayarlanıyor..."
	sed -i "s|https://jitsi.org/live|$support|g" $INT_CONF
fi

printf "${Purple}========== Yerel Kaydı Yeniden Etkinleştir  ==========${Color_Off}\n"
if [ $LocRec = on ]; then
        echo "Yerel kayıt özelliği ayarlanıyor..."
        sed -i "s|'tileview'|'tileview', 'localrecording'|" $INT_CONF
else
        echo "Taşınıyor..."
fi

printf "${Purple}========== Arka planı bulanıklaştırma ayarı  ==========${Color_Off}\n"
sed -i "s|'videobackgroundblur', ||" $INT_CONF

restart_services


########################################################################
#                      Jitsi arayüz özelleştirmeleri                   #
########################################################################
if [ $ENABLE_BLESSM = on ]; then
	bash $PWD/muhyaljao.sh
fi
printf "${Blue}Hepsi tamamlandı \o/! Destek almak için: https://www.muhyal.com ${Color_Off}\n"
