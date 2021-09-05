#!/bin/bash

set -x

if ! mountpoint -q -- "$MW_VOLUME"; then
    echo "Folder $MW_VOLUME contains important data and must be mounted to persistent storage!"
    if [ "$MW_ALLOW_UNMOUNTED_VOLUME" != true ]; then
        exit 1
    fi
fi

# read variables from LocalSettings.php
get_mediawiki_variable () {
    php /getMediawikiSettings.php --variable="$1" --format="${2:-string}"
}

get_hostname_with_port () {
    port=$(echo "$1" | grep ":" | cut -d":" -f2)
    echo "$1:${port:-$2}"
}

WG_SITE_SERVER=$(get_mediawiki_variable wgServer)
WG_DB_TYPE=$(get_mediawiki_variable wgDBtype)
WG_DB_SERVER=$(get_mediawiki_variable wgDBserver)
WG_DB_NAME=$(get_mediawiki_variable wgDBname)
WG_DB_USER=$(get_mediawiki_variable wgDBuser)
WG_DB_PASSWORD=$(get_mediawiki_variable wgDBpassword)
WG_SQLITE_DATA_DIR=$(get_mediawiki_variable wgSQLiteDataDir)
WG_LANG_CODE=$(get_mediawiki_variable wgLanguageCode)
WG_SITE_NAME=$(get_mediawiki_variable wgSitename)
WG_SEARCH_TYPE=$(get_mediawiki_variable wgSearchType)
WG_CIRRUS_SEARCH_SERVER=$(get_hostname_with_port "$(get_mediawiki_variable wgCirrusSearchServers first)" 9200)
VERSION_HASH=$(php /getMediawikiSettings.php --versions --format=md5)

if [ -z "$WG_DB_SERVER" ]; then
    echo the wgDBserver variable must be defined
    exit 1
fi

# Map the site hostname to 172.17.0.1 for VisualEditor
MW_SITE_HOST=$(echo "$WG_SITE_SERVER" | sed -e 's|^[^/]*//||' -e 's|[:/].*$||')
cp /etc/hosts ~/hosts.new
sed -i '/# MW_SITE_HOST/d' ~/hosts.new

if [ "$MW_MAP_DOMAIN_TO_DOCKER_GATEWAY" != true ]; then
    echo "MW_MAP_DOMAIN_TO_DOCKER_GATEWAY is not true"
