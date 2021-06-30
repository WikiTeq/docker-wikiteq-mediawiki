# WikiTeq's MediaWiki Docker image

The image is based on `centos` and runs [MediaWiki](https://www.mediawiki.org/) software.

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

## LocalSettings.php

The [LocalSettings.php](https://www.mediawiki.org/wiki/Manual:LocalSettings.php) is divided into three parts:
- LocalSettings.php will be created automatically upon container startup, contains settings specific to the MediaWiki installed instance such as database connection, [$wgSecretKey](https://www.mediawiki.org/wiki/Manual:$wgSecretKey) and etc. **Should not be changed**
- DockerSettings.php contains settings specific to the released containers such as database server name, path to programs, installed extensions, etc. **Should be changed if you make changes to the containers only**
- CustomSettings.php - contains user defined settings such as user rights, extensions settings and etc. **You should make changes there**.
  `CustomSettings.php` placed in folder `_resources` And will be copied to the container during build

## Data (images, database)

Data like uploaded images and the database files stored in the `_data` directory
Docker containers write files to these directories using internal users; most likely you cannot change/remove these directories until you change permissions

## Log files

Log files stored in `_logs` directory

## Keeping up to date

**Make a full backup of the wiki, including both the database and the files.**
While the upgrade scripts are well-maintained and robust, things could still go awry.
```sh
cd docker-wikiteq-mediawiki
docker-compose exec db /bin/bash -c 'mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD" 2>/dev/null | gzip | base64 -w 0' | base64 -d > backup_$(date +"%Y%m%d_%H%M%S").sql.gz
docker-compose exec web /bin/bash -c 'tar -c $MW_VOLUME $MW_HOME/images 2>/dev/null | base64 -w 0' | base64 -d > backup_$(date +"%Y%m%d_%H%M%S").tar
```

pick up the latest changes, stop, rebuild and start containers:

```sh
cd docker-wikiteq-mediawiki
git pull
docker-compose build
docker-compose stop
docker-compose up
```

The upgrade process is fully automated and includes the launch of all necessary maintenance scripts.
