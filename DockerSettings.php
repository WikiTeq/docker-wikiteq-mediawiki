<?php

# Protect against web entry
if ( !defined( 'MEDIAWIKI' ) ) {
	exit;
}

const DOCKER_SKINS = [
	'chameleon',
	'CologneBlue',
	'MinervaNeue',
	'Modern',
	'MonoBook', # bundled
	'Refreshed',
	'Timeless', # bundled
	'Vector', # bundled
];

const DOCKER_EXTENSIONS = [
	'AdminLinks',
	'AdvancedSearch',
	'AJAXPoll',
	'AntiSpoof',
	'ApprovedRevs',
	'Arrays',
	'BetaFeatures',
	'Bootstrap',
	'BreadCrumbs2',
	'CategoryTree', # bundled
	'ChangeAuthor',
	'CharInsert',
	'CheckUser',
	'CirrusSearch',
	'ContributionScores',
	'Elastica',
	'Cite', # bundled
	'CiteThisPage', # bundled
	'CodeEditor', # bundled
	'CodeMirror',
	'Collection',
	'CommentStreams',
	'CommonsMetadata',
	'ConfirmAccount',
	'ConfirmEdit', # bundled
	'ConfirmEdit/QuestyCaptcha', # bundled
	'ConfirmEdit/ReCaptchaNoCaptcha', # bundled
	'ContactPage',
	'DataTransfer',
	'DebugMode',
	'Description2',
	'Disambiguator',
	'DismissableSiteNotice',
	'DisplayTitle',
	'Echo',
	'EditAccount',
	'EmbedVideo',
	'EncryptedUploads',
	'EventLogging',
	'EventStreamConfig',
	'ExternalData',
	'Favorites',
	'FixedHeaderTable',
	'Flow',
	'Gadgets', # bundled
	'GlobalNotice',
	'googleAnalytics',
	'GoogleAnalyticsMetrics',
	'GoogleDocCreator',
	'GoogleDocTag',
	'GTag',
	'HeaderFooter',
	'HeaderTabs',
	'HeadScript',
	'HTMLTags',
	'IframePage',
	'ImageMap', # bundled
	'InputBox', # bundled
	'Interwiki', # bundled
	'LabeledSectionTransclusion',
	'Lazyload',
	'Lingo',
	'LinkSuggest',
	'LinkTarget',
	'LiquidThreads',
	'LocalisationUpdate', # bundled
	'LockAuthor',
	'Lockdown',
	'LookupUser',
	'Loops',
	'Maps',
	'MassMessage',
	'MassMessageEmail',
	'MassPasswordReset',
	'Math',
	'Mendeley',
	'MobileDetect',
	'MobileFrontend',
	'MsUpload',
	'MultimediaViewer', # bundled
	'MyVariables',
	'NCBITaxonomyLookup',
	'Nuke', # bundled
	'NumerAlpha',
	'OATHAuth', # bundled
	'OpenGraphMeta',
	'OpenIDConnect',
	'PageExchange',
	'PageImages', # bundled
//	'PageForms',   must be enabled manually after enableSemantics()
	'PageSchemas',
	'ParserFunctions', # bundled
	'PDFEmbed',
	'PdfHandler', # bundled
	'PluggableAuth',
	'Poem', # bundled
	'Popups',
	'PubmedParser',
	'Renameuser', # bundled
	'ReplaceText', # bundled
	'RevisionSlider',
	'RottenLinks',
	'SandboxLink',
	'SaveSpinner',
	'Scopus',
	'Scribunto', # bundled
	'SecureLinkFixer', # bundled
	'SelectCategory',
	'SemanticExternalQueryLookup',
	'SemanticExtraSpecialProperties',
	'SemanticCompoundQueries',
	'SemanticDrilldown',
	'SemanticQueryInterface',
	'SemanticResultFormats',
	'SemanticScribunto',
	'ShowMe',
	'SimpleChanges',
	'SimpleMathJax',
	'Skinny',
	'SkinPerNamespace',
	'SkinPerPage',
	'SocialProfile',
	'SoundManager2Button',
	'SpamBlacklist', # bundled
	'SRFEventCalendarMod',
	'SubPageList',
	'Survey',
	'Sync',
	'SyntaxHighlight_GeSHi', # bundled
	'Tabber',
	'Tabs',
	'TalkRight',
	'TemplateData', # bundled
	'TemplateStyles',
	'TextExtracts', # bundled
	'Thanks',
	'TimedMediaHandler',
	'TinyMCE',
	'TitleBlacklist', # bundled
	'TwitterTag',
	'UniversalLanguageSelector',
	'UploadWizard',
	'UploadWizardExtraButtons',
	'UrlGetParameters',
	'UserMerge',
	'Variables',
	'VEForAll',
	'VisualEditor', # bundled
	'VoteNY',
	'WhoIsWatching',
	'Widgets',
	'WikiEditor', # bundled
	'WikiForum',
	'WikiSEO',
	'Wiretap',
	'YouTube',
];

