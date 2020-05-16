#!/bin/bash
# Jigasi Yükleyici
# *buntu 16.04+ (LTS) tabanlı sistemler içindir
# © 2020, MUHYAL - https://www.muhyal.com
# GPLv3 ya da sonrası

#Kullanıcının root olup olmadığını kontrol et
if ! [ $(id -u) = 0 ]; then
   echo "Kök veya sudo ayrıcalıklarına sahip kullanıcı olmanız gerekir!"
   exit 0
fi

clear
echo '
########################################################################
                       Jigasi Transcript (Konuşmadan metne çeviri) eklentisi
########################################################################
                         © 2020, MUHYAL - https://www.muhyal.com
'

JIGASI_CONFIG=/etc/jitsi/jigasi/config
GC_API_JSON=/opt/gc-sdk/GCTranscriptAPI.json
DOMAIN=$(ls /etc/prosody/conf.d/ | grep -v localhost | awk -F'.cfg' '{print $1}' | awk '!NF || !seen[$0]++')
MEET_CONF=/etc/jitsi/meet/${DOMAIN}-config.js
JIG_SIP_PROP=/etc/jitsi/jigasi/sip-communicator.properties
DIST=$(lsb_release -sc)
CHECK_GC_REPO=$(apt-cache policy | grep http | grep cloud-sdk | head -n1 | awk '{print $3}' | awk -F '/' '{print $1}')

install_gc_repo() {
	if [ "$CHECK_GC_REPO" = "cloud-sdk-$DIST" ]; then
	echo "
Google Cloud SDK deposu zaten sisteminizde bulunuyor!
"
else
	echo "
Google Cloud SDK deposu son güncellemeleri alabilmek için ekleniyor!
"
	export CLOUD_SDK_REPO="cloud-sdk-$DIST"
	echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

fi
}
install_gc_repo
apt-get -q2 update
apt-get -y install google-cloud-sdk google-cloud-sdk-app-engine-java

echo "Lütfen mevcut seçeneklerden birini seçin:
[1] Yeni bir proje, hizmet hesabı, faturalandırma ve JSON kimlik bilgilerini yapılandırmak istiyorum.
[2] Zaten bir projem var ve zaten Google'dan bir JSON anahtar dosyam var."
while [[ $SETUP_TYPE != 1 && $SETUP_TYPE != 2 ]]
do
read -p "Nasıl kurulum yapılsın?: (1 ya da 2)"$'\n' -r SETUP_TYPE
if [ $SETUP_TYPE = 1 ]; then
	echo "Sıfırdan bir Google Cloud Projesi kuracağım."
elif [ $SETUP_TYPE = 2 ]; then
	echo "Yalnızca proje ve JSON anahtarını kuracağım."
fi
done

if [ $SETUP_TYPE = 1 ]; then
### Yeni proje yapılandırmasının başlangıcı - Google SDK
#Kurulum seçeneği 1 - Google Cloud SDK
echo "Google Cloud SDK'ya giriş yaptıktan sonra, lütfen yeni bir proje oluşturun (son seçenek)."
gcloud init
read -p "Jigasi Konuşmadan Metne çeviri özelliği için yeni oluşturduğunuz proje adını girin"$'\n' -r GC_PROJECT_NAME
#İkinci giriş - Google Kimlik Doğrulama Kütüphanesi
echo "Google Kimlik Doğrulama Kütüphanesi'ne giriş yapın"
gcloud auth application-default login

# Google Cloud Configuration'ı başlatın - Uygulama Hizmeti
GC_MEMBER=transcript
echo "Projenin var olup olmadığını kontrol ediliyor..."
PROJECT_GC_ID=$(gcloud projects list | grep $GC_PROJECT_NAME | awk '{print$3}')
while [ -z $PROJECT_GC_ID ]
do
read -p "Jigasi Konuşmadan Metne çeviri özelliği için yeni oluşturduğunuz proje adını girin"$'\n' -r GC_PROJECT_NAME
if [ -z PROJECT_GC_ID ]; then
	echo "Lütfen proje adınızı kontrol edin,
	Belirtilen adla listelenmiş proje yok: $GC_PROJECT_NAME"
	PROJECT_GC_ID=$(gcloud projects list | grep $GC_PROJECT_NAME | awk '{print$3}')
fi
done
echo "Proje: $GC_PROJECT_NAME ID: $PROJECT_GC_ID"

# Speech2Text etkinleştir
echo "Önemli: Lütfen aşağıdaki URL'yi kullanarak projenizde faturalandırmayı etkinleştirin:
https://console.developers.google.com/project/$PROJECT_GC_ID/settings"

echo "Faturalandırma kontrol ediliyor..."
CHECK_BILLING="$(gcloud services enable speech.googleapis.com 2>/dev/null)"
while [[ $? -eq 1 ]]
do
CHECK_BILLING="$(gcloud services enable speech.googleapis.com 2>/dev/null)"
if [[ $? -eq 1 ]]; then
        echo "Bu proje için faturalandırmayı etkinleştirmediğiniz belirlendi: $GC_PROJECT_NAME
    Bunun için şu adresi ziyaret etmelisiniz: https://console.developers.google.com/project/$PROJECT_GC_ID/settings
    "
        read -p "Devam etmek için Enter tuşuna basın"
        CHECK_BILLING="$(gcloud services enable speech.googleapis.com 2>/dev/null)"
fi
done
echo "Faturalandırma hesabı hazır görünüyor, devam ediyoruz..."

gcloud iam service-accounts create $GC_MEMBER

gcloud projects add-iam-policy-binding  $GC_PROJECT_NAME \
    --member serviceAccount:$GC_MEMBER@$GC_PROJECT_NAME.iam.gserviceaccount.com \
    --role  roles/editor

