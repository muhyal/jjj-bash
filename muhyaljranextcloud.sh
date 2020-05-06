#!/bin/bash
# JRA (Jibri Recordings Access) Nextcloud Entegrasyonu
# *buntu 16.04+ (LTS) tabanlı sistemler içindir
# © 2020, MUHYAL - https://www.muhyal.com
# GPLv3 ya da sonrası
if ! [ $(id -u) = 0 ]; then
   echo "Root kullanıcısı ya da sudo yetkileriniz olmalı!"
   exit 0
fi

clear
echo '
########################################################################
                 JRA (Jibri Recordings Access) Nextcloud Entegrasyonu
########################################################################
                   © 2020, MUHYAL - https://www.muhyal.com
'
read -p "Nextcloud kurulacak alan adını yazın: " -r NC_DOMAIN
read -p "Nextcloud kullanıcı adını belirleyin " -r NC_USER
read -p "Nextcloud kullanıcısının şifresini belirleyin " -r NC_PASS
#HSTS yapılandırması
while [[ "$ENABLE_HSTS" != "yes" && "$ENABLE_HSTS" != "no" ]]
do
read -p "> Bu alan adı için HSTS etkinleştirmek istiyor musunuz? Ne yaptığınızı bilmiyorsanız Hayır yani no yanıtı önerilir! (yes ya da no)
  HSTS hakkında bilgi edinmek için: https://hstspreload.org/"$'\n' -r ENABLE_HSTS
if [ "$ENABLE_HSTS" = "no" ]; then
	echo "-- HSTS etkinleştirilmedi."
elif [ "$ENABLE_HSTS" = "yes" ]; then
	echo "-- HSTS etkinleştirildi."
