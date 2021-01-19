FROM centos:7.9.2009

MAINTAINER pastakhov@yandex.ru

# Install requered packages
RUN set -x; \
	yum -y install httpd \
		https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
		https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
		yum-utils
RUN yum-config-manager --enable remi-php74
RUN yum -y update
RUN yum -y install php php-cli php-mysqlnd php-gd php-mbstring php-xml php-intl php-opcache php-pecl-apcu php-redis php-pecl-xdebug \
		git composer mysql wget unzip imagemagick python-pygments ssmtp

RUN sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

ENV MW_VERSION=REL1_35 \
	MW_CORE_VERSION=1.35.1 \
	MW_HOME=/var/www/html/w \
	MW_VOLUME=/mediawiki \
	MW_ORIGIN_FILES=/mw_origin_files \
	WWW_USER=apache \
	WWW_GROUP=apache \
	APACHE_LOG_DIR=/var/log/apache2

##### MediaWiki Core setup
RUN set -x; \
	# Core
	mkdir -p $MW_ORIGIN_FILES \
	mkdir -p $MW_HOME \
	&& git clone --depth 1 -b $MW_CORE_VERSION https://gerrit.wikimedia.org/r/mediawiki/core.git $MW_HOME \
	&& cd $MW_HOME \
	&& git submodule update --init

# VisualEditor
RUN set -x; \
	cd $MW_HOME/extensions/VisualEditor \
	&& git submodule update --init

RUN set -x; \
	mv $MW_HOME/images $MW_ORIGIN_FILES/ \
	&& mv $MW_HOME/cache $MW_ORIGIN_FILES/ \
	&& ln -s $MW_VOLUME/images $MW_HOME/images \
	&& ln -s $MW_VOLUME/cache $MW_HOME/cache

COPY composer.local.json $MW_HOME/composer.local.json
RUN set -x; cd $MW_HOME && composer update --no-dev

# Chamelion Skin
RUN set -x; \
	cd $MW_HOME/skins \
	&& git clone https://github.com/ProfessionalWiki/chameleon.git \
	&& cd chameleon \
	&& git checkout -b $MW_VERSION c4cd43625c20e8979f2d274b4dd514388f3d47cc

### Extensions

RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DataTransfer \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Variables \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Loops \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MyVariables \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Arrays \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/DisplayTitle \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ConfirmAccount \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Lockdown \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Math

RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/LinkTarget \
	&& cd LinkTarget \
	&& git checkout -b $MW_VERSION ab1aba0a4a138f80c4cd9c86cc53259ca0fe4545

RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Widgets \
	&& cd Widgets \
	&& composer update --no-dev \
	&& mkdir -p $MW_ORIGIN_FILES/extensions/Widgets \
	&& mv compiled_templates $MW_ORIGIN_FILES/extensions/Widgets/ \
	&& ln -s $MW_VOLUME/extensions/Widgets/compiled_templates compiled_templates

RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CodeMirror \
	&& cd CodeMirror \
	&& composer update --no-dev

RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/Fannon/SimpleTooltip.git \
	&& cd SimpleTooltip \
	&& git checkout -b $MW_VERSION 2476bff8f4555f86795c26ca5fdb7db99bfe58d1

RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/bovender/PubmedParser.git \
	&& cd PubmedParser \
	&& git checkout -b $MW_VERSION 9cd01d828b23853e3e790dc7bf49cdd230847272

# PageForm
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/PageForms \
	&& cd PageForms \
	&& git checkout -b $MW_VERSION d2e48e51eef1

# NCBITaxonomyLookup
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/WikiTeq/NCBITaxonomyLookup.git \
	&& cd NCBITaxonomyLookup \
	&& git checkout -b $MW_VERSION f23565dfe2fdbcaa5b265545058ddc6959c96f40

# MathJax
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/xeyownt/mediawiki-mathjax.git MathJax \
	&& cd MathJax \
	&& git checkout -b $MW_VERSION 4afdc226f08f9c2b1471a523d3c64df716b25c6c

# BreadCrumbs2
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/BreadCrumbs2.git \
	&& cd BreadCrumbs2 \
	&& git checkout -b $MW_VERSION d95826a74eef014be0d9685bdf66d07af0b37777

# GTag1
COPY sources/GTag1.2.0.tar.gz /tmp/
RUN set -x; \
	tar -xvf /tmp/GTag*.tar.gz -C $MW_HOME/extensions \
	&& rm /tmp/GTag*.tar.gz

ENV MW_MAINTENANCE_UPDATE=0 \
	MW_ENABLE_UPLOADS=0 \
	MW_MAIN_CACHE_TYPE=CACHE_NONE \
	PHP_UPLOAD_MAX_FILESIZE=2M \
	PHP_POST_MAX_SIZE=8M \
	PHP_LOG_ERRORS=On \
    PHP_ERROR_REPORTING=E_ALL

COPY ssmtp.conf /etc/ssmtp/ssmtp.conf

COPY php.ini /etc/php.d/90-mediawiki.ini
COPY mediawiki.conf /etc/httpd/conf.d/

COPY run-apache.sh /run-apache.sh
RUN chmod -v +x /run-apache.sh

COPY DockerSettings.php $MW_HOME/DockerSettings.php

CMD ["/run-apache.sh"]
# CMD sleep 100000000000

EXPOSE 80