$DOCKER_MW_VOLUME = getenv( 'MW_VOLUME' );

########################### Core Settings ##########################

# The name of the site. This is the name of the site as displayed throughout the site.
$wgSitename  = getenv( 'MW_SITE_NAME' );

$wgMetaNamespace = "Project";

## The URL base path to the directory containing the wiki;
## defaults for all runtime URL paths are based off of this.
## For more information on customizing the URLs
## (like /w/index.php/Page_title to /wiki/Page_title) please see:
## https://www.mediawiki.org/wiki/Manual:Short_URL
$wgScriptPath = "/w";
$wgScriptExtension = ".php";

## The protocol and server name to use in fully-qualified URLs
if ( getenv( 'MW_SITE_SERVER' ) ) {
	$wgServer = getenv( 'MW_SITE_SERVER' );
}

## The URL path to static resources (images, scripts, etc.)
$wgResourceBasePath = $wgScriptPath;

## UPO means: this is also a user preference option

$wgEnableEmail = (bool)getenv( 'MW_ENABLE_EMAIL' );
$wgEnableUserEmail = (bool)getenv( 'MW_ENABLE_USER_EMAIL' );

$wgEmergencyContact = getenv( 'MW_EMERGENCY_CONTACT' );
$wgPasswordSender = getenv( 'MW_PASSWORD_SENDER' );

$wgEnotifUserTalk = false; # UPO
$wgEnotifWatchlist = false; # UPO
$wgEmailAuthentication = true;

## Database settings
$wgSQLiteDataDir = "$DOCKER_MW_VOLUME/sqlite";
$wgDBtype = getenv( 'MW_DB_TYPE' );
$wgDBserver = getenv( 'MW_DB_SERVER' );
$wgDBname = getenv( 'MW_DB_NAME' );
$wgDBuser = getenv( 'MW_DB_USER' );
$wgDBpassword = getenv( 'MW_DB_PASS' );

# MySQL specific settings
$wgDBprefix = "";

# MySQL table options to use during installation or update
$wgDBTableOptions = "ENGINE=InnoDB, DEFAULT CHARSET=binary";

# Periodically send a pingback to https://www.mediawiki.org/ with basic data
# about this MediaWiki instance. The Wikimedia Foundation shares this data
# with MediaWiki developers to help guide future development efforts.
$wgPingback = false;

## If you use ImageMagick (or any other shell command) on a
## Linux server, this will need to be set to the name of an
## available UTF-8 locale
$wgShellLocale = "en_US.utf8";

## Set $wgCacheDirectory to a writable directory on the web server
## to make your wiki go slightly faster. The directory should not
## be publicly accessible from the web.
$wgCacheDirectory = getenv( 'MW_USE_CACHE_DIRECTORY' ) ? "$IP/cache" : false;

$wgSecretKey = getenv( 'MW_SECRET_KEY' );

# Changing this will log out all existing sessions.
$wgAuthenticationTokenVersion = "1";

## For attaching licensing metadata to pages, and displaying an
## appropriate copyright notice / icon. GNU Free Documentation
## License and Creative Commons licenses are supported so far.
$wgRightsPage = ""; # Set to the title of a wiki page that describes your license/copyright
$wgRightsUrl = "";
$wgRightsText = "";
$wgRightsIcon = "";

# Path to the GNU diff3 utility. Used for conflict resolution.
$wgDiff3 = "/usr/bin/diff3";

# see https://www.mediawiki.org/wiki/Manual:$wgCdnServersNoPurge
$wgCdnServersNoPurge = [ '172.16.0.0/12' ]; # Add docker network as CDN

if ( getenv( 'MW_SHOW_EXCEPTION_DETAILS' ) === 'true' ) {
	$wgShowExceptionDetails = true;
}

# Site language code, should be one of the list in ./languages/Names.php
$wgLanguageCode = getenv( 'MW_SITE_LANG' ) ?: 'en';

# Allow images and other files to be uploaded through the wiki.
$wgEnableUploads  = (bool)getenv( 'MW_ENABLE_UPLOADS' );
$wgUseImageMagick = (bool)getenv( 'MW_USE_IMAGE_MAGIC' );