fi
done
DISTRO_RELEASE="$(lsb_release -sc)"
DOMAIN=$(ls /etc/prosody/conf.d/ | grep -v localhost | awk -F'.cfg' '{print $1}' | awk '!NF || !seen[$0]++')
PHPVER="7.4"
MDBVER="10.4"
PHP_FPM_DIR="/etc/php/$PHPVER/fpm"
PHP_INI="$PHP_FPM_DIR/php.ini"
PHP_CONF="/etc/php/$PHPVER/fpm/pool.d/www.conf"
NC_NGINX_CONF="/etc/nginx/sites-available/$NC_DOMAIN.conf"
NC_NGINX_SSL_PORT="$(grep "listen 44" /etc/nginx/sites-enabled/$DOMAIN.conf | awk '{print$2}')"
NC_REPO="https://download.nextcloud.com/server/releases"
NCVERSION="$(curl -s -m 900 $NC_REPO/ | sed --silent 's/.*href="nextcloud-\([^"]\+\).zip.asc".*/\1/p' | sort --version-sort | tail -1)"
STABLEVERSION="nextcloud-$NCVERSION"
NC_PATH="/var/www/nextcloud"
NC_CONFIG="$NC_PATH/config/config.php"
NC_DB_USER="nextcloud_user"
NC_DB="nextcloud_db"
NC_DB_PASSWD="$(tr -dc "a-zA-Z0-9#_*=" < /dev/urandom | fold -w 14 | head -n1)"
DIR_RECORD="$(grep -nr RECORDING /home/jibri/finalize_recording.sh|head -n1|cut -d "=" -f2)"
REDIS_CONF="/etc/redis/redis.conf"
JITSI_MEET_PROXY="/etc/nginx/modules-enabled/60-jitsi-meet.conf"
if [ -f $JITSI_MEET_PROXY ];then
PREAD_PROXY=$(grep -nr "preread_server_name" $JITSI_MEET_PROXY | cut -d ":" -f1)
fi
exit_ifinstalled() {
if [ "$(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")" == "1" ]; then
	echo " $1 zaten yüklenmiş çıkış yapılıyor..."
	echo " Bir sorun bildirmek için:
    -> https://www.muhyal.com "
	exit
fi
}
install_ifnot() {
if [ "$(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")" == "1" ]; then
	echo " $1 zaten yüklenmiş atlanıyor..."
    else
    	echo -e "\n---- $1 yükleniyor... ----"
		apt-get -yq2 install $1
fi
}
add_mariadb() {
	if [ "$(dpkg-query -W -f='${Status}' "mariadb-server" 2>/dev/null | grep -c "ok installed")" == "1" ]; then
		echo "MariaDB zaten yüklenmiş"
	else
		echo "# MariaDB $MDBVER deposu ekleniyor... "
		apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C74CD1D8
		echo "deb [arch=amd64] http://ftp.ddg.lth.se/mariadb/repo/$MDBVER/ubuntu $DISTRO_RELEASE main" > /etc/apt/sources.list.d/mariadb.list
		apt-get update -q2
	fi
}
add_php74() {
	if [ "$(dpkg-query -W -f='${Status}' "php$PHPVER-fpm" 2>/dev/null | grep -c "ok installed")" == "1" ]; then
		echo "PHP $PHPVER zaten yüklenmiş."
	else
		echo "# PHP $PHPVER deposu ekleniyor..."
		apt-key adv --recv-keys --keyserver keyserver.ubuntu.com E5267A6C
		echo "deb [arch=amd64] http://ppa.launchpad.net/ondrej/php/ubuntu $DISTRO_RELEASE main" > /etc/apt/sources.list.d/php7x.list
		apt-get update -q2
	fi
}
#Kök klasör izin sorunlarını çöz
cp $PWD/patch_425_3dty.patch /tmp
cp $PWD/jra-nc-app-ef.json /tmp

exit_ifinstalled mariadb-server

## Gereksinimleri yükle
# MariaDB
add_mariadb
install_ifnot mariadb-server-$MDBVER

# PHP 7.4
add_php74
apt-get install -y \
			php$PHPVER-fpm \
			php$PHPVER-bz2 \
			php$PHPVER-curl \
			php$PHPVER-gd \
			php$PHPVER-gmp \
			php$PHPVER-intl \
			php$PHPVER-json \
			php$PHPVER-ldap \
			php$PHPVER-mbstring \
			php$PHPVER-mysql \
			php$PHPVER-soap \
			php$PHPVER-xml \
			php$PHPVER-xmlrpc \
			php$PHPVER-zip \
			php-imagick \
			php-redis \
			redis-server

#Sistem tarafında yapılandırmalar yapılıyor...
install_ifnot smbclient
sed -i "s|.*env\[HOSTNAME\].*|env\[HOSTNAME\] = \$HOSTNAME|" $PHP_CONF
sed -i "s|.*env\[PATH\].*|env\[PATH\] = /usr/local/bin:/usr/bin:/bin|" $PHP_CONF
sed -i "s|.*env\[TMP\].*|env\[TMP\] = /tmp|" $PHP_CONF
sed -i "s|.*env\[TMPDIR\].*|env\[TMPDIR\] = /tmp|" $PHP_CONF
sed -i "s|.*env\[TEMP\].*|env\[TEMP\] = /tmp|" $PHP_CONF
sed -i "s|;clear_env = no|clear_env = no|" $PHP_CONF

echo "
PHP.ini dosyası ayarlanıyor...
"
# php.ini düzenlemeleri yapılıyor...
# max_execution_time
sed -i "s|max_execution_time =.*|max_execution_time = 3500|g" "$PHP_INI"
# max_input_time
sed -i "s|max_input_time =.*|max_input_time = 3600|g" "$PHP_INI"
# memory_limit
sed -i "s|memory_limit =.*|memory_limit = 512M|g" "$PHP_INI"
# post_max
sed -i "s|post_max_size =.*|post_max_size = 1025M|g" "$PHP_INI"
# upload_max
sed -i "s|upload_max_filesize =.*|upload_max_filesize = 1024M|g" "$PHP_INI"

phpenmod opcache
{

echo "# Nextcloud için OPcache yapılandırması yapılıyor... "
echo "opcache.enable=1"
echo "opcache.enable_cli=1"
echo "opcache.interned_strings_buffer=8"
echo "opcache.max_accelerated_files=10000"
echo "opcache.memory_consumption=256"
echo "opcache.save_comments=1"
echo "opcache.revalidate_freq=1"
echo "opcache.validate_timestamps=1"
} >> "$PHP_INI"

systemctl restart php$PHPVER-fpm.service

#--------------------------------------------------
# MySQL kullanıcısı oluşturuluyor...
#--------------------------------------------------

echo -e "\n---- MariaDB kullanıcısı oluşturuluyor...  ----"

mysql -u root <<DB
CREATE DATABASE nextcloud_db;
CREATE USER ${NC_DB_USER}@localhost IDENTIFIED BY '${NC_DB_PASSWD}';
GRANT ALL PRIVILEGES ON ${NC_DB}.* TO '${NC_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
DB
echo "İşlem tamamlandı!
"
#MariaDB optimizasyonları
#mysql_secure_installation

#Nginx yapılandırması
cat << NC_NGINX > $NC_NGINX_CONF
upstream php-handler {
    #server 127.0.0.1:9000;
    server unix:/run/php/php${PHPVER}-fpm.sock;
}
server {
    listen 80;
    listen [::]:80;
    server_name $NC_DOMAIN;
    # enforce https
    return 301 https://\$server_name\$request_uri;
}
server {
    listen $NC_NGINX_SSL_PORT ssl http2;
    listen [::]:$NC_NGINX_SSL_PORT ssl http2;
    server_name $NC_DOMAIN;
    ssl_certificate /etc/letsencrypt/live/$NC_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$NC_DOMAIN/privkey.pem;
    #Strict-Transport-Security "max-age=15552000; includeSubDomains; preload;";
    #Detaylı bilgi için https://hstspreload.org/
    add_header Referrer-Policy "no-referrer" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Download-Options "noopen" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Permitted-Cross-Domain-Policies "none" always;
    add_header X-Robots-Tag "none" always;
    add_header X-XSS-Protection "1; mode=block" always;
    #Kurulum dizini yapılandırması
    root $NC_PATH/;
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    #user_webfinger uygulaması için yapılan iki değişiklik
    #user_webfinger için şu iki satırın hashtaglerini kaldırabilirsiniz
    #rewrite ^/.well-known/host-meta /public.php?service=host-meta last;
    #rewrite ^/.well-known/host-meta.json /public.php?service=host-meta-json
    #last;
    location = /.well-known/carddav {
      return 301 \$scheme://\$host/remote.php/dav;
    }
    location = /.well-known/caldav {
      return 301 \$scheme://\$host/remote.php/dav;
    }
    location ~ /.well-known/acme-challenge {
      allow all;
    }
    #max upload size ayarı
    client_max_body_size 1024M;
    fastcgi_buffers 64 4K;
    #Gzip etkileştir ancak ETag üst bilgilerini kaldırma
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
    #ngx_pagespeed modülü için hashtaglerini kaldırabilirsiniz
    #Bu modül desteklenmiyor bilginize..
    #pagespeed off;
    location / {
        rewrite ^ /index.php\$uri;
    }
    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)/ {
        deny all;
    }
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }
    location ~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+)\.php(?:\$|/) {
        fastcgi_split_path_info ^(.+\.php)(/.*)\$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param HTTPS on;
        #Güvenlik üst bilgilerini iki kez göndermekten kaçın
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass php-handler;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }
    location ~ ^/(?:updater|ocs-provider)(?:\$|/) {
        try_files \$uri/ =404;
        index index.php;
    }
    #js ve css dosyaları için ön bellek üst bilgileri yapılandırması
    location ~ \.(?:css|js|woff|svg|gif)\$ {
        try_files \$uri /index.php\$uri\$is_args\$args;
        add_header Cache-Control "public, max-age=15778463";
        #Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
        #Detaylı bilgi için https://hstspreload.org/
        add_header Referrer-Policy "no-referrer" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Download-Options "noopen" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Permitted-Cross-Domain-Policies "none" always;
        add_header X-Robots-Tag "none" always;
        add_header X-XSS-Protection "1; mode=block" always;
        # Opsiyonel
        access_log off;
    }
    location ~ \.(?:png|html|ttf|ico|jpg|jpeg)\$ {
        try_files \$uri /index.php\$uri\$is_args\$args;
        # Opsiyonel
        access_log off;
    }
}
NC_NGINX
systemctl stop nginx
letsencrypt certonly --standalone --renew-by-default --agree-tos -d $NC_DOMAIN
if [ -f /etc/letsencrypt/live/$NC_DOMAIN/fullchain.pem ];then
	ln -s /etc/nginx/sites-available/$NC_DOMAIN.conf /etc/nginx/sites-enabled/
