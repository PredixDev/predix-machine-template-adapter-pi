dir=`pwd`
export PREDIX_MACHINE_HOME=/home/root/predixmachine16.1.0
cd $PREDIX_MACHINE_HOME/machine/bin/predix
nohup ./predixmachine clean > $PREDIX_MACHINE_HOME/logs/machine/machine.log 2> $PREDIX_MACHINE_HOME/logs/machine/machine.err < /dev/null &
cd $dir