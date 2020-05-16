#!/bin/bash
# Jitsi - Jibri - Jigasi Yükleyici
# *buntu 16.04+ (LTS) tabanlı sistemler içindir
# © 2020, MUHYAL - https://www.muhyal.com
# GPLv3 ya da sonrası
{
echo "Başlatıldı: $(date +'%Y-%m-%d %H:%M:%S')" >> muhyaljjjyukleyici.log

while getopts m: option
do
	case "${option}"
	in
		m) MODE=${OPTARG};;
		\?) echo "Kullanım şekli: sudo ./muhyaljjjyukleyici.sh [-m debug]" && exit;;
	esac
done

#DEBUG
if [ "$MODE" = "debug" ]; then
set -x
fi

# SİSTEM YÜKLEMESİ
JITSI_REPO=$(apt-cache policy | grep http | grep jitsi | grep stable | awk '{print $3}' | head -n 1 | cut -d "/" -f1)
CERTBOT_REPO=$(apt-cache policy | grep http | grep certbot | head -n 1 | awk '{print $2}' | cut -d "/" -f4)
APACHE_2=$(dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -c "ok installed")
NGINX=$(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "ok installed")
DIST=$(lsb_release -sc)
GOOGL_REPO="/etc/apt/sources.list.d/dl_google_com_linux_chrome_deb.list"
PROSODY_REPO=$(apt-cache policy | grep http | grep prosody| awk '{print $3}' | head -n 1 | cut -d "/" -f2)

if [ $DIST = flidas ]; then
DIST="xenial"
fi
if [ $DIST = etiona ]; then
DIST="bionic"
fi
install_ifnot() {
if [ "$(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")" == "1" ]; then
	echo " $1 yüklenmiş, atlanıyor..."
    else
    	echo -e "\n---- $1 Yükleniyor ----"
		apt-get -yq2 install $1
fi
}
check_serv() {
if [ "$APACHE_2" -eq 1 ]; then
	echo "
Web sunucusu zaten yüklenmiş!
"
exit
elif [ "$NGINX" -eq 1 ]; then

echo "
Web sunucusu zaten yüklenmiş!
"

else
	echo "
Nginx web sunucusu olarak yükleniyor!
"
	install_ifnot nginx
fi
}
check_snd_driver() {
modprobe snd-aloop
echo "snd-aloop" >> /etc/modules
if [ "$(lsmod | grep snd_aloop | head -n 1 | cut -d " " -f1)" = "snd_aloop" ]; then
	echo "
#--------------------------------------------------
# Sistem ses sürücüleri iyi görünüyor.
#--------------------------------------------------"
else
	echo "
#--------------------------------------------------
# Kurulumdan sonra ses sürücünüz yüklenemeyebilir
# tamamlandığı zaman ve sunucunuz yeniden başlatıldığında emin olmak için şu komutu çalıştırın: lsmod | grep snd_aloop
# Sorun devam ediyorsa: https://www.muhyal.com/t/45
#--------------------------------------------------"
read -n 1 -s -r -p "Devam etmek için bir tuşa basınız..."$'\n'
fi
}
update_certbot() {
	if [ "$CERTBOT_REPO" = "certbot" ]; then
	echo "
Certbot repo zaten sisteminizde bulunuyor!
Güncellemeler kontrol ediliyor...
"
	apt-get -q2 update
	apt-get -yq2 dist-upgrade
else
	echo "
Son güncellemeleri almak için certbot (letsencrypt) PPA repo ekleniyor
"
	echo "deb http://ppa.launchpad.net/certbot/certbot/ubuntu $DIST main" > /etc/apt/sources.list.d/certbot.list
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 75BCA694
	apt-get -q2 update
	apt-get -yq2 dist-upgrade
fi
}

clear
echo '
########################################################################
               Jitsi/Jibri/Jigasi Yükleyicisine Hoş Geldiniz
########################################################################
MUHYAL (Muhammed Yalçınkaya) tarafından sunulmuştur - https://www.muhyal.com
Betikle ilgili destek almak için: https://www.muhyal.com/t/45
Manevi destekleri için özel teşekkürler: Ferdi Kılıç :)

MUHYAL desteklemek için:
- Youtube: https://www.youtube.com/channel/UCE64wWpZ9FebjnpZ8ndcW-Q
- Twitter: https://twitter.com/muhyal
- Facebook: https://www.facebook.com/muhyal
- Instagram: https://www.instagram.com/muhyal

Ön koşullar:
- Nextcloud için yapılandırılmış DNS A kaydı (Örn: nextcloud.sizinalanadiniz.com)
- Jitsi Meet için yapılandırılmış DNS A kaydı (Örn: konferans.sizinalanadiniz.com)
- Temiz Ubuntu 18.04 LTS kurulu bir sunucu
- DNS kayıtları yapılandırılmış bir alan adı (Let’s Encrypt SSL sertifikası için)
- ACME (SSL) etkileşimi ve doğrulama işlemi 443 portu açık olmalıdır
- Konferans kaydı için minimum 8 GB RAM / 2 CPU / 10 GB ve üzeri SSD depolama alanı
- (Opsiyonel) Dropbox geliştirici konsolunda oluşturulmuş bir uygulama ve API bilgileri
- (Opsiyonel) Sesten metne çeviri için Google Cloud ve yapılandırılmış bir faturalandırma hesabı
- Çalışır durumda web kamerası ve mikrofon
- root ya da sudo yetkilerine sahip bir kullanıcı ile SSH erişimi

