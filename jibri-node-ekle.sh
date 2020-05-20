#!/bin/bash
# Jibri Node Ekleyici
# *buntu 16.04+ (LTS) tabanlı sistemler içindir
# © 2020, MUHYAL - https://www.muhyal.com
# GPLv3 ya da sonrası

#Dosya adının gerekli olduğundan emin ol
if [ ! "$(basename $0)" = "jibri-node-ekle.sh" ]; then
	echo "Çoğu durumda adlandırma önemli değildir ama bu adımda önemlidir."
	echo "Lütfen bu komut dosyası için orijinal adı kullanın: \`jibri-node-ekle.sh', daha sonra tekrar çalıştırın."
	exit
fi

while getopts m: option
do
	case "${option}"
	in
		m) MODE=${OPTARG};;
		\?) echo "Kullanım şekli: sudo ./jibri-node-ekle.sh [-m debug]" && exit;;
	esac
done

#Hata ayıkla
if [ "$MODE" = "debug" ]; then
set -x
fi

#Yetkileri kontrol et
if ! [ "$(id -u)" = 0 ]; then
   echo "Root ya da sudo yetkilerine sahip olmalısınız!"
   exit 0
fi

### 0_VAR_DEF
MAIN_SRV_DIST=TBD
MAIN_SRV_REPO=TBD
MAIN_SRV_DOMAIN=TBD
JibriBrewery=TBD
JB_NAME=TBD
JB_AUTH_PASS=TBD
JB_REC_PASS=TBD
THIS_SRV_DIST=$(lsb_release -sc)
JITSI_REPO=$(apt-cache policy | grep http | grep jitsi | grep stable | awk '{print $3}' | head -n 1 | cut -d "/" -f1)
START=0
LAST=TBD
CONF_JSON="/etc/jitsi/jibri/config.json"
DIR_RECORD="/var/jbrecord"
REC_DIR="/home/jibri/finalize_recording.sh"
CHD_VER="$(curl -sL https://chromedriver.storage.googleapis.com/LATEST_RELEASE)"
GOOGL_REPO="/etc/apt/sources.list.d/dl_google_com_linux_chrome_deb.list"
GCMP_JSON="/etc/opt/chrome/policies/managed/managed_policies.json"
### 1_VAR_DEF

# jibri-node-ekle.sh
var_dlim() {
	grep -n $1 jibri-node-ekle.sh|head -n1|cut -d ":" -f1
}

check_var() {
	if [ -z "$2" ]; then
		echo "$1 tanımlı değil, lütfen kontrol edin. Çıkış yapılıyor..."
		exit
	else
		echo "$1 şuna ayarlandı: $2"
	fi
	}

if [ -z "$LAST" ]; then
	echo "LAST tanımında bir hata var, lütfen bize bildirin: http://muhyal.com/t/45"
	exit
elif [ "$LAST" = "TBD" ]; then
	ADDUP=$((START + 1))
else
	ADDUP=$((LAST + 1))
fi

#Sunucu ve Node işletim sistemini kontrol et
if [ ! "$THIS_SRV_DIST" = "$MAIN_SRV_DIST" ]; then
	echo "Her iki sunucuda jibri kurulumu için lütfen aynı işletim sistemini kullanın."
	echo "Bu sunucunun sistemi: $THIS_SRV_DIST"
	echo "Ana sunucunun sistemi: $MAIN_SRV_DIST"
	exit
fi

echo "
#-----------------------------------------------------------------------
# İlk gerekli değişkenler kontrol ediliyor ...
#-----------------------------------------------------------------------"

check_var MAIN_SRV_DIST "$MAIN_SRV_DIST"
check_var MAIN_SRV_REPO "$MAIN_SRV_REPO"
check_var MAIN_SRV_DOMAIN "$MAIN_SRV_DOMAIN"
check_var JibriBrewery "$JibriBrewery"
check_var JB_NAME "$JB_NAME"
check_var JB_AUTH_PASS "$JB_AUTH_PASS"
check_var JB_REC_PASS "$JB_REC_PASS"

# Jitsi-Meet Repo
echo "Jitsi repo ekleniyor..."
if [ -z "$JITSI_REPO" ]; then
	echo "deb http://download.jitsi.org $MAIN_SRV_REPO/" > /etc/apt/sources.list.d/jitsi-$MAIN_SRV_REPO.list
	wget -qO -  https://download.jitsi.org/jitsi-key.gpg.key | apt-key add -
elif [ ! "$JITSI_REPO" = "$MAIN_SRV_REPO" ]; then
	echo "Ana sunucu ve node versiyonları eşleşmiyor, çıkış yapılıyor..."
	exit
elif [ "$JITSI_REPO" = "$MAIN_SRV_REPO" ]; then
	echo "Ana sunucu ve node versiyonları eşleşiyor, devam ediliyor..."
else
	echo "Jitsi $JITSI_REPO deposu zaten kurulu."
fi