echo "Kurulum kimlik bilgileri:"
echo "Lütfen şu adresten geçerli json anahtarınızı indirin:
https://console.developers.google.com/apis/credentials?folder=&organizationId=&project=$GC_PROJECT_NAME"
### Yeni proje yapılandırmasının sonu - Google SDK
fi

if [ $SETUP_TYPE = 2 ]; then
#Kurulum seçeneği 1 - Google Cloud SDK
echo "Google Cloud SDK'ya giriş yaptıktan sonra, lütfen JSON anahtarının sahibi olan projeyi seçin."
gcloud init
echo "Google Kimlik Doğrulama Kütüphanesi'ne giriş yapın"
gcloud auth application-default login
fi

echo "JSON anahtar dosyasını ayarlanıyor..."
sleep 2
mkdir /opt/gc-sdk/
cat << KEY_JSON > $GC_API_JSON
#
# Bu kısmın altına hizmet hesabı için GC JSON anahtarınızı yapıştırın:
# $GC_MEMBER@$GC_PROJECT_NAME.iam.gserviceaccount.com
#
# Aşağıdaki bağlantıyı ziyaret edin ve bir *Hizmet Hesabı Anahtarı* oluşturun:
# https://console.developers.google.com/apis/credentials?folder=&organizationId=&project=$GC_PROJECT_NAME
# Bu satırlar daha sonra silinecektir.
#
KEY_JSON
chmod 644 $GC_API_JSON
nano $GC_API_JSON
sed -i '/^#/d' $GC_API_JSON

CHECK_JSON_KEY="$(cat $GC_API_JSON | python -m json.tool 2>/dev/null)"
while [[ $? -eq 1 ]]
do
CHECK_JSON_KEY="$(cat $GC_API_JSON | python -m json.tool 2>/dev/null)"
if [[ $? -eq 1 ]]; then
        echo "Check again your JSON file, syntax doesn't seem right"
        sleep 2
        nano $GC_API_JSON
        CHECK_JSON_KEY="$(cat $GC_API_JSON | python -m json.tool 2>/dev/null)"
fi
done
echo "
Harika, JSON anahtar sözdiziminiz hatası görünüyor...
"
sleep 2

export GOOGLE_APPLICATION_CREDENTIALS=$GC_API_JSON

echo "Jigasi'yi yüklediğinizde, SIP kimlik bilgileriniz sorulacak (mandatory)"
apt-get -y install jigasi=1.0-235

apt-mark hold jigasi

cat  << JIGASI_CONF >> $JIGASI_CONFIG
GOOGLE_APPLICATION_CREDENTIALS=$GC_API_JSON
JIGASI_CONF

echo "Google Cloud kimlik bilgileriniz şurada: $GC_API_JSON"

echo "Jigasi konuşmadan metne çeviri geçerli platforma kuruluyor..."
#callcontrol Bağlantısı
sed -i "s|// call_control:|call_control:|" $MEET_CONF
sed -i "s|// transcribingEnabled|transcribingEnabled|" $MEET_CONF
sed -i "/transcribingEnabled/ s|false|true|" $MEET_CONF

#siptest2siptest@sizinalanadiniz.com
#Jibri konferans - internal.auth değişiklikleri
sed -i "s|siptest|siptest@internal.auth.$DOMAIN|" $JIG_SIP_PROP

#Konuşmadan metneyi etkinleştir / SIP devre dışı bırak
sed -i "/ENABLE_TRANSCRIPTION/ s|#||" $JIG_SIP_PROP
sed -i "/ENABLE_TRANSCRIPTION/ s|false|true|" $JIG_SIP_PROP
sed -i "/ENABLE_SIP/ s|#||" $JIG_SIP_PROP
sed -i "/ENABLE_SIP/ s|true|false|" $JIG_SIP_PROP

#Konuşmadan metne formatı
sed -i "/SAVE_JSON/ s|# ||" $JIG_SIP_PROP
sed -i "/SEND_JSON/ s|# ||" $JIG_SIP_PROP
sed -i "/SAVE_TXT/ s|# ||" $JIG_SIP_PROP
sed -i "/SEND_TXT/ s|# ||" $JIG_SIP_PROP
#sed -i "/SEND_TXT/ s|false|true|" $JIG_SIP_PROP

#LE'nin nasıl kullanılacağını veya neyin gerekli olduğunu öğrenmeyi unutmayın
sed -i "/ALWAYS_TRUST_MODE_ENABLED/ s|# ||" $JIG_SIP_PROP

#Jigasi bilgileri
sed -i "/xmpp.acc.USER_ID/ s|# ||" $JIG_SIP_PROP
sed -i "/xmpp.acc.USER_ID/ s|SOME_USER\@SOME_DOMAIN|transcript\@auth.$DOMAIN|" $JIG_SIP_PROP
sed -i "/xmpp.acc.PASS/ s|# ||" $JIG_SIP_PROP
sed -i "/xmpp.acc.PASS/ s|SOME_PASS|jigasi|" $JIG_SIP_PROP
sed -i "/xmpp.acc.ANONYMOUS_AUTH/ s|# ||" $JIG_SIP_PROP

prosodyctl register transcript auth.$DOMAIN jigasi

systemctl restart 	prosody \
					jicofo \
					jibri* \
					jitsi-videobridge*
echo "
Test etmek için önce toplantıda altyazıları etkinleştirmeniz ve ardından katılımcı davet etmeniz gerekir \
\"jitsi_meet_transcribe\" (Tırnaklar olmadan).
"

echo "
Tam konuşma metni dosyaları şu adreste bulunur:
--> /var/lib/jigasi/transcripts/
"

echo "
Mutlu konuşmadan metne çeviriler!
"

#APP.conference._room.dial("jitsi_meet_transcribe");