####################### Skin Settings #######################
# Default skin: you can change the default skin. Use the internal symbolic
# names, ie 'standard', 'nostalgia', 'cologneblue', 'monobook', 'vector':
$wgDefaultSkin = getenv( 'MW_DEFAULT_SKIN' );
$dockerLoadSkins = null;
$dockerLoadSkins = getenv( 'MW_LOAD_SKINS' );
if ( $dockerLoadSkins ) {
	$dockerLoadSkins = explode( ',', $dockerLoadSkins );
	$dockerLoadSkins = array_intersect( DOCKER_SKINS, $dockerLoadSkins );
	if ( $dockerLoadSkins ) {
		wfLoadSkins( $dockerLoadSkins );
	}
}
if ( !$dockerLoadSkins ) {
	wfLoadSkin( 'Vector' );
	$wgDefaultSkin = 'Vector';
} else{
	if ( !$wgDefaultSkin ) {
		$wgDefaultSkin = reset( $dockerLoadSkins );
	}
	$dockerLoadSkins = array_combine( $dockerLoadSkins, $dockerLoadSkins );
}

if ( isset( $dockerLoadSkins['chameleon'] ) ) {
	wfLoadExtension( 'Bootstrap' );
}

####################### Extension Settings #######################
// The variable will be an array [ 'extensionName' => 'extensionName, ... ]
// made by see array_combine( $dockerLoadExtensions, $dockerLoadExtensions ) below
$dockerLoadExtensions = getenv( 'MW_LOAD_EXTENSIONS' );
if ( $dockerLoadExtensions ) {
	$dockerLoadExtensions = explode( ',', $dockerLoadExtensions );
	$dockerLoadExtensions = array_intersect( DOCKER_EXTENSIONS, $dockerLoadExtensions );
	if ( $dockerLoadExtensions ) {
		$dockerLoadExtensions = array_combine( $dockerLoadExtensions, $dockerLoadExtensions );
		foreach ( $dockerLoadExtensions as $extension ) {
			if ( file_exists( "$wgExtensionDirectory/$extension/extension.json" ) ) {
				wfLoadExtension( $extension );
			} else {
				require_once "$wgExtensionDirectory/$extension/$extension.php";
			}
		}
	}
}

# SyntaxHighlight_GeSHi
$wgPygmentizePath = '/usr/bin/pygmentize';

# SemanticMediaWiki
$smwgConfigFileDir = "$DOCKER_MW_VOLUME/extensions/SemanticMediaWiki/config";

// Scribunto https://www.mediawiki.org/wiki/Extension:Scribunto
if ( isset( $dockerLoadExtensions['Scribunto'] ) ) {
	$wgScribuntoDefaultEngine = 'luastandalone';
	$wgScribuntoUseGeSHi = boolval( $dockerLoadExtensions['SyntaxHighlight_GeSHi'] ?? false );
	$wgScribuntoUseCodeEditor = boolval( $dockerLoadExtensions['CodeEditor'] ?? false );
	$wgScribuntoEngineConf['luastandalone']['luaPath'] = "$IP/extensions/Scribunto/includes/engines/LuaStandalone/binaries/lua5_1_5_linux_64_generic/lua";
}

# Interwiki
$wgGroupPermissions['sysop']['interwiki'] = true;

# InstantCommons allows wiki to use images from http://commons.wikimedia.org
$wgUseInstantCommons  = (bool)getenv( 'MW_USE_INSTANT_COMMONS' );

# Name used for the project namespace. The name of the meta namespace (also known as the project namespace), used for pages regarding the wiki itself.
#$wgMetaNamespace = 'Project';
#$wgMetaNamespaceTalk = 'Project_talk';

# The relative URL path to the logo.  Make sure you change this from the default,
# or else you'll overwrite your logo when you upgrade!
$wgLogo = "$wgScriptPath/logo.png";

##### Short URLs
## https://www.mediawiki.org/wiki/Manual:Short_URL
$wgArticlePath = '/wiki/$1';
## Also see mediawiki.conf

##### Jobs
# Number of jobs to perform per request. see https://www.mediawiki.org/wiki/Manual:$wgJobRunRate
$wgJobRunRate = 0;

