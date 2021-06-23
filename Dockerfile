FROM centos:7.9.2009 as base

MAINTAINER pastakhov@yandex.ru

LABEL org.opencontainers.image.source=https://github.com/WikiTeq/docker-wikiteq-mediawiki

ENV MW_VERSION=REL1_35 \
	MW_CORE_VERSION=1.35.2 \
	MW_HOME=/var/www/html/w \
	MW_VOLUME=/mediawiki \
	MW_ORIGIN_FILES=/mw_origin_files \
	WWW_USER=apache \
	WWW_GROUP=apache \
	APACHE_LOG_DIR=/var/log/apache2

# Install requered packages
RUN set -x; \
	yum -y install --nogpgcheck yum-utils \
	https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
	https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
	https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm \
	https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm \
	&& yum-config-manager --enable remi-php74 \
	&& yum -y update \
	&& yum -y install httpd php php-cli php-mysqlnd php-gd php-mbstring php-xml php-intl php-opcache php-pecl-apcu php-redis \
		git composer mysql wget unzip ImageMagick python-pygments ssmtp patch vim mc ffmpeg curl monit \
	&& mkdir -p $MW_ORIGIN_FILES \
	&& mkdir -p $MW_HOME

FROM base as source

##### MediaWiki Core setup
RUN set -x; \
	git clone --depth 1 -b $MW_CORE_VERSION https://gerrit.wikimedia.org/r/mediawiki/core.git $MW_HOME \
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
# Chameleon skin
RUN set -x; \
	cd $MW_HOME/skins \
	&& git clone https://github.com/ProfessionalWiki/chameleon.git \
	&& cd chameleon \
	&& git checkout -b $MW_VERSION c4cd43625c20e8979f2d274b4dd514388f3d47cc

# CologneBlue, Modern, Refreshed skins
RUN set -x; \
	cd $MW_HOME/skins \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/skins/CologneBlue \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/skins/Modern \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/skins/Refreshed

RUN set -x; \
	cd $MW_HOME/skins \
	&& git clone --depth 1 -b v2.3.0 https://github.com/Hutchy68/pivot.git

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
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Favorites \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleDocTag \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EditUser \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EventLogging \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/EventStreamConfig \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SaveSpinner \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UploadWizard \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/CommentStreams \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/GoogleAnalyticsMetrics \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MassMessage \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/MassMessageEmail \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/SemanticDrilldown \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/VEForAll \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/HeaderTabs \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/UrlGetParameters \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/TinyMCE

# switch to version 0.3 TODO remove me for REL1_36
RUN set -x; \
	cd $MW_HOME/extensions/VEForAll \
	&& git fetch origin master \
	&& git checkout 8f83eb6e607b89f6e1a44966e8637cadd7942bd7

# TODO move me above when REL1_35 branch will be created
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/LockAuthor \
	&& cd LockAuthor \
	&& git checkout -b $MW_VERSION ee5ab1ed2bc34ab1b08c799fb1e14e0d5de65953

# TODO move me above when REL1_35 branch will be created
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/EncryptedUploads \
	&& cd EncryptedUploads \
	&& git checkout -b $MW_VERSION 51e3482462f1852e289d5863849b164e1b1a7ea9

# TODO move me above, we use master because of compatibility issues of REL1_35 branch of the extension with core 1.35.1 tag
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/PageExchange \
	&& cd PageExchange \
    && git checkout -b $MW_VERSION 339056ffba8db1a98ff166aa11f639e5bc1ac665

RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/LinkTarget \
	&& cd LinkTarget \
	&& git checkout -b $MW_VERSION ab1aba0a4a138f80c4cd9c86cc53259ca0fe4545

RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone --depth 1 -b $MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/Widgets \
	&& cd Widgets \
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

# PageForms
COPY patches/pageforms-xss-cherry-picked.patch /tmp/pageforms-xss-cherry-picked.patch
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/PageForms \
	&& cd PageForms \
	&& git checkout -b $MW_VERSION d2e48e51eef1 \
	&& git apply /tmp/pageforms-xss-cherry-picked.patch

# NCBITaxonomyLookup
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/NCBITaxonomyLookup

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

# GoogleDocCreator
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/nischayn22/GoogleDocCreator.git \
	&& cd GoogleDocCreator \
	&& git checkout -b $MW_VERSION 63aecabb4292ad9d4e8336a93aec25f977ee633e

# MassPasswordReset
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/nischayn22/MassPasswordReset.git \
	&& cd MassPasswordReset \
	&& git checkout -b $MW_VERSION affaeee6620f9a70b9dc80c53879a35c9aed92c6

# Tabber
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://gitlab.com/hydrawiki/extensions/Tabber.git \
	&& cd Tabber \
	&& git checkout -b $MW_VERSION 6c67baf4d18518fa78e07add4c032d62dd384b06

# UploadWizardExtraButtons
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/vedmaka/mediawiki-extension-UploadWizardExtraButtons.git UploadWizardExtraButtons \
	&& cd UploadWizardExtraButtons \
	&& git checkout -b $MW_VERSION accba1b9b6f50e67d709bd727c9f4ad6de78c0c0

# Mendeley
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/nischayn22/Mendeley.git \
	&& cd Mendeley \
	&& git checkout -b $MW_VERSION b866c3608ada025ce8a3e161e4605cd9106056c4

