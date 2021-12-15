#!/bin/bash

wget https://kojipkgs.fedoraproject.org//packages/sqlite/3.8.11/1.fc21/x86_64/sqlite-3.8.11-1.fc21.x86_64.rpm
yum -y install sqlite-3.8.11-1.fc21.x86_64.rpm
composer update
php maintenance/install.php --dbtype sqlite --dbuser root --dbname mw --dbpath $(pwd) --pass AdminPassword WikiName AdminUser
echo 'error_reporting(0);' >> LocalSettings.php
echo 'wfLoadExtension("Bootstrap");' >> LocalSettings.php
echo '$wgShowExceptionDetails = false;' >> LocalSettings.php
echo '$wgShowDBErrorBacktrace = false;' >> LocalSettings.php
echo '$wgDevelopmentWarnings = false;' >> LocalSettings.php
php maintenance/update.php --quick
php tests/phpunit/phpunit.php --stop-on-failure --stop-on-error
