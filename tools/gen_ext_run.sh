#!/bin/bash

# Generates list of Docker RUN commands to clone the list of extensions
# and checkout to the giving branch tip commits

BRANCH=$1

if [[ -z "$BRANCH" ]]; then
  echo "Please specify branch name as first param!"
  echo ""
  exit 1
fi

Extensions=(
    AdminLinks
    ContributionScores
    ExternalData
    DismissableSiteNotice
    MobileFrontend
    RevisionSlider
    SandboxLink
    OpenIDConnect
    PluggableAuth
    WhoIsWatching
    LabeledSectionTransclusion
    GlobalNotice
    FixedHeaderTable
    Lingo
    OpenGraphMeta
    NumerAlpha
	"DataTransfer"
	"Variables"
	"Loops"
	"MyVariables"
	"Arrays"
	"DisplayTitle"
	"ConfirmAccount"
	"Lockdown"
	"Math"
	"Echo"
	"ChangeAuthor"
	"ContactPage"
	"IframePage"
	"MsUpload"
	"SelectCategory"
	"ShowMe"
	"SoundManager2Button"
	"CirrusSearch"
	"Elastica"
	"googleAnalytics"
	"UniversalLanguageSelector"
	"Survey"
	"LiquidThreads"
	"CodeMirror"
	"Flow"
	"ApprovedRevs"
	"Collection"
	"HTMLTags"
	"BetaFeatures"
	"SkinPerNamespace"
	"SkinPerPage"
	"CharInsert"
	"Tabs"
	"AdvancedSearch"
	"Disambiguator"
	"CheckUser"
	"CommonsMetadata"
	"TimedMediaHandler"
	"SocialProfile"
	"WikiForum"
	"VoteNY"
	"AJAXPoll"
	"YouTube"
	"AntiSpoof"
	"Popups"
	"Description2"
	"Thanks"
	"MobileDetect"
	"SimpleChanges"
	"UserMerge"
	"LinkSuggest"
	"TwitterTag"
	"TemplateStyles"
	"LookupUser"
	"HeadScript"
	"GoogleDocTag"
	EditAccount
	"EventLogging"
	"EventStreamConfig"
	"SaveSpinner"
	"UploadWizard"
	"CommentStreams"
	"GoogleAnalyticsMetrics"
	"MassMessage"
	"MassMessageEmail"
	"SemanticDrilldown"
	"VEForAll"
	"HeaderTabs"
	"UrlGetParameters"
	"TinyMCE"
	"RandomInCategory"
)

echo "RUN set -x; \\"
echo "	cd \$MW_HOME/extensions \\"

for EXT in ${Extensions[*]}; do
  SHA=$(./get_ext_sha.sh $EXT $BRANCH)
  if [ $? -eq 1 ]; then
    echo "  SHA not found :("
    exit 1
    #continue
  fi
  echo "	# $EXT"
  echo "	&& git clone --single-branch -b \$MW_VERSION https://gerrit.wikimedia.org/r/mediawiki/extensions/$EXT \$MW_HOME/extensions/$EXT \\"
  echo "	&& cd \$MW_HOME/extensions/$EXT \\"
  echo "	&& git checkout -q $SHA \\"
done
