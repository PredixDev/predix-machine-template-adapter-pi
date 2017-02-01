#!/bin/bash
set -e
CURRENT_DIR="`pwd`"
quickstartLogDir="$CURRENT_DIR/log"
# Creating a logfile if it doesn't exist
if ! [ -d "$quickstartLogDir" ]; then
mkdir "$quickstartLogDir"
chmod 744 "$quickstartLogDir"
touch "$quickstartLogDir/quickstartlog.log"
fi
##################### Variables Section Start #####################
if [[ "${TERM/term}" = "$TERM" ]]; then
COLUMNS=50
else
COLUMNS=$(tput cols)
fi

MACHINE_HOME="$CURRENT_DIR/predix-scripts/bash/PredixMachine"
COMPILE_REPO=0

export COLUMNS
##################### Variables Section End   #####################

################Functions start #################

function __checkoutTags
{
	#Checkout the tag if provided by user
	if [[ ( "$1" != "") ]]; then
		git tag
		reponame=$(echo "$1" | awk -F "/" '{print $NF}')
		echo "$reponame"

		repo_version="$(echo "$a" | sed -n "/$reponame/p" $CURRENT_DIR/version.json | awk -F"\"" '{print $4}' | awk -F"#" '{print $NF}')"
		if [[ "$(git tag | grep "$repo_version" | head -n 1 | wc -l | awk '{$1=$1}{ print }')" == "1" ]]; then
	    git checkout tags/$repo_version
	  else
	    echo "No release tag version $repo_version found for $reponame"
	  fi
	fi
}

function getRepoURL {
	local  repoURLVar=$2
	reponame=$(echo "$1" | awk -F "/" '{print $NF}')
	url=$(echo "$a" | sed -n "/$reponame/p" $CURRENT_DIR/version.json | awk -F"\"" '{print $4}' | awk -F"#" '{print $1}')
	eval $repoURLVar="'$url'"
}
function getRepoVersion {
	local  repoVersionVar=$2
	reponame=$(echo "$1" | awk -F "/" '{print $NF}')
	repo_version="$(echo "$a" | sed -n "/$reponame/p" $CURRENT_DIR/version.json | awk -F"\"" '{print $4}' | awk -F"#" '{print $NF}')"
	eval $repoVersionVar="'$repo_version'"
}
__echo_run() {
  echo $@
  $@
  return $?
}

__print_center() {
  len=${#1}
  sep=$2
  buf=$((($COLUMNS-$len-2)/2))
  line=""
  for (( i=0; i < $buf; i++ )) {
  line="$line$sep"
  }
  line="$line $1 "
  for (( i=0; i < $buf; i++ )) {
    line="$line$sep"
  }
  echo ""
  echo $line
}

####### End of functions######################################
arguments="$*"
echo "Arguments $arguments"
echo "$CURRENT_DIR"

rm -rf predix-scripts
rm -rf predix-machine-templates

getRepoURL "predix-scripts" predix_scripts_url
getRepoVersion "predix-scripts" predix_scripts_version
__echo_run git clone "$predix_scripts_url" -b $predix_scripts_version
cd predix-scripts
__echo_run __checkoutTags "predix-scripts"

__print_center "Creating Cloud Services" "#"

cd $CURRENT_DIR/predix-scripts
source bash/readargs.sh
source bash/scripts/files_helper_funcs.sh
#if [[ ( "$RELEASE_TAG_VERSION" != "") ]]; then
	#git stash
	#__checkoutTags "predix-scripts" "$RELEASE_TAG_VERSION"
 #fi


cd $CURRENT_DIR/predix-scripts/bash

if type dos2unix >/dev/null; then
find . -name "*.sh" -exec dos2unix -q {} \;
fi

#Run the quickstart
if [[ $SKIP_SERVICES -eq 0 ]]; then
__echo_run ./quickstart.sh -cs -mc -if $arguments
else
__echo_run ./quickstart.sh -mc -p $arguments
fi

cd "$CURRENT_DIR"

__print_center "Build and setup the Predix Machine Adapter for Intel Device" "#"

__echo_run cp "$CURRENT_DIR/config/com.ge.predix.solsvc.workshop.adapter.config" "$MACHINE_HOME/configuration/machine"
__echo_run cp "$CURRENT_DIR/config/com.ge.predix.workshop.nodeconfig.json" "$MACHINE_HOME/configuration/machine"
__echo_run cp "$CURRENT_DIR/config/com.ge.dspmicro.hoover.spillway-0.config" "$MACHINE_HOME/configuration/machine"
#__echo_run cp "$CURRENT_DIR/config/start_container.sh" "$MACHINE_HOME/machine/bin/predix"

#Replace the :TAE tag with instance prepender
configFile="$MACHINE_HOME/configuration/machine/com.ge.predix.workshop.nodeconfig.json"
__find_and_replace ":TAE" ":$(echo $INSTANCE_PREPENDER | tr 'a-z' 'A-Z')" "$configFile" "$quickstartLogDir"

if [[ $RUN_COMPILE_REPO -eq 1 ]]; then
	./scripts/deployPiDependencies.sh	
fi

cd predix-scripts/bash
./scripts/buildMavenBundle.sh "$MACHINE_HOME"

cd $CURRENT_DIR

PREDIX_SERVICES_SUMMARY_FILE="$CURRENT_DIR/predix-scripts/bash/log/predix-services-summary.txt"

echo "" >> "$PREDIX_SERVICES_SUMMARY_FILE"
echo "Edge Device Specific Configuration" >> "$PREDIX_SERVICES_SUMMARY_FILE"
echo "What did we do:"  >> "$PREDIX_SERVICES_SUMMARY_FILE"
echo "We setup some configuration files in the Predix Machine container to read from a DataNode for our sensors"  >> "$PREDIX_SERVICES_SUMMARY_FILE"
echo "We installed some Raspberry PI API jar files that represent the Grove PI API" >> "$PREDIX_SERVICES_SUMMARY_FILE"
echo "We built and deployed the Machine Adapter bundle which reads from the Grove PI API" >> "$PREDIX_SERVICES_SUMMARY_FILE"
echo "" >> "$PREDIX_SERVICES_SUMMARY_FILE"

__print_center "Summary File available at $PREDIX_SERVICES_SUMMARY_FILE" "#"
cat $PREDIX_SERVICES_SUMMARY_FILE
__print_center "Success - the script is complete" "#"