Betik özellikleri:
- Nginx & Let’s Encrypt için mobil uygulamalardaki sertifika sorunu giderildi.
- Kurulum kayıtları eklendi (muhyaljjjyukleyici.log).
- Jibri Kayıt ve YouTube Stream özelliği eklendi.
- Jigasi Transcription özelliği eklendi.
- Arayüz özelleştirmeleri yeni baştan yapılandırıldı (watermark.png, favicon.ico, jitsilogo.png, logo-deep-linking.png…).
- Yükleyiciye özel güncelleyici betiği eklendi.
- Prosody kullanıcılarını listelemek için ek modül eklendi.
- Web sunucusu Nginx olarak ayarlandı.
- Geçersiz TLS sertifikalarını (TLSv1.0/1.1) kaldırma işlemi eklendi.
- LE SSL kurulumu ve yapılandırması düzenlendi.
- RAND_load_file hatası çözüldü.
- JRA ile Nextcloud (Nextcloud & MariaDB, OPcache, memcache, Redis, PHP 7.4 kurulumları ve yapılandırmaları dahil) entegrasyonu eklendi.
- scssphp/src/Compiler.php yaması eklendi (patch_425_3dty.patch)
- Secure Rooms özelliği düzenlendi.
- /etc/jitsi/meet/$DOMAIN-config.js optimizasyonları yapıldı.
- Yapılandırma dosyası kontrolü eklendi.
- Nadiren yaşanan Jibri bağlantı sorunu kalıcı olarak çözüldü.
- Dropbox özelliği düzenlendi.
- Statik avatar yapılandırması geliştirildi.
- Yerel ses kaydı özelliği yapılandırıldı.
- Güncelleyici yeni yapılandırmalara göre ayarlandı.
- Stabil olmayan Jitsi deposu stabil olan depo ile değiştirildi.
- HSTS kontrolü eklendi.
- Donanımsal ses sorunları tespiti eklendi.
- Chromedriver ve web sunucusu kontrolü eklendi.
- Kanal başlığı düzenleme eklendi.
- Destek bağlantıları kaldırıldı.
- İşletim sistemi desteği kontrolü eklendi.
ve daha bir çok burada belirtilmeyen yapılandırma ve optimizasyon yapıldı.

Detaylı bilgi ve destek için https://www.muhyal.com/t/45
'
read -n 1 -s -r -p "Kuruluma devam etmek için herhangi bir tuşa basın..."

#root yetkilerini kontrol et
if ! [ $(id -u) = 0 ]; then
   echo "root kullanıcısı olmanız veya sudo ayrıcalıklarına sahip olmanız gerekir!"
   exit 0
fi
if [ "$DIST" = "xenial" ] || [ "$DIST" = "bionic" ]; then
	echo "OS: $(lsb_release -sd)
Harika! Bu işletim sistemi destekleniyor!"
else
	echo "OS: $(lsb_release -sd)
Üzgünüm, bu işletim sistemi desteklenmiyor... exiting"
	exit
fi
#Ubuntu 18.04 LTS ya da 16.04 üzeri önerilir
if [ "$DIST" = "xenial" ]; then
echo "$(lsb_release -sc), şu an uyumlu ve işlevsel olsa bile.
Daha uzun destek süresi ve güvenlik nedenleriyle bir sonraki (LTS) sürümü kullanmanızı öneriyoruz."
read -n 1 -s -r -p "Devam etmek için bir tuşa basın..."
fi
# Jitsi-Meet Repo
echo "Jitsi yazılım doğrulama anahtarları ekleniyor..."
if [ "$JITSI_REPO" = "stable" ]; then
	echo "Jitsi stabil sürüm deposu zaten yüklenmiş."
else
<<<<<<< HEAD
	echo 'deb https://download.jitsi.org stable/' > /etc/apt/sources.list.d/jitsi-stable.list
=======
	echo 'deb http://download.jitsi.org unstable/' > /etc/apt/sources.list.d/jitsi-unstable.list
>>>>>>> 2dd120e... Ek Jibri node ayarı
	wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add -
fi
#LE SSL için
while [[ $LE_SSL != yes && $LE_SSL != no ]]
do
read -p "> Let's Encrypt SSL sertifikası kullanmak istiyor musunuz?: (yes ya da no)"$'\n' -r LE_SSL
if [ $LE_SSL = yes ]; then
	echo "Let's Encrypt SSL varsayılan olarak yüklenecektir."
elif [ $LE_SSL = no ]; then
	echo "Bu işlem için daha sonra seçim yapmanıza izin verilecektir."
fi
done