##### Improve performance
# https://www.mediawiki.org/wiki/Manual:$wgMainCacheType
switch ( getenv( 'MW_MAIN_CACHE_TYPE' ) ) {
	case 'CACHE_ACCEL':
		# APC has several problems in latest versions of WediaWiki and extensions, for example:
		# https://www.mediawiki.org/wiki/Extension:Flow#.22Exception_Caught:_CAS_is_not_implemented_in_Xyz.22
		$wgMainCacheType = CACHE_ACCEL;
		$wgSessionCacheType = CACHE_DB; #This may cause problems when CACHE_ACCEL is used
		break;
	case 'CACHE_DB':
		$wgMainCacheType = CACHE_DB;
		break;
	case 'CACHE_ANYTHING':
		$wgMainCacheType = CACHE_ANYTHING;
		break;
	case 'CACHE_MEMCACHED':
		# Use Memcached, see https://www.mediawiki.org/wiki/Memcached
		$wgMainCacheType = CACHE_MEMCACHED;
		$wgParserCacheType = CACHE_MEMCACHED; # optional
		$wgMessageCacheType = CACHE_MEMCACHED; # optional
		$wgMemCachedServers = explode( ',', getenv( 'MW_MEMCACHED_SERVERS' ) );
		$wgSessionsInObjectCache = true; # optional
		$wgSessionCacheType = CACHE_MEMCACHED; # optional
		break;
	case 'CACHE_REDIS':
		$wgObjectCaches['redis'] = [
			'class' => 'RedisBagOStuff',
			'servers' => ['redis:6379']
		];
		$wgMainCacheType = 'redis';
		$wgSessionCacheType = CACHE_DB;
		break;
	default:
		$wgMainCacheType = CACHE_NONE;
}

# Use Varnish accelerator
$tmpProxy = getenv( 'MW_PROXY_SERVERS' );
if ( $tmpProxy ) {
	# https://www.mediawiki.org/wiki/Manual:Varnish_caching
	$wgUseCdn = true;
	$wgCdnServers = explode( ',', $tmpProxy );
	$wgUsePrivateIPs = true;
	# Use HTTP protocol for internal connections like PURGE request to Varnish
	if ( strncasecmp( $wgServer, 'https://', 8 ) === 0 ) {
		$wgInternalServer = 'http://' . substr( $wgServer, 8 ); // Replaces HTTPS with HTTP
	}
}

######################### Custom Settings ##########################
if ( file_exists( "$IP/_settings/LocalSettings.php" ) ) {
	require_once "$IP/_settings/LocalSettings.php";
} elseif ( file_exists( "$IP/CustomSettings.php" ) ) {
	require_once "$IP/CustomSettings.php";
}

# Flow https://www.mediawiki.org/wiki/Extension:Flow
if ( isset( $dockerLoadExtensions['Flow'] ) ) {
	$flowNamespaces = getenv( 'MW_FLOW_NAMESPACES' );
	if ( $flowNamespaces ) {
		$wgFlowContentFormat = 'html';
		foreach ( explode( ',', $flowNamespaces ) as $ns ) {
			$wgNamespaceContentModels[ constant( $ns ) ] = 'flow-board';
		}
	}
}

########################### Search Type ############################
switch( getenv( 'MW_SEARCH_TYPE' ) ) {
	case 'CirrusSearch':
		# https://www.mediawiki.org/wiki/Extension:CirrusSearch
		wfLoadExtension( 'Elastica' );
		wfLoadExtension( 'CirrusSearch' );
		$wgCirrusSearchServers =  explode( ',', getenv( 'MW_CIRRUS_SEARCH_SERVERS' ) );
		if ( isset( $flowNamespaces ) ) {
			$wgFlowSearchServers = $wgCirrusSearchServers;
		}
		$wgSearchType = 'CirrusSearch';
		break;
}

########################### Sitemap ############################
if ( getenv('MW_ENABLE_SITEMAP_GENERATOR') === 'true' ) {
	$wgHooks['BeforePageDisplay'][] = function ( $out, $skin ) {
		global $wgScriptPath;
		$out->addLink( [
			'rel' => 'sitemap',
			'type' => 'application/xml',
			'title' => 'Sitemap',
			'href' => $wgScriptPath . '/sitemap/sitemap-index-mediawiki.xml'
		] );
	};
}

# Debug mode
$wgDebugMode = getenv('MW_DEBUG_MODE') === 'true';
if( $wgDebugMode ) {
	if( isset( $wgDebugModeForIP ) && $_SERVER['REMOTE_ADDR'] == $wgDebugModeForIP ) {
		wfLoadExtension( 'DebugMode' );
	}
}

# Sentry
$wgSentryDsn = getenv('MW_SENTRY_DSN');
if ( $wgSentryDsn ) {
	wfLoadExtension( 'Sentry' );
}

# Fixes CVE-2021-44858, CVE-2021-45038, CVE-2021-44857, https://www.mediawiki.org/wiki/2021-12_security_release/FAQ
$wgActions['mcrundo'] = false;
$wgActions['mcrrestore'] = false;
$wgWhitelistRead = [];
$wgWhitelistReadRegexp = [];
