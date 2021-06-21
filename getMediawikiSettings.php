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
			'format',
			'',
			false,
			true
		);
	}

	public function execute() {
		$return = null;
		if ( $this->hasOption( 'variable' ) ) {
			$variableName = $this->getOption( 'variable' );
			$config = MediaWikiServices::getInstance()->getMainConfig();
			if ( $config->has( $variableName ) ) {
				$return = $config->get( $variableName );
			} else { // the last chance to fetch a value from global variable
				$return = $GLOBALS[$variableName] ?? '';
			}
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

	/**
	 * Remove values from the SetupAfterCache hooks at last-minute setup because
	 * some extensions makes requests to the database using the SetupAfterCache hook
	 * (for example they can check user and etc..)
	 * but this script can be used for getting parameters when database is not initialized yet
	 */
	public function finalSetup() {
		parent::finalSetup();

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