else
	echo "SSL sertifikalarını almakla ilgili sorunlar var..."
	read -n 1 -s -r -p "Devam etmek için bir tuşa basın..."
fi
nginx -t
systemctl restart nginx

if [ "$ENABLE_HSTS" = "yes" ]; then
sed -i "s|# add_header Strict-Transport-Security|add_header Strict-Transport-Security|g" $NC_NGINX_CONF
fi

if [ "$DISTRO_RELEASE" = "bionic" ] && [ -z $PREAD_PROXY ]; then
echo "
  Nextcloud etki alan adınız Jitsi Meet turn proxy üzerinde yapılandırılıyor
"
	sed -i "/server {/i \ \ map \$ssl_preread_server_name \$upstream {" $JITSI_MEET_PROXY
	sed -i "/server {/i \ \ \ \ \ \ $DOMAIN      web;" $JITSI_MEET_PROXY
	sed -i "/server {/i \ \ \ \ \ \ $NC_DOMAIN web;" $JITSI_MEET_PROXY
	sed -i "/server {/i \ \ }" $JITSI_MEET_PROXY
fi

echo "
Kurulacak olan en güncel sürüm: $STABLEVERSION
"
curl -s $NC_REPO/$STABLEVERSION.zip > /tmp/$STABLEVERSION.zip
unzip -q /tmp/$STABLEVERSION.zip
mv nextcloud $NC_PATH