# Scopus
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/nischayn22/Scopus.git \
	&& cd Scopus \
	&& git checkout -b $MW_VERSION 4fe8048459d9189626d82d9d93a0d5f906c43746

# SemanticQueryInterface
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/vedmaka/SemanticQueryInterface.git \
	&& cd SemanticQueryInterface \
	&& git checkout -b $MW_VERSION 0016305a95ecbb6ed4709bfa3fc6d9995d51336f \
# FIXME in the repo
	&& mv SemanticQueryInterface/* . \
	&& rmdir SemanticQueryInterface \
	&& ln -s SQI.php SemanticQueryInterface.php \
	&& rm -fr .git

# SRFEventCalendarMod
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/vedmaka/mediawiki-extension-SRFEventCalendarMod.git SRFEventCalendarMod \
	&& cd SRFEventCalendarMod \
	&& git checkout -b $MW_VERSION e0dfa797af0709c90f9c9295d217bbb6d564a7a8

# Sync
RUN set -x; \
	cd $MW_HOME/extensions \
	&& git clone https://github.com/nischayn22/Sync.git \
	&& cd Sync \
	&& git checkout -b $MW_VERSION f56b956521f383221737261ad68aef2367466b76

# GTag1
COPY sources/GTag1.2.0.tar.gz /tmp/
RUN set -x; \
	tar -xvf /tmp/GTag*.tar.gz -C $MW_HOME/extensions \
	&& rm /tmp/GTag*.tar.gz \

# SemanticExternalQueryLookup (WikiTeq fork)
RUN set -x; \
    cd $MW_HOME/extensions \
    && git clone https://github.com/WikiTeq/SemanticExternalQueryLookup.git

# Resolve composer conflicts for GoogleAnalyticsMetrics extension TODO remove me when update the core or extension
COPY patches/core-fix-composer-for-GoogleAnalyticsMetrics.diff /tmp/core-fix-composer-for-GoogleAnalyticsMetrics.diff
RUN set -x; \
	cd $MW_HOME \
	&& git apply /tmp/core-fix-composer-for-GoogleAnalyticsMetrics.diff

# we should run composer update before patches because we need to patch installed extensions by composer too
COPY composer.local.json $MW_HOME/composer.local.json
RUN set -x; cd $MW_HOME && composer update --no-dev

# PATCHES
# SemanticResultFormats, see https://github.com/WikiTeq/SemanticResultFormats/compare/master...WikiTeq:fix1_35
COPY patches/semantic-result-formats.patch /tmp/semantic-result-formats.patch
RUN set -x; \
	cd $MW_HOME/extensions/SemanticResultFormats \
	&& patch < /tmp/semantic-result-formats.patch

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

FROM base as final

COPY --from=source $MW_HOME $MW_HOME
COPY --from=source $MW_ORIGIN_FILES $MW_ORIGIN_FILES

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
	MW_DB_TYPE=mysql \
	MW_DB_SERVER=db \
	MW_CIRRUS_SEARCH_SERVERS=elasticsearch \
	MW_MAINTENANCE_CIRRUSSEARCH_UPDATECONFIG=1 \
	MW_MAINTENANCE_CIRRUSSEARCH_FORCEINDEX=1 \
	MW_ENABLE_JOB_RUNNER=true \
	MW_JOB_RUNNER_PAUSE=2 \
	MW_ENABLE_TRANSCODER=true \
	MW_JOB_TRANSCODER_PAUSE=60 \
	MW_MAP_DOMAIN_TO_DOCKER_GATEWAY=0 \
	MW_ENABLE_SITEMAP_GENERATOR=false \
	MW_SITEMAP_PAUSE_DAYS=1 \
	PHP_UPLOAD_MAX_FILESIZE=2M \
	PHP_POST_MAX_SIZE=8M

COPY ssmtp.conf /etc/ssmtp/ssmtp.conf
COPY php_error_reporting.ini php_upload_max_filesize.ini /etc/php.d/
COPY mediawiki.conf /etc/httpd/conf.d/
COPY robots.txt .htaccess /var/www/html/
COPY run-apache.sh mwjobrunner.sh mwsitemapgen.sh mwtranscoder.sh monit-slack.sh rotatelogs-compress.sh getMediawikiSettings.php /
COPY DockerSettings.php $MW_HOME/DockerSettings.php

# update packages every time!
RUN set -x; \
	yum -y update \
	&& sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf \
	&& chmod -v +x /*.sh \
	&& mkdir $MW_HOME/sitemap \
	&& chown $WWW_USER:$WWW_GROUP $MW_HOME/sitemap \
	&& chmod g+w $MW_HOME/sitemap \
# Install Monit & monit-slack-hook to watch low disk space
# The hook will do nothing unless the $MONIT_SLACK_HOOK is provided
	&& echo $'set httpd port 2812 and\n\tuse address localhost\n\tallow localhost' >> /etc/monitrc \
	&& echo $'check filesystem rootfs with path /\n\tif SPACE usage > 90% then exec "/monit-slack.sh"' > /etc/monit.d/hdd \
# Comment out ErrorLog and CustomLog parameters, we use rotatelogs in mediawiki.conf for the log files
	&& sed -i 's/^\(\s*ErrorLog .*\)/# \1/g' /etc/httpd/conf/httpd.conf \
	&& sed -i 's/^\(\s*CustomLog .*\)/# \1/g' /etc/httpd/conf/httpd.conf

CMD ["/run-apache.sh"]

EXPOSE 80

WORKDIR $MW_HOME
