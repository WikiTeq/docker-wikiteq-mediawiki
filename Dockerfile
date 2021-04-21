FROM centos:7.9.2009

MAINTAINER pastakhov@yandex.ru

LABEL org.opencontainers.image.source=https://github.com/WikiTeq/docker-wikiteq-mediawiki

# Install requered packages
RUN set -x; \
	yum -y install httpd \
	https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
	https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
	yum-utils
RUN yum -y localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm \
	https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm
RUN yum-config-manager --enable remi-php74
RUN yum -y update
RUN yum -y install php php-cli php-mysqlnd php-gd php-mbstring php-xml php-intl php-opcache php-pecl-apcu php-redis \
	git composer mysql wget unzip ImageMagick python-pygments ssmtp patch vim mc ffmpeg

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

### Skins
# Chameleon
RUN set -x; \
	cd $MW_HOME/skins \
	&& git clone https://github.com/ProfessionalWiki/chameleon.git \
	&& cd chameleon \
	&& git checkout -b $MW_VERSION c4cd43625c20e8979f2d274b4dd514388f3d47cc

# Refreshed
RUN set -x; \
	cd $MW_HOME/skins \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/skins/Refreshed

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
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Math \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Echo \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ChangeAuthor \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ContactPage \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/IframePage \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MsUpload \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SelectCategory \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ShowMe \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SoundManager2Button \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CirrusSearch \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Elastica \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/googleAnalytics \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UniversalLanguageSelector \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Survey \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LiquidThreads \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CodeMirror \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Flow \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/ApprovedRevs \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Collection \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HTMLTags \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/BetaFeatures \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SkinPerNamespace \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SkinPerPage \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CharInsert \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Tabs \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AdvancedSearch \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CheckUser \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CommonsMetadata \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TimedMediaHandler \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SocialProfile \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiForum \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/VoteNY \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AJAXPoll \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/YouTube \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/AntiSpoof \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Popups \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Description2 \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Thanks \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileDetect \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SimpleChanges \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UserMerge \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LinkSuggest \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TwitterTag \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateStyles \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/LookupUser \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HeadScript \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Favorites

# TODO move me above when REL1_35 branch will be created
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/LockAuthor \
	&& cd LockAuthor \
	&& git checkout -b $MW_VERSION ee5ab1ed2bc34ab1b08c799fb1e14e0d5de65953

# TODO move me above, we use master because of compatibility issues of REL1_35 branch of the extension with core 1.35.1 tag
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/PageExchange \
	&& cd PageExchange \
    && git checkout -b $MW_VERSION 339056ffba8db1a98ff166aa11f639e5bc1ac665

# Run composer update
#RUN set -x; \
#	cd $MW_HOME/extensions/CirrusSearch \
#	&& composer update --no-dev
RUN set -x; \
	cd $MW_HOME/extensions/CodeMirror \
	&& composer update --no-dev
#RUN set -x; \
#	cd $MW_HOME/extensions/Elastica \
#	&& composer update --no-dev
RUN set -x; \
	cd $MW_HOME/extensions/Flow \
	&& composer update --no-dev
RUN set -x; \
	cd $MW_HOME/extensions/TimedMediaHandler \
	&& composer update --no-dev
RUN set -x; \
	cd $MW_HOME/extensions/AntiSpoof \
	&& composer update --no-dev
RUN set -x; \
	cd $MW_HOME/extensions/TemplateStyles \
	&& composer update --no-dev

COPY composer.local.json $MW_HOME/composer.local.json
RUN set -x; cd $MW_HOME && composer update --no-dev

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

# https://www.mediawiki.org/wiki/Extension:Skinny
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/tinymighty/skinny.git Skinny \
	&& cd Skinny \
	&& git checkout -b $MW_VERSION 41ba4e90522f6fa971a136fab072c3911750e35c

# BreadCrumbs2
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/BreadCrumbs2.git \
	&& cd BreadCrumbs2 \
	&& git checkout -b $MW_VERSION d95826a74eef014be0d9685bdf66d07af0b37777

# https://www.mediawiki.org/wiki/Extension:RottenLinks version 1.0.11
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/miraheze/RottenLinks.git \
	&& cd RottenLinks \
	&& git checkout -b $MW_VERSION 4e7e675bb26fc39b85dd62c9ad37e29d8f705a41

# EmbedVideo
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gitlab.com/hydrawiki/extensions/EmbedVideo.git \
	&& cd EmbedVideo \
	&& git checkout -b $MW_VERSION 85c5219593cc86367ffb17bfb650f73ca3eb9b11

# Lazyload
# TODO change me when https://github.com/mudkipme/mediawiki-lazyload/pull/15 will be merged
RUN set -x; \
	cd $MW_HOME/extensions \
#	&& git clone https://github.com/mudkipme/mediawiki-lazyload.git Lazyload \
	&& git clone https://github.com/WikiTeq/mediawiki-lazyload.git Lazyload \
	&& cd Lazyload \
	&& git checkout -b $MW_VERSION 92172c30ee5ac764627e397b19eddd536155394e