# Gereksinimler
echo "Bu biraz zaman alabilir sistem gereksinimlerini yükleyerek başlayacağız, lütfen sabırlı olun..."
apt-get update -q2
apt-get dist-upgrade -yq2

apt-get -y install \
				bmon \
				curl \
				ffmpeg \
				git \
				htop \
				letsencrypt \
				linux-image-generic-hwe-$(lsb_release -r|awk '{print$2}') \
				unzip \
				wget

check_serv

echo "
#--------------------------------------------------
# Jitsi Framework Yükle
#--------------------------------------------------
"
if [ "$LE_SSL" = "yes" ]; then
echo "set jitsi-meet/cert-choice	select	Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)" | debconf-set-selections
fi
apt-get -y install \
				jitsi-meet \
				jibri \
				openjdk-8-jre-headless

# RAND_load_file hatasının çözümü
#https://github.com/openssl/openssl/issues/7754#issuecomment-444063355
sed -i "/RANDFILE/d" /etc/ssl/openssl.cnf

echo "
#--------------------------------------------------
# NodeJS Yükle
#--------------------------------------------------
"
if [ "$(dpkg-query -W -f='${Status}' nodejs 2>/dev/null | grep -c "ok")" == "1" ]; then
		echo "Nodejs zaten yüklü, atlanıyor..."
    else
		curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
		apt-get install -yq2 nodejs
		echo "nodejs esprima paketi yükleniyor..."
		npm install -g esprima
fi

if [ "$(npm list -g esprima 2>/dev/null | grep -c "empty")" == "1" ]; then
	echo "nodejs esprima paketi yükleniyor..."
	npm install -g esprima
elif [ "$(npm list -g esprima 2>/dev/null | grep -c "esprima")" == "1" ]; then
	echo "Gayet iyi. Esprima paketi zaten yüklenmiş."
fi