chown -R www-data:www-data $NC_PATH
chmod -R 755 $NC_PATH

if $(dpkg --compare-versions "$NCVERSION" "le" "18.0.3"); then
echo "
-> Yama uygulanıyor... (scssphp/src/Compiler.php)..."
sudo -u www-data patch -d "$NC_PATH/3rdparty/leafo/scssphp/src/" -p0  < /tmp/patch_425_3dty.patch
fi

echo "
Veritabanı yapılandırılıyor...
"
sudo -u www-data php $NC_PATH/occ maintenance:install \
--database=mysql \
--database-name="$NC_DB" \
--database-user="$NC_DB_USER" \
--database-pass="$NC_DB_PASSWD" \
--admin-user="$NC_USER" \
--admin-pass="$NC_PASS"

echo "
Özel düzenlemeler uygulanıyor...
"
sed -i "/datadirectory/a \ \ \'skeletondirectory\' => \'\'," $NC_CONFIG
sed -i "/skeletondirectory/a \ \ \'simpleSignUpLink.shown\' => false," $NC_CONFIG
sed -i "/simpleSignUpLink.shown/a \ \ \'knowledgebaseenabled\' => false," $NC_CONFIG
sed -i "s|http://localhost|http://$NC_DOMAIN|" $NC_CONFIG

echo "Crontab yapılandırılıyor..."
crontab -u www-data -l | { cat; echo "*/5  *  *  *  * php -f $NC_PATH/cron.php"; } | crontab -u www-data -

echo "
memcache desteği ekleniyor...
"
sed -i "s|# unixsocket .*|unixsocket /var/run/redis/redis.sock|g" $REDIS_CONF
sed -i "s|# unixsocketperm .*|unixsocketperm 777|g" $REDIS_CONF
sed -i "s|port 6379|port 0|" $REDIS_CONF
systemctl restart redis-server

echo "--> config.php yapılandırılıyor..."
sed -i "/);/i \ \ 'filelocking.enabled' => 'true'," $NC_CONFIG
sed -i "/);/i \ \ 'memcache.locking' => '\\\OC\\\Memcache\\\Redis'," $NC_CONFIG
sed -i "/);/i \ \ 'memcache.local' => '\\\OC\\\Memcache\\\Redis'," $NC_CONFIG
sed -i "/);/i \ \ 'memcache.local' => '\\\OC\\\Memcache\\\Redis'," $NC_CONFIG
sed -i "/);/i \ \ 'memcache.distributed' => '\\\OC\\\Memcache\\\Redis'," $NC_CONFIG
sed -i "/);/i \ \ 'redis' =>" $NC_CONFIG
sed -i "/);/i \ \ \ \ array (" $NC_CONFIG
sed -i "/);/i \ \ \ \ \ 'host' => '/var/run/redis/redis.sock'," $NC_CONFIG
sed -i "/);/i \ \ \ \ \ 'port' => 0," $NC_CONFIG
sed -i "/);/i \ \ \ \ \ 'timeout' => 0," $NC_CONFIG
sed -i "/);/i \ \ )," $NC_CONFIG
echo "Done
"
echo "
Yerel depolama için dosya ekleme ayarları ve harici uygulama yapılandırılıyor...
"
sudo -u www-data php $NC_PATH/occ app:install files_external
sudo -u www-data php $NC_PATH/occ app:enable files_external
sudo -u www-data php $NC_PATH/occ files_external:import /tmp/jra-nc-app-ef.json

usermod -a -G jibri www-data
chown -R jibri:www-data $DIR_RECORD
chmod -R 770 $DIR_RECORD
chmod -R g+s $DIR_RECORD

echo "
Olası tablo sorunları gideriliyor...
"
echo "y"|sudo -u www-data php $NC_PATH/occ db:convert-filecache-bigint
sudo -u www-data php $NC_PATH/occ db:add-missing-indices

echo "
Güvenilen alan adı ekleniyor...
"
sudo -u www-data php $NC_PATH/occ config:system:set trusted_domains 0 --value=$NC_DOMAIN

echo "Nextcloud kurulumu tamamlandı!"