elif [[ $MW_SITE_HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "MW_SITE_HOST is IP address '$MW_SITE_HOST'"
else
    echo "Add MW_SITE_HOST '172.17.0.1 $MW_SITE_HOST' to /etc/hosts"
    echo "172.17.0.1 $MW_SITE_HOST # MW_SITE_HOST" >> ~/hosts.new
fi
cp -f ~/hosts.new /etc/hosts

# Create needed directories
rsync -avh --ignore-existing "$MW_ORIGIN_FILES"/ "$MW_VOLUME"/
mkdir -p "$MW_VOLUME"/extensions/SemanticMediaWiki/config

# Allow to write to the directories
chgrp -R "$WWW_GROUP" "$MW_VOLUME"
chmod -R g=rwX "$MW_VOLUME"
chgrp -R "$WWW_GROUP" /var/log/httpd
chmod -R g=rwX /var/log/httpd
chgrp -R "$WWW_GROUP" "$MW_LOG"
chmod -R go=rwX "$MW_LOG"

if [ "$WG_DB_TYPE" = "sqlite" ]; then
    mkdir -p "$WG_SQLITE_DATA_DIR"
    chgrp -R "$WWW_GROUP" "$WG_SQLITE_DATA_DIR"
    chmod -R g=rwX "$WG_SQLITE_DATA_DIR"
fi

wait_database_started ()
{
    if [ -n "$db_started" ]; then
        return 0; # already started
    fi

    if [ "$WG_DB_TYPE" = "sqlite" ]; then
        echo >&2 "SQLite database used"
        db_started="3"
        return 0
    fi

    if [ "$WG_DB_TYPE" != "mysql" ]; then
        echo >&2 "Unsupported database type ($WG_DB_TYPE)"
        exit 123
    fi

    echo >&2 "Waiting for database to start"
    mysql=( mysql -h "$WG_DB_SERVER" -u"$WG_DB_USER" -p"$WG_DB_PASSWORD" )
    mysql_install=( mysql -h "$WG_DB_SERVER" -u"${MW_DB_INSTALLDB_USER:-root}" -p"$MW_DB_INSTALLDB_PASS" )

    for i in {86400..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
            db_started="1"
            break
        fi
        sleep 1
        if echo 'SELECT 1' | "${mysql_install[@]}" &> /dev/null; then
            db_started="2"
            break
        fi
        echo >&2 'Waiting for database to start...'
        sleep 1
    done
    if [ "$i" = 0 ]; then
        echo >&2 'Could not connect to the database.'
        return 1
    fi
    echo >&2 'Successfully connected to the database.'
    return 0
}

get_tables_count() {
    wait_database_started

    if [ "3" = "$db_started" ]; then
        # sqlite
        find "$WG_SQLITE_DATA_DIR" -type f | wc -l
        return 0
    elif [ "1" = "$db_started" ]; then
        db_user="$WG_DB_USER"
        db_password="$WG_DB_PASSWORD"
    else
        db_user="$MW_DB_INSTALLDB_USER"
        db_password="$MW_DB_INSTALLDB_PASS"
    fi
    mysql -h "$WG_DB_SERVER" -u"$db_user" -p"$db_password" -e "SELECT count(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$WG_DB_NAME'" | sed -n 2p
}

wait_elasticsearch_started ()
{
    if [ -n "$es_started" ]; then
        return 0; # already started
    fi

    echo >&2 'Waiting for elasticsearch to start'
    for i in {300..0}; do
        result=0
        output=$(wget --timeout=1 -q -O - "http://$WG_CIRRUS_SEARCH_SERVER/_cat/health") || result=$?
        if [[ "$result" = 0 && $(echo "$output"|awk '{ print $4 }') = "green" ]]; then
            break
        fi
        if [ "$result" = 0 ]; then
            echo >&2 "Waiting for elasticsearch health status changed from [$(echo "$output"|awk '{ print $4 }')] to [green]..."
        else
            echo >&2 'Waiting for elasticsearch to start...'
        fi
        sleep 1
    done
    if [ "$i" = 0 ]; then
        echo >&2 'Could not connect to the elasticsearch'
        echo "$output"
        retirn 1
    fi
    echo >&2 'Elasticsearch started successfully'
    es_started="1"
    return 0
}

run_maintenance_script_if_needed () {
    if [ -f "$MW_VOLUME/$1.info" ]; then
        update_info="$(cat "$MW_VOLUME/$1.info" 2>/dev/null)"
    else
        update_info=""
    fi

    if [[ "$update_info" != "$2" && -n "$2" || "$2" == "always" ]]; then
        wait_database_started
        if [[ "$1" == *CirrusSearch* ]]; then wait_elasticsearch_started; fi

        i=3
        while [ -n "${!i}" ]
        do
            if [ ! -f "$(echo "${!i}" | awk '{print $1}')" ]; then
                echo >&2 "Maintenance script does not exit: ${!i}"
                return 0;
            fi
            echo >&2 "Run maintenance script: ${!i}"
            runuser -c "php ${!i}" -s /bin/bash "$WWW_USER"
            i=$((i+1))
        done

        echo >&2 "Successful updated: $2"
        echo "$2" > "$MW_VOLUME/$1.info"
    else
        echo >&2 "$1 is up to date: $2."
    fi
}

run_script_if_needed () {
    if [ -f "$MW_VOLUME/$1.info" ]; then
        update_info="$(cat "$MW_VOLUME/$1.info" 2>/dev/null)"
    else
        update_info=""
    fi

    if [[ "$update_info" != "$2" && -n "$2" && "${2: -1}" != '-' ]]; then
        wait_database_started
        if [[ "$1" == *CirrusSearch* ]]; then wait_elasticsearch_started; fi
        echo >&2 "Run script: $3"
        eval "$3"

        cd "$MW_HOME" || exit

        echo >&2 "Successful updated: $2"
        echo "$2" > "$MW_VOLUME/$1.info"
    else
        echo "$1 is skipped: $2."
    fi
}

cd "$MW_HOME" || exit

# If there is no LocalSettings.php
if [ ! -e "$MW_VOLUME/LocalSettings.php" ] && [ ! -e "$MW_HOME/LocalSettings.php" ]; then
    echo "There is no LocalSettings.php"

    # Check that the database and table exists (docker creates an empty database)
    tables_count=$(get_tables_count)
    if [[ "$tables_count" -gt 0 ]] ; then
        echo "Database exists. Create a symlink to DockerSettings.php as LocalSettings.php"
        ln -s "$MW_HOME/DockerSettings.php" "$MW_VOLUME/LocalSettings.php"
    else
        for x in MW_DB_INSTALLDB_USER MW_DB_INSTALLDB_PASS MW_ADMIN_USER MW_ADMIN_PASS
        do
            if [ -z "${!x}" ]; then
                echo >&2 "Variable $x must be defined";
                exit 1;
            fi
        done

        echo "Create database and LocalSettings.php using maintenance/install.php"
        php maintenance/install.php \
            --confpath "$MW_VOLUME" \
            --dbserver "$WG_DB_SERVER" \
            --dbtype "$WG_DB_TYPE" \
            --dbname "$WG_DB_NAME" \
            --dbuser "$WG_DB_USER" \
            --dbpass "$WG_DB_PASSWORD" \
            --dbpath "$WG_SQLITE_DATA_DIR" \
            --installdbuser "$MW_DB_INSTALLDB_USER" \
            --installdbpass "$MW_DB_INSTALLDB_PASS" \
            --scriptpath "/w" \
            --lang "$WG_LANG_CODE" \
            --pass "$MW_ADMIN_PASS" \
            --skins "" \
            "$WG_SITE_NAME" \
            "$MW_ADMIN_USER"

        # Append inclusion of DockerSettings.php
        echo "@include('DockerSettings.php');" >> "$MW_VOLUME/LocalSettings.php"
    fi
fi

if [ ! -e "$MW_HOME/LocalSettings.php" ]; then
    ln -s "$MW_VOLUME/LocalSettings.php" "$MW_HOME/LocalSettings.php"
fi

jobrunner() {
    sleep 3
    if [ "$MW_ENABLE_JOB_RUNNER" = true ]; then
        echo >&2 Run Jobs
        nice -n 20 runuser -c /mwjobrunner.sh -s /bin/bash "$WWW_USER"
    else
        echo >&2 Job runner is disabled
    fi
}

transcoder() {
    sleep 3
    if [ "$MW_ENABLE_TRANSCODER" = true ]; then
        echo >&2 Run transcoder
        nice -n 20 runuser -c /mwtranscoder.sh -s /bin/bash "$WWW_USER"
    else
        echo >&2 Transcoder disabled
    fi
}

sitemapgen() {
    sleep 3
    if [ "$MW_ENABLE_SITEMAP_GENERATOR" = true ]; then
        echo >&2 Run sitemap generator
        nice -n 20 runuser -c /mwsitemapgen.sh -s /bin/bash "$WWW_USER"
    else
        echo >&2 Sitemap generator is disabled
    fi
}

run_autoupdate () {
    echo >&2 'Check for the need to run maintenance scripts'
    ### maintenance/update.php

#    if [ "$(php /getMediawikiSettings.php --isSMWValid)" = false ]; then
#        SMW_UPGRADE_KEY=
#        UPDATE_DATABASE_ANYWAY=true
#    else
#        UPDATE_DATABASE_ANYWAY=false
#    fi

    SMW_UPGRADE_KEY=$(php /getMediawikiSettings.php --SMWUpgradeKey)
    run_maintenance_script_if_needed 'maintenance_update' "$MW_VERSION-$MW_CORE_VERSION-$MW_MAINTENANCE_UPDATE-$VERSION_HASH-$SMW_UPGRADE_KEY" \
        'maintenance/update.php --quick'

#    run_maintenance_script_if_needed 'maintenance_update' "always" \
#        'maintenance/update.php --quick'


    # Run incomplete SemanticMediawiki setup tasks
    SMW_INCOMPLETE_TASKS=$(php /getMediawikiSettings.php --SWMIncompleteSetupTasks --format=space)
    for task in $SMW_INCOMPLETE_TASKS
    do
        case $task in
            smw-updateentitycollation-incomplete)
                run_maintenance_script_if_needed 'maintenance_semantic_updateEntityCollation' "always" \
                    'extensions/SemanticMediaWiki/maintenance/updateEntityCollation.php'
                ;;
            smw-updateentitycountmap-incomplete)
                run_maintenance_script_if_needed 'maintenance_semantic_updateEntityCountMap' "always" \
                    'extensions/SemanticMediaWiki/maintenance/updateEntityCountMap.php'
                ;;
            *)
                echo >&2 "######## Unknown SMW maintenance setup task - $task ########"
                ;;
        esac
    done

    ### CirrusSearch
    if [ "$WG_SEARCH_TYPE" == 'CirrusSearch' ]; then
        run_maintenance_script_if_needed 'maintenance_CirrusSearch_updateConfig' "${EXTRA_MW_MAINTENANCE_CIRRUSSEARCH_UPDATECONFIG}${MW_MAINTENANCE_CIRRUSSEARCH_UPDATECONFIG}${MW_VERSION}" \
            'extensions/CirrusSearch/maintenance/UpdateSearchIndexConfig.php --reindexAndRemoveOk --indexIdentifier now' \
            'extensions/CirrusSearch/maintenance/Metastore.php --upgrade'

        run_maintenance_script_if_needed 'maintenance_CirrusSearch_forceIndex' "${EXTRA_MW_MAINTENANCE_CIRRUSSEARCH_FORCEINDEX}${MW_MAINTENANCE_CIRRUSSEARCH_FORCEINDEX}${MW_VERSION}" \
            'extensions/CirrusSearch/maintenance/ForceSearchIndex.php --skipLinks --indexOnSkip' \
            'extensions/CirrusSearch/maintenance/ForceSearchIndex.php --skipParse'
    fi

    ### cldr extension
    if [ -n "$MW_SCRIPT_CLDR_REBUILD" ]; then
    run_script_if_needed 'script_cldr_rebuild' "$MW_VERSION-$MW_SCRIPT_CLDR_REBUILD" \
        "set -x; cd $MW_HOME/extensions/cldr && wget -q http://www.unicode.org/Public/cldr/latest/core.zip && unzip -q core.zip -d core && php rebuild.php && set +x;"

        if [ -n "$MW_MAINTENANCE_ULS_INDEXER" ]; then
            ### UniversalLanguageSelector extension
            run_maintenance_script_if_needed 'maintenance_ULS_indexer' "$MW_VERSION-$MW_SCRIPT_CLDR_REBUILD-$MW_MAINTENANCE_ULS_INDEXER" \
                'extensions/UniversalLanguageSelector/data/LanguageNameIndexer.php'
        fi
    fi

    ### Flow extension
#    if [ -n "$MW_FLOW_NAMESPACES" ]; then
# https://phabricator.wikimedia.org/T172369
#        if [ "$WG_SEARCH_TYPE" == 'CirrusSearch' ]; then
#            # see https://www.mediawiki.org/wiki/Flow/Architecture/Search
#            run_maintenance_script_if_needed 'maintenance_FlowSearchConfig_CirrusSearch' "$MW_MAINTENANCE_CIRRUSSEARCH_UPDATECONFIG" \
#                'extensions/Flow/maintenance/FlowSearchConfig.php'
#        fi
#    fi

    jobrunner &
    transcoder &
    sitemapgen &

    echo Auto-update completed
}

########## Run maintenance scripts ##########
if [ "$MW_AUTOUPDATE" = true ]; then
    run_autoupdate &
else
    echo "Auto update script is disabled, \$MW_AUTOUPDATE is $MW_AUTOUPDATE";
    jobrunner &
    transcoder &
    sitemapgen &
fi

########## Run Monit ##########
if [ -n "$MONIT_SLACK_HOOK" ]; then
    echo "Starting monit.."
    monit -I -c /etc/monitrc &
else
    echo "Skip monit (MONIT_SLACK_HOOK is not defined)"
fi

# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.

############### Run Apache ###############
# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/* /tmp/httpd*

exec /usr/sbin/apachectl -DFOREGROUND
