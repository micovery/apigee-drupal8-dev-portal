# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM debian:stretch-slim

ARG KICKSTART_VERSION
ENV DEBIAN_FRONTEND noninteractive
ENV KICKSTART_VERSION ${KICKSTART_VERSION}

# Check for required arguments
RUN \
if [ -z "${KICKSTART_VERSION}" ] ; then \
     echo "ERROR: Build argument for KICKSTART_VERSION is required" 1>&2 ; \
    exit 1; \
fi

ENV DRUPAL_PROJECT_DIR=/drupal/project
ENV DRUPAL_WEB_DIR=${DRUPAL_PROJECT_DIR}/web
ENV PATH="${DRUPAL_PROJECT_DIR}/vendor/bin:${PATH}"

# Base
RUN apt-get update && \
    apt-get -y --no-install-recommends \
             install software-properties-common wget apt-transport-https \
             gnupg2 lsb-release sudo && \
    \
    wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add - && \
    echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list && \
    apt-get update && \
    apt-get -y install -y --no-install-recommends \
              php php-cli php-bcmath php-bz2 php-intl php-gd \
              php-mbstring php-mysql php-zip php-sqlite3 \
              php-curl php-xml php-intl \
              apache2 libapache2-mod-php \
              git unzip cron gnupg supervisor \
              mysql-server mysql-client && \
    apt-get -y clean && \
    apt-get -y autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    \
    useradd -p "$(openssl passwd -1 drupal)" -d /drupal -ms /bin/bash drupal && \
    usermod -aG sudo drupal && \
    echo "drupal ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    \
    sudo -u drupal composer -V && \
    \
    mkdir -p ${DRUPAL_PROJECT_DIR} && \
    chmod -R a+rw ${DRUPAL_PROJECT_DIR}  && \
    \
    sudo -u drupal composer create-project apigee/devportal-kickstart-project:${KICKSTART_VERSION} ${DRUPAL_PROJECT_DIR} --no-interaction && \
    \
    cd ${DRUPAL_PROJECT_DIR} && \
    sudo -u drupal composer require drupal/devel && \
    \
    sudo -u drupal composer clear-cache && \
    \
    echo 'LoadModule rewrite_module /usr/lib/apache2/modules/mod_rewrite.so' \
       >> /etc/apache2/mods-available/rewrite.load && \
    cd /etc/apache2/mods-enabled && \
    ln -s ../mods-available/rewrite.load && \
    \
    echo '\
  ServerName localhost \n\
  <VirtualHost *:80> \n\
      ServerAdmin webmaster@localhost \n\
      DocumentRoot ' ${DRUPAL_WEB_DIR} ' \n\
      <Directory ' ${DRUPAL_WEB_DIR} ' > \n\
          Options Indexes FollowSymLinks \n\
          AllowOverride All \n\
          Require all granted \n\
      </Directory> \n\
      ErrorLog ${APACHE_LOG_DIR}/error.log \n\
      CustomLog ${APACHE_LOG_DIR}/access.log combined \n\
  </VirtualHost>' > /etc/apache2/sites-available/000-default.conf && \
    \
    sudo -u drupal mkdir -p ${DRUPAL_WEB_DIR}/sites/default/files && \
	sudo -u drupal chmod a+w ${DRUPAL_WEB_DIR}/sites/default -R && \
	sudo -u drupal mkdir -p ${DRUPAL_WEB_DIR}/sites/all/modules/contrib && \
	sudo -u drupal mkdir -p ${DRUPAL_WEB_DIR}/sites/all/modules/custom && \
	sudo -u drupal mkdir -p ${DRUPAL_WEB_DIR}/sites/all/themes/contrib && \
	sudo -u drupal mkdir -p ${DRUPAL_WEB_DIR}/sites/all/themes/custom && \
	sudo -u drupal cp ${DRUPAL_WEB_DIR}/sites/default/default.settings.php ${DRUPAL_WEB_DIR}/sites/default/settings.php && \
	sudo -u drupal cp ${DRUPAL_WEB_DIR}/sites/default/default.services.yml ${DRUPAL_WEB_DIR}/sites/default/services.yml && \
	sudo -u drupal chmod a+w ${DRUPAL_WEB_DIR}/sites/default/settings.php && \
	sudo -u drupal chmod 0664 ${DRUPAL_WEB_DIR}/sites/default/services.yml && \
	sudo -u drupal echo '$settings["trusted_host_patterns"] = array("^.*$");' >> ${DRUPAL_WEB_DIR}/sites/default/settings.php && \
    \
    service mysql start && \
    mysql -u root -e "\
       GRANT ALL PRIVILEGES ON *.* TO drupal@localhost IDENTIFIED BY 'drupal'; \
       CREATE DATABASE drupal;" && \
    \
    cd ${DRUPAL_WEB_DIR} && \
    sudo -u www-data ${DRUPAL_PROJECT_DIR}/vendor/bin/drush site:install -y apigee_devportal_kickstart \
          --db-url=mysql://drupal:drupal@localhost/drupal \
          --account-mail admin@localhost --account-name=admin \
          --account-pass=admin && \
    \
    sudo -u www-data ${DRUPAL_PROJECT_DIR}/vendor/bin/drush en devel && \
    sudo -u drupal chmod o-w ${DRUPAL_WEB_DIR}/sites/default/settings.php && \
    sudo -u drupal chmod o-w ${DRUPAL_WEB_DIR}/sites/default && \
    \
    echo '\
[program:apache2]  \n\
command=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND" \n\
autorestart=true   \n\
                   \n\
[program:mysql]    \n\
command=/usr/bin/pidproxy /var/run/mysqld/mysqld.pid /usr/sbin/mysqld \n\
autorestart=true   \n\
                   \n\
[program:cron]     \n\
command=cron -f    \n\
autorestart=false  \n\
' >> /etc/supervisor/supervisord.conf

# Make drupal active user
USER drupal
ENV PATH="${DRUPAL_PROJECT_DIR}/vendor/bin:${PATH}"
WORKDIR /drupal

EXPOSE 80
CMD exec sudo -u root supervisord -n -c /etc/supervisor/supervisord.conf