# WikiSEO Dont change me without well testing!
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/WikiSEO \
	&& cd WikiSEO \
	&& git checkout -b $MW_VERSION 30bb8c323e8cd44df52c7537f97f8518de2557df

# GTag1
COPY sources/GTag1.2.0.tar.gz /tmp/
RUN set -x; \
	tar -xvf /tmp/GTag*.tar.gz -C $MW_HOME/extensions \
	&& rm /tmp/GTag*.tar.gz

# PATCHES
# SemanticResultFormats, see https://github.com/WikiTeq/SemanticResultFormats/compare/master...WikiTeq:fix1_35
COPY patches/semantic-result-formats.patch /tmp/semantic-result-formats.patch
RUN set -x; \
	cd $MW_HOME/extensions/SemanticResultFormats \
	&& patch < /tmp/semantic-result-formats.patch

# Rewind ReplaceText to apply fix
# TODO remove me in mw > 1.35.1
RUN set -x; \
	cd $MW_HOME/extensions/ReplaceText \
	&& git pull origin REL1_35

# This path fixes error: `Use of undefined constant CURLMOPT_MAX_HOST_CONNECTIONS`, see https://phabricator.wikimedia.org/T264986
# TODO remove me in mw > 1.35.1
COPY patches/core-fix-for-curl-a2f60bb.diff /tmp/core-fix-for-curl-a2f60bb.diff
RUN set -x; \
	cd $MW_HOME \
	&& git apply /tmp/core-fix-for-curl-a2f60bb.diff

# Fixes PHP parsoid errors when user replies on a flow message, see https://phabricator.wikimedia.org/T260648#6645078
COPY patches/flow-conversion-utils.patch /tmp/flow-conversion-utils.patch
RUN set -x; \
	cd $MW_HOME/extensions/Flow \
	&& git apply /tmp/flow-conversion-utils.patch

# SWM maintenance page returns 503 (Service Unavailable) status code, PR: https://github.com/SemanticMediaWiki/SemanticMediaWiki/pull/4967
COPY patches/smw-maintenance-503.patch /tmp/smw-maintenance-503.patch
RUN set -x; \
	cd $MW_HOME/extensions/SemanticMediaWiki \
	&& patch -u -b src/SetupCheck.php -i /tmp/smw-maintenance-503.patch

# TODO send to upstream, see https://wikiteq.atlassian.net/browse/MW-64 and https://wikiteq.atlassian.net/browse/MW-81
COPY patches/skin-refreshed.patch /tmp/skin-refreshed.patch
RUN set -x; \
	cd $MW_HOME/skins/Refreshed \
	&& patch -u -b includes/RefreshedTemplate.php -i /tmp/skin-refreshed.patch

# Default values
ENV MW_AUTOUPDATE=true \
	MW_MAINTENANCE_UPDATE=0 \
	MW_ENABLE_EMAIL=0 \
	MW_ENABLE_USER_EMAIL=0 \
	MW_ENABLE_UPLOADS=0 \
	MW_USE_IMAGE_MAGIC=0 \
	MW_USE_INSTANT_COMMONS=0 \
	MW_EMERGENCY_CONTACT=apache@invalid \
	MW_PASSWORD_SENDER=apache@invalid \
	MW_MAIN_CACHE_TYPE=CACHE_NONE \
	MW_DB_SERVER=db \
	MW_CIRRUS_SEARCH_SERVERS=elasticsearch \
	MW_MAINTENANCE_CIRRUSSEARCH_UPDATECONFIG=1 \
	MW_MAINTENANCE_CIRRUSSEARCH_FORCEINDEX=1 \
	MW_ENABLE_JOB_RUNNER=true \
	MW_JOB_RUNNER_PAUSE=2 \
	MW_ENABLE_TRANSCODER=true \
	MW_JOB_TRANSCODER_PAUSE=60 \
	MW_MAP_DOMAIN_TO_DOCKER_GATEWAY=0 \
	PHP_UPLOAD_MAX_FILESIZE=2M \
	PHP_POST_MAX_SIZE=8M \
	PHP_LOG_ERRORS=On \
    PHP_ERROR_REPORTING=24567

COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
COPY php.ini /etc/php.d/90-mediawiki.ini
COPY mediawiki.conf /etc/httpd/conf.d/
COPY robots.txt /var/www/html/robots.txt
COPY .htaccess /var/www/html/.htaccess

COPY mwjobrunner.sh /mwjobrunner.sh
RUN chmod -v +x /mwjobrunner.sh
COPY mwtranscoder.sh /mwtranscoder.sh
RUN chmod -v +x /mwtranscoder.sh

COPY run-apache.sh /run-apache.sh
RUN chmod -v +x /run-apache.sh

COPY DockerSettings.php $MW_HOME/DockerSettings.php

CMD ["/run-apache.sh"]

EXPOSE 80