check_snd_driver() {
modprobe snd-aloop
echo "snd-aloop" >> /etc/modules
if [ "$(lsmod | grep snd_aloop | head -n 1 | cut -d " " -f1)" = "snd_aloop" ]; then
	echo "
#-----------------------------------------------------------------------
# Ses sürücüleri gayet iyi görünüyor
#-----------------------------------------------------------------------"
else
	echo "
#-----------------------------------------------------------------------
# Kurulumdan sonra ses sürücünüz yüklenemeyebilir
# tamamlandıktan ve sunucu yeniden başlatıldıktan sonra, lütfen çalıştırın: \`lsmod | grep snd_aloop'
#-----------------------------------------------------------------------"
read -n 1 -s -r -p "Devam etmek için bir tuşa basın..."$'\n'
fi
}

# Gereksinimler
echo "Bu biraz zaman alabilir sistem gereksinimleri yükleyerek başlayacağız lütfen sabırlı olun..."
apt-get update -q2
apt-get dist-upgrade -yq2

apt-get -y install \
				bmon \
				curl \
				ffmpeg \
				git \
				htop \
				linux-image-generic-hwe-"$(lsb_release -r|awk '{print$2}')" \
				unzip \
				wget

check_snd_driver

echo "
#--------------------------------------------------
# Jibri yükle
#--------------------------------------------------
"
apt-get -y install \
                jibri \
                openjdk-8-jre-headless

echo "# Google Chrome / ChromeDriver yükleniyor"
if [ -f $GOOGL_REPO ]; then
	echo "Google deposu zaten ekli."
else
	echo "Google Chrome Stable yükleniyor"
	wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
	echo "deb http://dl.google.com/linux/chrome/deb/ stable main" | tee $GOOGL_REPO
fi
apt-get -q2 update
apt-get install -y google-chrome-stable
rm -rf /etc/apt/sources.list.d/dl_google_com_linux_chrome_deb.list

if [ -f /usr/local/bin/chromedriver ]; then
	echo "Chromedriver zaten yüklü."
else
	echo "Chromedriver yükleniyor"
	wget -q https://chromedriver.storage.googleapis.com/$CHD_VER/chromedriver_linux64.zip -O /tmp/chromedriver_linux64.zip
	unzip /tmp/chromedriver_linux64.zip -d /usr/local/bin/
	chown root:root /usr/local/bin/chromedriver
	chmod 0755 /usr/local/bin/chromedriver
	rm -rf /tpm/chromedriver_linux64.zip
fi

echo "
Google yazılımlarının çalışabilirliği kontrol ediliyor...
"
/usr/bin/google-chrome --version
/usr/local/bin/chromedriver --version | awk '{print$1,$2}'

echo '
########################################################################
                        Jibri yapılandırması başlatılıyor
########################################################################
'
echo "
Chrome uyarısı kaldırılıyor...
"
mkdir -p /etc/opt/chrome/policies/managed
echo '{ "CommandLineFlagSecurityWarningsEnabled": false }' > $GCMP_JSON

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

## JSON yapılandırması
cp $CONF_JSON ${CONF_JSON}.orijinal

cat << CONF_JSON > $CONF_JSON
{
    "recording_directory":"$DIR_RECORD",
    "finalize_recording_script_path": "$REC_DIR",
    "xmpp_environments": [
        {
            "name": "$JB_NAME",
            "xmpp_server_hosts": [
                "$MAIN_SRV_DOMAIN"
            ],
            "xmpp_domain": "$MAIN_SRV_DOMAIN",
            "control_login": {
                "domain": "auth.$MAIN_SRV_DOMAIN",
                "username": "jibri",
                "password": "$JB_AUTH_PASS"
            },
            "control_muc": {
                "domain": "internal.auth.$MAIN_SRV_DOMAIN",
                "room_name": "$JibriBrewery",
                "nickname": "Live-$ADDUP"
            },
            "call_login": {
                "domain": "recorder.$MAIN_SRV_DOMAIN",
                "username": "recorder",
                "password": "$JB_REC_PASS"
            },
            "room_jid_domain_string_to_strip_from_start": "conference.",
            "usage_timeout": "0"
        }
    ]
}
CONF_JSON

echo "Node numarası yazılıyor..."
sed -i "$(var_dlim 0_VAR),$(var_dlim 1_VAR){s|LAST=.*|LAST=$ADDUP|}" jibri-node-ekle.sh
sed -i "$(var_dlim 0_LAST),$(var_dlim 1_LAST){s|LETS: .*|LETS: $(date -R)|}" jibri-node-ekle.sh
echo "Son dosya versiyonu: $(grep "LETS:" jibri-node-ekle.sh|head -n1|awk -F'LETS:' '{print$2}')"

#Jibri hizmetlerini başlat
systemctl enable jibri
systemctl enable jibri-xorg
systemctl enable jibri-icewm

echo "
########################################################################
                        Node ekleme işlemi tamamlandı!
               Destek ve detaylı bilgi için: http://muhyal.com/t/45
########################################################################
"

echo "Yeniden başlatılıyor..."
secs=$((15))
while [ $secs -gt 0 ]; do
   echo -ne "$secs\033[0K\r"
   sleep 1
   : $((secs--))
done
reboot