# Google repo ayarlanıyor
echo "snd-aloop" | tee -a /etc/modules
check_snd_driver
CHD_VER=$(curl -sL https://chromedriver.storage.googleapis.com/LATEST_RELEASE)
GCMP_JSON="/etc/opt/chrome/policies/managed/managed_policies.json"

echo "# Google Chrome / ChromeDriver yükleniyor."
if [ -f $GOOGL_REPO ]; then
echo "Google repo zaten ayarlanmış."
else
echo "Google Chrome yükleniyor."
	wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
	echo "deb http://dl.google.com/linux/chrome/deb/ stable main" | tee $GOOGL_REPO
fi
apt-get -q2 update
apt-get install -yq2 google-chrome-stable
rm -rf /etc/apt/sources.list.d/dl_google_com_linux_chrome_deb.list

if [ -f /usr/local/bin/chromedriver ]; then
	echo "Chromedriver zaten yüklenmiş."
else
	echo "Chromedriver yükleniyor."
	wget -q https://chromedriver.storage.googleapis.com/$CHD_VER/chromedriver_linux64.zip -O /tmp/chromedriver_linux64.zip
	unzip /tmp/chromedriver_linux64.zip -d /usr/local/bin/
	chown root:root /usr/local/bin/chromedriver
	chmod 0755 /usr/local/bin/chromedriver
	rm -rf /tpm/chromedriver_linux64.zip
fi

echo "
Google yazılımlarının çalışabilirliğini kontrol et...
"
/usr/bin/google-chrome --version
/usr/local/bin/chromedriver --version | awk '{print$1,$2}'
echo "
Chrome uyarısı kaldırılıyor...
"
mkdir -p /etc/opt/chrome/policies/managed
echo '{ "CommandLineFlagSecurityWarningsEnabled": false }' >> $GCMP_JSON

echo '
########################################################################
                    Jibri ayarlanıyor...
########################################################################
'
# MEET / JIBRI YÜKLEME
DOMAIN=$(ls /etc/prosody/conf.d/ | grep -v localhost | awk -F'.cfg' '{print $1}' | awk '!NF || !seen[$0]++')
WS_CONF=/etc/nginx/sites-enabled/$DOMAIN.conf
JB_AUTH_PASS="$(tr -dc "a-zA-Z0-9#*=" < /dev/urandom | fold -w 10 | head -n1)"
JB_REC_PASS="$(tr -dc "a-zA-Z0-9#*=" < /dev/urandom | fold -w 10 | head -n1)"
PROSODY_FILE=/etc/prosody/conf.d/$DOMAIN.cfg.lua
PROSODY_SYS=/etc/prosody/prosody.cfg.lua
JICOFO_SIP=/etc/jitsi/jicofo/sip-communicator.properties
MEET_CONF=/etc/jitsi/meet/$DOMAIN-config.js
CONF_JSON=/etc/jitsi/jibri/config.json
DIR_RECORD=/var/jitsikayitlari
REC_DIR=/home/jibri/finalize_recording.sh
JB_NAME="Jibri Oturumları"
LE_RENEW_LOG="/var/log/letsencrypt/renew.log"
MOD_LISTU="https://prosody.im/files/mod_listusers.lua"
MOD_LIST_FILE="/usr/lib/prosody/modules/mod_listusers.lua"
ENABLE_SA="yes"
#Jitsi Meet dil seçimi
echo "## Jitsi Meet dil yapılandırması ##
Jitsi Meet web arayüzü bu dili kullanacak şekilde ayarlanacaktır.
Tüm dil seçenekleri için: https://github.com/jitsi/jitsi-meet/blob/master/lang/languages.json
"
read -p "Bir dil seçimi yapabilirsiniz ancak varsayılan dil olan İngilizce ile devam etmeniz önerilir. Enter ile devam edebilirsiniz :"$'\n' -r LANG
while [[ -z $SYSADMIN_EMAIL ]]
do
read -p "Sistem yöneticisi e-posta adresi (Bu zorunlu bir alandır):"$'\n' -r SYSADMIN_EMAIL
done

#Geçersiz TLS kaldırma işlemi
while [[ $DROP_TLS1 != yes && $DROP_TLS1 != no ]]
do
read -p "> Güvenlik sorunu oluşturabilecek TLSv1.0/1.1 kaldırılsın mı (Önerilir!): (yes ya da no)"$'\n' -r DROP_TLS1
if [ $DROP_TLS1 = no ]; then
	echo "TLSv1.0/1.1 olduğu gibi kalacak."
elif [ $DROP_TLS1 = yes ]; then
	echo "TLSv1.0/1.1 kaldırılacak."
fi
done
#SSL LE
if [ "$LE_SSL" = "yes" ]; then
	ENABLE_SSL=yes
else
	while [[ $ENABLE_SSL != yes && $ENABLE_SSL != no ]]
	do
	read -p "> Alan adınıza bir Let's Encrypt SSL sertifikası kurmak istiyor musunuz? (yes ya da no)"$'\n' -r ENABLE_SSL
	if [ $ENABLE_SSL = no ]; then
		echo "Daha sonra letsencrypt.sh çalıştırarak sertifikanızı kurabilirsiniz."
	elif [ $ENABLE_SSL = yes ]; then
		echo "SSL sertifikanız otomatik olarak kurulacaktır."
	fi
	done
fi
#Dropbox
while [[ $ENABLE_DB != yes && $ENABLE_DB != no ]]
do
read -p "Dropbox özelliği aktif edilsin mi: (yes ya da no)"$'\n' -r ENABLE_DB
if [ $ENABLE_DB = no ]; then
	echo "Dropbox etkinleştirilmedi."
elif [ $ENABLE_DB = yes ]; then
	read -p "Dropbox uygulama anahtarını yazın: "$'\n' -r DB_CID
fi
done
#Arayüz özelleştirmeleri
while [[ $ENABLE_BLESSM != yes && $ENABLE_BLESSM != no ]]
do
read -p "> Özel arayüz yapılandırmaları uygulansın mı?: (yes ya da no)"$'\n' -r ENABLE_BLESSM
if [ $ENABLE_BLESSM = no ]; then
	echo "Özelleştirmeler uygulanmayacak."
elif [ $ENABLE_BLESSM = yes ]; then
	echo "Özelleştirmeler uygulanacak."
fi
done
echo "İhtiyacınız varsa bazı kullanıcı arayüzü çevirilerini yerelleştirmek için bir dakikanızı ayırın."
#Katılımcı
echo "> 'Participant' normalde Katılımcı anlamına gelir. Siz neye çevirmek istersiniz?"
read -p "Varsayılan değer için boş bırakıp devam edin: " L10N_PARTICIPANT
#Me
echo "> 'me' normalde Ben anlamına gelir. Siz neye çevirmek istersiniz?"
read -p "Varsayılan değer için boş bırakıp devam edin: " L10N_ME
#Hoş geldiniz sayfası
while [[ $ENABLE_WELCP != yes && $ENABLE_WELCP != no ]]
do
read -p "> Hoş geldiniz sayfası kapatılsın mı: (yes ya da no)"$'\n' -r ENABLE_WELCP
if [ $ENABLE_WELCP = yes ]; then
	echo "Hoş geldiniz sayfası kapatıldı."
elif [ $ENABLE_WELCP = no ]; then
	echo "Hoş geldiniz sayfası etkin bırakıldı."
fi
done
#Statik avatar yapılandırması
while [[ "$ENABLE_SA" != "yes" && "$ENABLE_SA" != "no" ]]
do
read -p "> Statik avatar yapılandırılsın mı?: (yes ya da no)"$'\n' -r ENABLE_SA
if [ "$ENABLE_SA" = "no" ]; then
	echo "Statik avatar yapılandırıldı"
elif [ "$ENABLE_SA" = "yes" ]; then
	echo "Statik avatar yapılandırılmadı"
fi
done
#Yerel ses kaydı
while [[ "$ENABLE_LAR" != "yes" && "$ENABLE_LAR" != "no" ]]
do
read -p "> Yerel ses kaydı özelliği yapılandırılsın mı?: (yes ya da no)"$'\n' -r ENABLE_LAR
if [ "$ENABLE_LAR" = "no" ]; then
	echo " Yerel ses kaydı özelliği yapılandırılmadı"
elif [ "$ENABLE_LAR" = "yes" ]; then
	echo " Yerel ses kaydı özelliği yapılandırıldı"
fi
done
#Secure room yapılandırması
while [[ "$ENABLE_SC" != "yes" && "$ENABLE_SC" != "no" ]]
do
read -p "> Secure room yapılandırılsın mı?: (yes ya da no)"$'\n' -r ENABLE_SC
if [ "$ENABLE_SC" = "no" ]; then
	echo "-- Secure room yapılandırılmadı"
elif [ "$ENABLE_SC" = "yes" ]; then
	echo "-- Secure room yapılandırıldı"
	read -p "Secure room için moderatör kullanıcı adı: "$'\n' -r SEC_ROOM_USER
	read -p "Secure room için moderatör şifresi: "$'\n' -r SEC_ROOM_PASS
fi
done
#Jibri Records Access (JRA) - Nextcloud entegrasyonu
while [[ $ENABLE_NC_ACCESS != yes && $ENABLE_NC_ACCESS != no ]]
do
read -p "> Jibri Records Access ile Nextcloud entegre edilsin mi? (yes ya da no)
( Detaylı bilgi için: https://www.muhyal.com/t/45 )"$'\n' -r ENABLE_NC_ACCESS
if [ $ENABLE_NC_ACCESS = no ]; then
	echo "JRA - Nextcloud yapılandırılmadı."
elif [ $ENABLE_NC_ACCESS = yes ]; then
	echo "JRA - Nextcloud yapılandırıldı."
fi
done
#Jigasi
while [[ $ENABLE_TRANSCRIPT != yes && $ENABLE_TRANSCRIPT != no ]]
do
read -p "> Jigasi Transcription kurulumunu yapmak istiyor musunuz?: (yes ya da no)
( Detaylı bilgi için: https://www.muhyal.com/t/45 )"$'\n' -r ENABLE_TRANSCRIPT
if [ $ENABLE_TRANSCRIPT = no ]; then
	echo "Jigasi Transcription etkinleştirilmedi."
elif [ $ENABLE_TRANSCRIPT = yes ]; then
	echo "Jigasi Transcription aktifleştirildi."
fi
done
#Yapılandırmaları başlat
echo '
########################################################################
                  Jitsi Framework yapılandırmaları
########################################################################
'
JibriBrewery=JibriBrewery
INT_CONF="/usr/share/jitsi-meet/interface_config.js"
WAN_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

ssl_wa() {
systemctl stop $1
	letsencrypt certonly --standalone --renew-by-default --agree-tos --email $5 -d $6
	sed -i "s|/etc/jitsi/meet/$3.crt|/etc/letsencrypt/live/$3/fullchain.pem|" $4
	sed -i "s|/etc/jitsi/meet/$3.key|/etc/letsencrypt/live/$3/privkey.pem|" $4
systemctl restart $1
	#Cron ekle
	crontab -l | { cat; echo "@weekly certbot renew --${2} > $LE_RENEW_LOG 2>&1"; } | crontab -
	crontab -l
}

enable_letsencrypt() {
if [ "$ENABLE_SSL" = "yes" ]; then
echo '
########################################################################
                    LetsEncrypt ayarlanıyor...
########################################################################
'
# upstream sorunu çözülene kadar pasif durumdadır
#bash /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh

update_certbot

else
echo "SSL yüklemesi atlandı."
fi
}

check_jibri() {
if [ "$(dpkg-query -W -f='${Status}' "jibri" 2>/dev/null | grep -c "ok installed")" == "1" ]
then
	systemctl restart jibri
	systemctl restart jibri-icewm
	systemctl restart jibri-xorg
else
	echo "Jibri hizmeti yüklenmedi."
fi
}

# Hizmetler yeniden başlatılıyor
restart_services() {
	systemctl restart jitsi-videobridge2
	systemctl restart jicofo
	systemctl restart prosody
	check_jibri
}

# Jibri ayarlanıyor
## PROSODY
cat  << MUC-JIBRI >> $PROSODY_FILE
-- internal muc component, meant to enable pools of jibri and jigasi clients
Component "internal.auth.$DOMAIN" "muc"
    modules_enabled = {
      "ping";
    }
    storage = "null"
    muc_room_cache_size = 1000
MUC-JIBRI

cat  << REC-JIBRI >> $PROSODY_FILE
VirtualHost "recorder.$DOMAIN"
  modules_enabled = {
    "ping";
  }
  authentication = "internal_plain"
REC-JIBRI

#Jibri bağlantı hatalarını çöz
sed -i "s|c2s_require_encryption = .*|c2s_require_encryption = false|" $PROSODY_SYS
sed -i "/c2s_require_encryption = false/a \\
\\
consider_bosh_secure = true" $PROSODY_SYS
if [ ! -z $L10N_PARTICIPANT ]; then
	sed -i "s|PART_USER=.*|PART_USER=\"$L10N_PARTICIPANT\"|" muhyaljao.sh
fi
if [ ! -z $L10N_ME ]; then
	sed -i "s|LOCAL_USER=.*|LOCAL_USER=\"$L10N_ME\"|" muhyaljao.sh
fi
if [ ! -f $MOD_LIST_FILE ]; then
echo "
-> Prosody kullanıcılarını listelemek için ek modül ekleniyor...
"
curl -s $MOD_LISTU > $MOD_LIST_FILE

echo "Kullanıcıları alttaki komutla listeyebilirsiniz:
prosodyctl mod_listusers
"
else
echo "Kullanıcıları listelemek için Prosody desteği yapılandırılmış.
Kontrol etmek için: prosodyctl mod_listusers
"
fi

### Prosody kullanıcıları
prosodyctl register jibri auth.$DOMAIN $JB_AUTH_PASS
prosodyctl register recorder recorder.$DOMAIN $JB_REC_PASS

## JICOFO
# /etc/jitsi/jicofo/sip-communicator.properties
cat  << BREWERY >> $JICOFO_SIP
#org.jitsi.jicofo.auth.URL=XMPP:$DOMAIN
org.jitsi.jicofo.jibri.BREWERY=$JibriBrewery@internal.auth.$DOMAIN
org.jitsi.jicofo.jibri.PENDING_TIMEOUT=90
#org.jitsi.jicofo.auth.DISABLE_AUTOLOGIN=true
BREWERY

# Jibri optimizasyonları /etc/jitsi/meet/$DOMAIN-config.js
sed -i "s|// anonymousdomain: 'guest.example.com'|anonymousdomain: \'guest.$DOMAIN\'|" $MEET_CONF
sed -i "s|conference.$DOMAIN|internal.auth.$DOMAIN|" $MEET_CONF
sed -i "s|// fileRecordingsEnabled: false,|fileRecordingsEnabled: true,| " $MEET_CONF
sed -i "s|// liveStreamingEnabled: false,|liveStreamingEnabled: true,\\
\\
    hiddenDomain: \'recorder.$DOMAIN\',|" $MEET_CONF

#Dropbox özelliği
if [ $ENABLE_DB = "yes" ]; then
DB_STR=$(grep -n "dropbox:" $MEET_CONF | cut -d ":" -f1)
DB_END=$((DB_STR + 10))
sed -i "$DB_STR,$DB_END{s|// dropbox: {|dropbox: {|}" $MEET_CONF
sed -i "$DB_STR,$DB_END{s|//     appKey: '<APP_KEY>'|appKey: \'$DB_CID\'|}" $MEET_CONF
sed -i "$DB_STR,$DB_END{s|// },|},|}" $MEET_CONF
fi

#Yerel Ses Kaydı
if [ $ENABLE_LAR = "yes" ]; then
echo "# Yerel ses kaydı etkinleştiriliyor..."
LR_STR=$(grep -n "// Local Recording" $MEET_CONF | cut -d ":" -f1)
LR_END=$((LR_STR + 18))
sed -i "$LR_STR,$LR_END{s|// localRecording: {|localRecording: {|}" $MEET_CONF
sed -i "$LR_STR,$LR_END{s|//     enabled: true,|enabled: true,|}" $MEET_CONF
sed -i "$LR_STR,$LR_END{s|//     format: 'flac'|format: 'flac'|}" $MEET_CONF
sed -i "$LR_STR,$LR_END{s|// }|}|}" $MEET_CONF
sed -i "s|'tileview'|'tileview', 'localrecording'|" $INT_CONF
sed -i "s|LOC_REC=.*|LOC_REC=\"on\"|" muhyaljjjguncelleyici.sh
fi

#Ana dil ayarlanıyor
if [ -z $LANG ] || [ "$LANG" = "en" ]; then
	echo "English (en) varsayılan olarak ayarlanıyor..."
	sed -i "s|// defaultLanguage: 'en',|defaultLanguage: 'en',|" $MEET_CONF
else
	echo "Varsayılan dil değiştiriliyor: $LANG"
	sed -i "s|// defaultLanguage: 'en',|defaultLanguage: \'$LANG\',|" $MEET_CONF
fi

#Config dosyası kontrol ediliyor
echo "
# $MEET_CONF dosyası hatalar için kontrol ediliyor...
"
CHECKJS=$(esvalidate $MEET_CONF| cut -d ":" -f2)
if [[ -z "$CHECKJS" ]]; then
echo "
# $MEET_CONF dosyası sorunsuz olarak görünüyor =)
"
else
echo "
Dikkat et! $MEET_CONF satırında bir sorun var gibi görünüyor:
$CHECKJS
Bu hatanın değişikliklerden kaynaklandığını düşünüyorsanız lütfen bildirin.
https://www.muhyal.com/t/45
"
fi

# Kayıt dizini
if [ ! -d $DIR_RECORD ]; then
mkdir $DIR_RECORD
fi
chown -R jibri:jibri $DIR_RECORD
cat << REC_DIR > $REC_DIR
#!/bin/bash
RECORDINGS_DIR=$DIR_RECORD
echo "Kayıt sonlandırılıyor..." > /tmp/finalize.out
echo "Kayıt dosyası kayıtlar dizini /var/jitsikayitlari/ ile çağrıldı $RECORDINGS_DIR." >> /tmp/finalize.out
echo "Buradan herhangi bir sonlandırma fonksiyonu ekleyebilirsiniz (yeniden adlandırma, bir hizmete yükleme gibi.." >> /tmp/finalize.out
echo "Ya da depolama sağlayıcısı vb.)" >> /tmp/finalize.out
chmod -R 770 \$RECORDINGS_DIR
exit 0
REC_DIR
chown jibri:jibri $REC_DIR
chmod +x $REC_DIR

## JSON ayarlanıyor
cp $CONF_JSON ${CONF_JSON}.orijinal
cat << CONF_JSON > $CONF_JSON
{
    "recording_directory":"$DIR_RECORD",
    "finalize_recording_script_path": "$REC_DIR",
    "xmpp_environments": [
        {
            "name": "$JB_NAME",
            "xmpp_server_hosts": [
                "$DOMAIN"
            ],
            "xmpp_domain": "$DOMAIN",
            "control_login": {
                "domain": "auth.$DOMAIN",
                "username": "jibri",
                "password": "$JB_AUTH_PASS"
            },
            "control_muc": {
                "domain": "internal.auth.$DOMAIN",
                "room_name": "$JibriBrewery",
                "nickname": "Live"
            },
            "call_login": {
                "domain": "recorder.$DOMAIN",
                "username": "recorder",
                "password": "$JB_REC_PASS"
            },
            "room_jid_domain_string_to_strip_from_start": "conference.",
            "usage_timeout": "0"
        }
    ]
}
CONF_JSON

#jibri-node-ekle.sh
sed -i "s|MAIN_SRV_DIST=.*|MAIN_SRV_DIST=\"$DIST\"|" jibri-node-ekle.sh
sed -i "s|MAIN_SRV_REPO=.*|MAIN_SRV_REPO=\"$JITSI_REPO\"|" jibri-node-ekle.sh
sed -i "s|MAIN_SRV_DOMAIN=.*|MAIN_SRV_DOMAIN=\"$DOMAIN\"|" jibri-node-ekle.sh
sed -i "s|JB_NAME=.*|JB_NAME=\"$JB_NAME\"|" add-jibri-node.sh
sed -i "s|JibriBrewery=.*|JibriBrewery=\"$JibriBrewery\"|" jibri-node-ekle.sh
sed -i "s|JB_AUTH_PASS=.*|JB_AUTH_PASS=\"$JB_AUTH_PASS\"|" jibri-node-ekle.sh
sed -i "s|JB_REC_PASS=.*|JB_REC_PASS=\"$JB_REC_PASS\"|" jibri-node-ekle.sh
sed -i "$(var_dlim 0_LAST),$(var_dlim 1_LAST){s|LETS: .*|LETS: $(date -R)|}" jibri-node-ekle.sh
echo "Son duzenleme: $(grep "LETS:" jibri-node-ekle.sh|head -n1|awk -F'LETS:' '{print$2}')"

#Jitsi uygulama kontrolü için Tune web sunucusu
if [ -f $WS_CONF ]; then
	sed -i "/Eşleşme bulunamadı/i \\\n" $WS_CONF
	sed -i "/Eşleşme bulunamadı/i \ \ \ \ location = \/external_api.min.js {" $WS_CONF
	sed -i "/Eşleşme bulunamadı/i \ \ \ \ \ \ \ \ alias \/usr\/share\/jitsi-meet\/libs\/external_api.min.js;" $WS_CONF
	sed -i "/Eşleşme bulunamadı/i \ \ \ \ }" $WS_CONF
	sed -i "/Eşleşme bulunamadı/i \\\n" $WS_CONF
	systemctl reload nginx
else
	echo "Uygulama yapılandırma dosyası bulunamadı! Hatayı bildirmek için:
    -> https://www.muhyal.com/t/45"
fi
#Statik avatar ayarlanıyor
if [ "$ENABLE_SA" = "yes" ] && [ -f $WS_CONF ]; then
	#wget https://www.munuya.com/S/Gorseller/Jitsi/avatar.png -O /usr/share/jitsi-meet/images/avatar2.png
	cp avatar2.png /usr/share/jitsi-meet/images/
	sed -i "/location \/external_api.min.js/i \ \ \ \ location \~ \^\/avatar\/\(.\*\)\\\.png {" $WS_CONF
	sed -i "/location \/external_api.min.js/i \ \ \ \ \ \ \ \ alias /usr/share/jitsi-meet/images/avatar2.png;" $WS_CONF
	sed -i "/location \/external_api.min.js/i \ \ \ \ }\\
\ " $WS_CONF
	sed -i "/RANDOM_AVATAR_URL_PREFIX/ s|false|\'https://$DOMAIN/avatar/\'|" $INT_CONF
	sed -i "/RANDOM_AVATAR_URL_SUFFIX/ s|false|\'.png\'|" $INT_CONF
fi
#nginx -tlsv1/1.1
if [ $DROP_TLS1 = "yes" ] && [ $DIST = "bionic" ];then
	echo "TLSv1/1.1 kaldırılıyor - v1.3"
	sed -i "s|TLSv1 TLSv1.1|TLSv1.3|" /etc/nginx/nginx.conf
	#sed -i "s|TLSv1 TLSv1.1|TLSv1.3|" $WS_CONF
elif [ $DROP_TLS1 = "yes" ] && [ ! $DIST = "bionic" ];then
	echo "Sadece TLSv1/1.1 kaldırılıyor"
	sed -i "s|TLSv1 TLSv1.1||" /etc/nginx/nginx.conf
	#sed -i "s|TLSv1 TLSv1.1||" $WS_CONF
else
	echo "TLSv1/1.1 kaldırılamadı! Hatayı bildirmek için:
https://www.muhyal.com/t/45"
fi

#"Blur my background" özelliğini stabil olana kadar pasifleştir
sed -i "s|'videobackgroundblur', ||" $INT_CONF

#Güvenli kanallar etkinleştirilsin mi?
cat << P_SR >> $PROSODY_FILE
VirtualHost "$DOMAIN"
    authentication = "internal_plain"
VirtualHost "guest.$DOMAIN"
    authentication = "anonymous"
    c2s_require_encryption = false
P_SR

#Secure room kullanıcısı
if [ "$ENABLE_SC" = "yes" ]; then
echo "Secure room etkinleştirildi..."
echo "Secure Room kullanıcısı '${SEC_ROOM_USER}' \
ya da '${SEC_ROOM_USER}@${DOMAIN}' ve belirlemiş olduğunuz şifre ile oturum açabilirsiniz."
sed -i "s|#org.jitsi.jicofo.auth.URL=XMPP:|org.jitsi.jicofo.auth.URL=XMPP:|" $JICOFO_SIP
prosodyctl register $SEC_ROOM_USER $DOMAIN $SEC_ROOM_PASS
sed -i "s|SEC_ROOM=.*|SEC_ROOM=\"on\"|" muhyaljao.sh
fi

#Start with video muted ayarı
sed -i "s|// startWithVideoMuted: false,|startWithVideoMuted: true,|" $MEET_CONF

#Start with audio muted ayarını aç ve sadece kanalı açanı istisna ekle
sed -i "s|// startAudioMuted: 10,|startAudioMuted: 1,|" $MEET_CONF

#Hoş geldiniz sayfasını aç/kapat
if [ $ENABLE_WELCP = yes ]; then
	sed -i "s|.*enableWelcomePage:.*|    enableWelcomePage: false,|" $MEET_CONF
elif [ $ENABLE_WELCP = no ]; then
	sed -i "s|.*enableWelcomePage:.*|    enableWelcomePage: true,|" $MEET_CONF
fi
#Jibri ile çakıştığı için görünen adı gerekli değil olarak ayarlaHoş geldiniz sayfası
sed -i "s|// requireDisplayName: true,|requireDisplayName: false,|" $MEET_CONF
#Jibri hizmetlerini başlat
systemctl enable jibri
systemctl enable jibri-xorg
systemctl enable jibri-icewm
restart_services

enable_letsencrypt

#SSL verme işlemi
if [ "$(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "ok installed")" -eq 1 ]; then
	ssl_wa nginx nginx $DOMAIN $WS_CONF $SYSADMIN_EMAIL $DOMAIN
	install_ifnot python3-certbot-nginx
else
	echo "Web sunucusu bulunamadı lütfen bunu bize bildirin."
fi

#Arayüz özelleştirmeleri
if [ $ENABLE_BLESSM = yes ]; then
	echo "Arayüz özelleştirmeleri etkinleştirildi."
	sed -i "s|ENABLE_BLESSM=.*|ENABLE_BLESSM=\"on\"|" muhyaljjjguncelleyici.sh
	bash $PWD/muhyaljao.sh
fi
#JRA - Nextcloud
if [ $ENABLE_NC_ACCESS = yes ]; then
	echo "Jigasi Transcription etkinleştirildi."
	bash $PWD/muhyaljranextcloud.sh
fi
#Jigasi Transcript
if [ $ENABLE_TRANSCRIPT = yes ]; then
	echo "Jigasi Transcription etkinleştirildi."
	bash $PWD/muhyaljigasiyukleyici.sh
fi

#Jibri bağlantı sorunu çözümü
sed -i "/127.0.0.1/a \\
127.0.0.1       $DOMAIN" /etc/hosts

echo "
########################################################################
                    Kurulum tamamlandı!
           Destek almak için: https://www.muhyal.com/t/45
########################################################################
"
apt-get -y autoremove
apt-get autoclean

echo "Sunucunuz yeniden başlatılıyor..."
secs=$((15))
while [ $secs -gt 0 ]; do
   echo -ne "$secs\033[0K\r"
   sleep 1
   : $((secs--))
done
}  > >(tee -a muhyaljjjyukleyici.log) 2> >(tee -a muhyaljjjyukleyici.log >&2)
reboot
