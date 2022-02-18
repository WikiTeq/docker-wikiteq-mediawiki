# WikiTeq's MediaWiki Docker image

[![Docker build and push](https://github.com/WikiTeq/docker-wikiteq-mediawiki/actions/workflows/docker-image.yml/badge.svg)](https://github.com/WikiTeq/docker-wikiteq-mediawiki/actions/workflows/docker-image.yml)

The image is based on `centos` and runs [MediaWiki](https://www.mediawiki.org/) software.
The image consists of the following:

* Apache 2.x web server
* PHP 7.x
* Monit
* ImageMagick + FFMpeg + Curl
* Composer
* ClamAV client

**Note**: the image does not contain a database embed, so it won't work without 
external MySQL/MariaDB instance connected.

# Quick start

## From scratch via [Docker Compose](https://docs.docker.com/compose/)
* Clone the sample stack repository https://github.com/WikiTeq/docker-wikiteq-stack
* Copy `.env.example` to `.env`
* Modify the `.env` file if necessary
* Run `docker-compose up -d`

## From existing wiki dump via [Docker Compose](https://docs.docker.com/compose/)
* Clone the sample stack repository https://github.com/WikiTeq/docker-wikiteq-stack
* Copy `.env.example` to `.env`
* Modify the `.env` file if necessary
* Copy your existing database dump to `__initdb` directory (both `.sql` and `.gz` formats are supported)
* Copy your existing `images` directory to `_data/mediawiki/images`
* Copy your wiki `LocalSettings.php` file to `_settings/LocalSettings.php`
* Run `docker-compose up -d`

See https://hub.docker.com/_/mysql/ for details on the database dumps importing.

## [Docker Compose](https://docs.docker.com/compose/) base template
The base minimal `docker-compose.yml` template could look like below:

```yml
version: '2'
services:
  db:
    image: mysql:8.0
    command: --default-authentication-plugin=mysql_native_password --expire_logs_days=3
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_HOST=%
      - MYSQL_ROOT_PASSWORD=${MW_DB_INSTALLDB_PASS:-mediawiki}
      - MYSQL_DATABASE=${MW_DB_NAME:-mediawiki}
    volumes:
      - ./__initdb:/docker-entrypoint-initdb.d
      - ./_data/mysql:/var/lib/mysql

  web:
    image: ghcr.io/wikiteq/mediawiki:latest
    restart: unless-stopped
    ports:
      - "${PORT:-80}:80"
    links:
      - db
    environment:
      # Use .env file to provide values
      - MW_ADMIN_USER=${MW_ADMIN_USER:-admin}
      - MW_ADMIN_PASS=${MW_ADMIN_PASS:-admin}
      - MW_DB_NAME=${MW_DB_NAME:-mediawiki}
      - MW_DB_INSTALLDB_USER=${MW_DB_INSTALLDB_USER:-root}
      - MW_DB_INSTALLDB_PASS=${MW_DB_INSTALLDB_PASS:-mediawiki}
      - MW_DB_USER=${MW_DB_USER:-root}
      - MW_DB_PASS=${MW_DB_PASS:-mediawiki}
      - MW_LOAD_SKINS=${MW_LOAD_SKINS:-Vector}
      - MW_DEFAULT_SKIN=${MW_DEFAULT_SKIN:-Vector}
      - MW_LOAD_EXTENSIONS=${MW_LOAD_EXTENSIONS:-ParserFunctions,WikiEditor}
    volumes:
      - ./_data/mediawiki:/mediawiki
      - ./_logs/httpd:/var/log/httpd
      - ./_logs/mediawiki:/var/log/mediawiki
```

The latest recommended version of the stack can be found at
https://github.com/WikiTeq/docker-wikiteq-stack with details
on the directories structure

# Environment variables

Below is the list of evironment variables used by the image:

- `MW_SITE_SERVER` configures [$wgServer](https://www.mediawiki.org/wiki/Manual:$wgServer); set this to the server host and include the protocol like `http://my-wiki:8080`
- `MW_SITE_NAME` configures [$wgSitename](https://www.mediawiki.org/wiki/Manual:$wgSitename)
- `MW_SITE_LANG` configures [$wgLanguageCode](https://www.mediawiki.org/wiki/Manual:$wgLanguageCode)
- `MW_DEFAULT_SKIN` configures [$wgDefaultSkin](https://www.mediawiki.org/wiki/Manual:$wgDefaultSkin)
- `MW_ENABLE_UPLOADS` configures [$wgEnableUploads](https://www.mediawiki.org/wiki/Manual:$wgEnableUploads)
- `MW_USE_INSTANT_COMMONS` configures [$wgUseInstantCommons](https://www.mediawiki.org/wiki/Manual:$wgUseInstantCommons)
- `MW_ADMIN_USER` configures the default administrator username
- `MW_ADMIN_PASS` configures the default administrator password
- `MW_DB_NAME` specifies the database name that will be created automatically upon container startup
- `MW_DB_USER` specifies the database user for access to the database specified in `MW_DB_NAME`
- `MW_DB_PASS` specifies the database user password
- `MW_DB_INSTALLDB_USER` specifies the database superuser name for create database and user specified above
- `MW_DB_INSTALLDB_PASS` specifies the database superuser password; should be the same as `MYSQL_ROOT_PASSWORD` in db section.
- `MW_PROXY_SERVERS` (comma separated values) configures [$wgSquidServers](https://www.mediawiki.org/wiki/Manual:$wgSquidServers). Leave empty if no reverse proxy server used.
- `MW_MAIN_CACHE_TYPE` configures [$wgMainCacheType](https://www.mediawiki.org/wiki/Manual:$wgMainCacheType). `MW_MEMCACHED_SERVERS` should be provided for `CACHE_MEMCACHED`.
- `MW_MEMCACHED_SERVERS` (comma separated values) configures [$wgMemCachedServers](https://www.mediawiki.org/wiki/Manual:$wgMemCachedServers).
- `MW_AUTOUPDATE` if `true` (by default), run needed maintenance scripts automatically before web server start.
- `MW_SHOW_EXCEPTION_DETAILS` if `true` (by default) configures [$wgShowExceptionDetails](https://www.mediawiki.org/wiki/Manual:$wgShowExceptionDetails) as true.
- `PHP_LOG_ERRORS` specifies `log_errors` parameter in `php.ini` file.
- `PHP_ERROR_REPORTING` specifies `error_reporting` parameter in `php.ini` file. `E_ALL` by default, on production should be changed to `E_ALL & ~E_DEPRECATED & ~E_STRICT`.
- `MW_ENABLE_SITEMAP_GENERATOR` defines if sitemap generation is enabled or not
- `MW_SITEMAP_PAUSE_DAYS` if the above is enabled, sets the delys between sitemap regenerations
- `PHP_UPLOAD_MAX_FILESIZE` sets max upload size
- `PHP_POST_MAX_SIZE` sets max post size
- `LOG_FILES_COMPRESS_DELAY` sets logs compression delay in seconds
- `LOG_FILES_REMOVE_OLDER_THAN_DAYS` sets lifespan for old logs
- `MW_ENABLE_TRANSCODER` defines if the transcoder service is enabled
- `MW_JOB_TRANSCODER_PAUSE` sets the transcoder service delay in seconds
- `MW_ENABLE_JOB_RUNNER` defines if the job runner service is enabled
- `MW_JOB_RUNNER_PAUSE` sets the job runner service delay in seconds
- `MW_ENABLE_EMAIL` controls the `$wgEnableEmail`
- `MW_ENABLE_USER_EMAIL` controls the `$wgEnableUserEmail`
- `MW_EMERGENCY_CONTACT` controls the `$wgEmergencyContact`
- `MW_PASSWORD_SENDER` controls the `$wgPasswordSender`
- `MW_DB_TYPE` controls the `$wgDBtype`
- `MW_DB_SERVER` controls the `$wgDBserver`
- `MW_DB_NAME` controls the `$wgDBname`
- `MW_USE_CACHE_DIRECTORY` controls the `$wgCacheDirectory`, if set to `true` puts `$IP/cache` as a value
- `MW_SECRET_KEY` controls the `$wgSecretKey`
- `MW_USE_IMAGE_MAGIC` controls the `$wgUseImageMagick`
- `MW_LOAD_SKINS` controls the list of extension to enable out of the pre-installed skins list (see below)
- `MW_LOAD_EXTENSIONS` controls the list of extension to enable out of the pre-installed extensions list (see below)

# Pre-installed extensions

The image has the following extensions pre-installed. **These pre-installed extensions can be enabled via `MW_LOAD_EXTENSIONS` env:**

* AdminLinks
* AdvancedSearch
* AJAXPoll
* AntiSpoof
* ApprovedRevs
* Arrays
* BetaFeatures
* Bootstrap
* BreadCrumbs2
* CategoryTree
* ChangeAuthor
* CharInsert
* CheckUser
* CirrusSearch
* ContributionScores
* Elastica
* Cite
* CiteThisPage
* CodeEditor
* CodeMirror
* Collection
* CommentStreams
* CommonsMetadata
* ConfirmAccount
* ConfirmEdit
* ConfirmEdit/QuestyCaptcha
* ConfirmEdit/ReCaptchaNoCaptcha
* ContactPage
* DataTransfer
* DebugMode
* Description2
* Disambiguator
* DismissableSiteNotice
* DisplayTitle
* Echo
* EditAccount
* EmbedVideo
* EncryptedUploads
* EventLogging
* EventStreamConfig
* ExternalData
* Favorites
* FixedHeaderTable
* Flow
* Gadgets
* GlobalNotice
* googleAnalytics
* GoogleAnalyticsMetrics
* GoogleDocCreator
* GoogleDocTag
* GTag
* HeaderFooter
* HeaderTabs
* HeadScript
* HTMLTags
* IframePage
* ImageMap
* InputBox
* Interwiki
* LabeledSectionTransclusion
* Lazyload
* Lingo
* LinkSuggest
* LinkTarget
* LiquidThreads
* LocalisationUpdate
* LockAuthor
* Lockdown
* LookupUser
* Loops
* Maps
* MassMessage
* MassMessageEmail
* MassPasswordReset
* Math
* Mendeley
* MobileDetect
* MobileFrontend
* MsUpload
* MultimediaViewer
* MyVariables
* NCBITaxonomyLookup
* Nuke
* NumerAlpha
* OATHAuth
* OpenGraphMeta
* OpenIDConnect
* PageExchange
* PageForms
* PageImages
* PageSchemas
* ParserFunctions
* PdfHandler
* PluggableAuth
* Poem
* Popups
* PubmedParser
* Renameuser
* ReplaceText
* RevisionSlider
* RottenLinks
* SandboxLink
* SaveSpinner
* Scopus
* Scribunto
* SecureLinkFixer
* SelectCategory
* SemanticExternalQueryLookup
* SemanticExtraSpecialProperties
* SemanticCompoundQueries
* SemanticDrilldown
* SemanticMediaWiki
* SemanticQueryInterface
* SemanticResultFormats
* SemanticScribunto
* ShowMe
* SimpleChanges
* SimpleMathJax
* Skinny
* SkinPerNamespace
* SkinPerPage
* SocialProfile
* SoundManager2Button
* SpamBlacklist
* SRFEventCalendarMod
* SubPageList
* Survey
* Sync
* SyntaxHighlight_GeSHi
* Tabber
* Tabs
* TalkRight
* TemplateData
* TemplateStyles
* TextExtracts
* Thanks
* TimedMediaHandler
* TinyMCE
* TitleBlacklist
* TwitterTag
* UniversalLanguageSelector
* UploadWizard
* UploadWizardExtraButtons
* UrlGetParameters
* UserMerge
* Variables
* VEForAll
* VisualEditor
* VoteNY
* WhoIsWatching
* Widgets
* WikiEditor
* WikiForum
* WikiSEO
* Wiretap
* YouTube

# Pre-installed skins

The image has the following skins pre-installed, there extensions can be enabled via `MW_LOAD_SKINS` env:

* chameleon
* CologneBlue
* MinervaNeue
* Modern
* MonoBook
* Refreshed
* Timeless
* Vector

# ClamAV client

The image has the ClamAV client installed, it expects to have a ClamD installed on the Docker host machine (or somewhere else) and won’t work without it.
ClamAV client does not contain the viruses signature database and sends files for scanning to ClamD via TCP Socket (172.17.0.1:3310 by default).

You can install and configure ClamD on the Docker host machine to listen on `TCPSocket 3310` (ClamD default TCP port) and `TCPAddr 172.17.0.1` (Docker default gateway IP available for all containers).
Just add these parameters to `/etc/clamav/clamd.conf` file.
And define the antivirus configuration in `LocalSettings.php` file:
```
# Antivirus configuration
$wgAntivirusSetup = [
	'clamavD' => [
	    'command' => "/usr/bin/clamdscan --no-summary --fdpass %f",
	    'codemap' => [
	        "0"   =>  AV_NO_VIRUS,     #no virus
	        "1"   =>  AV_VIRUS_FOUND,  #virus found
	        "52"  =>  AV_SCAN_ABORTED, #unsupported file format (probably immune)
	        "*"   =>  AV_SCAN_FAILED,  #else scan failed
	    ],
	    'messagepattern' => '/.*?:(.*)/sim', 
	], 
];
# Use daemonized scanner through socket
$wgAntivirus = "clamavD";
```

# LocalSettings.php

Depending on the setup approach the container will handle the settings files as below:

* Fresh install:
** The default `LocalSettings.php` is generated automatically by the MediaWiki's `install.php` script
** The `DockerSettings.php` contains settings specific to the container, it handles all the specific of this image like
  automatically enabling of some settings when certain type of cache is enabled, etc. This file is appended to the default
  `LocalSettings.php` generated above
* Importing existing database:
** The `DockerSettings.php` is symlinked directly as root `LocalSettings.php`

# Custom settings files

The container looks for a custom settings file at `_settings/LocalSettings.php` so
you can mount the `_settings` directory to the container and put the `LocalSettings.php` file there.
This file will be appended to the bottom of the `DockerSettings.php`

# Data (images, database)

Data like uploaded images and the database files stored in the `_data` directory
Docker containers write files to these directories using internal users; most likely you cannot change/remove these directories until you change permissions

# Log files

Log files stored in `_logs` directory

# Runtime directories structure

* `/mediawiki` - the **volume** that stores `images`, `cache` and various extension persistent files like
`compiled_templates` for `Widgets` or `config` files for SMW extension which are being symlinked into `/var/www/html/w`.
  The volume **must** be mounted to persistent storage like a folder outside the docker container (`./_data/mediawiki` for example).
  The container will not start if `/mediawiki` is not mounted to a folder, but if you know what you do,
  you can allow to start the container without mounting `/mediawiki` if you set `MW_ALLOW_UNMOUNTED_VOLUME` environment variable as `true`.
* `/mw_origin_files` - a temp/backup directory to toss some of original files and directories of the wiki core
* `/var/www/html/w` - the main wiki web root
* `/var/log/apache2` - logs for Apache web server

# Service scripts

* `run-apache.sh` - main entrypoint
* `mwjobrunner.sh` - runs MediaWiki jobs via job queue
* `mwtranscoder.sh` - runs transcoding jobs via job queue
* `mwsitemapgen.sh` - generates sitemaps
* `rotatelogs-compress.sh` - rotates and compresses the logs

# Entrypoint

The entrypoint is `run-apache.sh` script. This script does all the necessary stuff related to the
initial container setup, detecting settings, detecting the need to do a fresh wiki install or
database initialization. The script is also in response of stating all the rest of the service scripts.

Simplified actions taken are as below:

* Fetch necessary settings via `getMediawikiSettings.php`
* Do necessary checks to ensure we're good to go
* Syncs `/mw_origin_files` with `/var/www/html/w`
* Sets directories permissions
* Waits for other services to start
* Starts `maintenance/install.php` (if it's a fresh installation) and appends the `DockerSettings.php` to the bottom
of generated `/var/www/html/w/LocalSettings.php`
* Or symlinks `/var/www/html/w/DockerSettings.php` -> `/mediawiki/LocalSettings.php`
* Starts service scripts
* Runs `maintenance/update.php` and SMW maintenance scripts
* Starts the Apache

# Debugging

The image is bundled with [DebugMode](https://www.mediawiki.org/wiki/Extension:DebugMode) extension which can be enabled via `MW_DEBUG_MODE=true` environment variable
plus adding your IP address to `$wgDebugModeForIP` array

