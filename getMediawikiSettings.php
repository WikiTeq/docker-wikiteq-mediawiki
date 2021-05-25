<?php

use MediaWiki\MediaWikiServices;

$mwHome = getenv( 'MW_HOME' );

if ( !defined( 'MW_CONFIG_FILE' ) && !file_exists( "$mwHome/LocalSettings.php" ) ) {
	define( 'MW_CONFIG_FILE', "$mwHome/DockerSettings.php" );
}

require_once "$mwHome/maintenance/Maintenance.php";

class GetMediawikiSettings extends Maintenance {

	public function __construct() {
		parent::__construct();
		$this->addOption(
			'variable',
			'',
			false,
			true
		);
		$this->addOption(
			'config',
			'',
			false,
			true
		);
		$this->addOption(
			'format',
			'',
			false,
			true
		);
	}

	public function execute() {
	#	$this->output( "######\n" . var_export( $GLOBALS, true ) );

		$return = null;
		if ( $this->hasOption( 'config' ) ) {
			$configName = $this->getOption( 'config' );
			$config = MediaWikiServices::getInstance()->getMainConfig();
			if ( $config->has( $configName ) ) {
				$return = $config->get( $configName );
			} // TODO else error message?
		} elseif ( $this->hasOption( 'variable' ) ) {
			$variableName = $this->getOption( 'variable' );
			$return = $GLOBALS[$variableName] ?? '';
		}

		$format = $this->getOption( 'format', 'string' );
		if ( strcasecmp( $format, 'json' ) === 0 ) {
			$this->output( FormatJson::encode( $return ) );
		} elseif ( $format === 'first' ) {
			if ( is_array( $return ) && $return ) {
				$return = array_values($return)[0];
			}
			$this->output( $return );
		} else { // string
			$this->output( $return );
		}
	}

	public function getDbType() {
		return Maintenance::DB_NONE;
	}

	public function finalSetup() {
		global $wgShowExceptionDetails, $wgHooks;

		$wgShowExceptionDetails = true;
		$wgHooks['SetupAfterCache'][] = function () {
			global $wgExtensionFunctions;
			$wgExtensionFunctions = [];
		};
	}
}

$maintClass = GetMediawikiSettings::class;
require RUN_MAINTENANCE_IF_MAIN;
