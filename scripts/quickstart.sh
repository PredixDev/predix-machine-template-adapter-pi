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
arguments="$*"
echo "Arguments $arguments"
echo "$CURRENT_DIR"
rm -rf predix-scripts
rm -rf predix-machine-templates


__echo_run git clone https://github.com/PredixDev/predix-scripts.git  

__print_center "Creating Cloud Services" "#"
cd predix-scripts/bash
source readargs.sh
source scripts/files_helper_funcs.sh

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
__echo_run cp "$CURRENT_DIR/config/start_container.sh" "$MACHINE_HOME/machine/bin/predix"

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

