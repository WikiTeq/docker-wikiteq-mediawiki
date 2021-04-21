# Containerized MediaWiki image

## Briefly

This repo contains [Docker Compose](https://docs.docker.com/compose/) containers to run the [MediaWiki](https://www.mediawiki.org/) software.

Clone the repo. Then create and start the containers:
```sh
cd docker-wikiteq-mediawiki
copy a database dump to the __intdb directory
copy images to the `docker-wikiteq-mediawiki/_data/mediawiki/images` directory
docker-compose up
```
Wait for the completion of the build and initialization process and access it via `http://localhost:8081` in a browser.

## Architecture of mediawiki containers

Running `sudo docker-compose up` will start the containers:

- `db` - MySQL [container](https://hub.docker.com/r/pastakhov/mysql/), used as the database backend for MediaWiki.
- `web` - Apache/MediaWiki container with PHP 7.4 and MediaWiki 1.35.0
- `redis` - Redis is an open source key-value store that functions as a data structure server

## Settings

Settings are in the `docker-compose.yml` file, the *environment* sections

also `_resources` contains favicon, logo and styles for chameleon skin
`CustomSettings.php` contains settings for MediaWiki core and extensions; you should change the settings there.

### db
Was cloned from the official [mysql](https://hub.docker.com/_/mysql/) container and has the same environment variables.
The reason that it is better than the official is the ability to automatically update the database when upgrading the version of mysql.
The only one important environment variable for us is `MYSQL_ROOT_PASSWORD`; it specifies the password that will be set for the MySQL `root` superuser account.
If changed, make sure that `MW_DB_INSTALLDB_PASS` in the web section was changed too.

### web

#### environment variables

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

picking up the latest changes, stop, rebuld and start containers:
```sh
cd docker-wikiteq-mediawiki
git pull
docker-compose build
docker-compose stop
docker-compose up
```
The upgrade process is fully automated and includes the launch of all necessary maintenance scripts.
