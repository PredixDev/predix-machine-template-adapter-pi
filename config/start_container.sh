#!/bin/sh
# Arguments = -p password

# Copyright (c) 2012-2016 General Electric Company. All rights reserved.
# The copyright to the computer software herein is the property of
# General Electric Company. The software may be used and/or copied only
# with the written permission of General Electric Company or in accordance
# with the terms and conditions stipulated in the agreement/contract
# under which the software has been supplied
usage()
{
cat << EOF
usage: $0 options

Start script for predix machine

OPTIONS:
   -p      password for the newly generated keystore password and key passwords
   -h      usage information
   clean   clear the storage
   debug   start debug listener for attaching from IDE on port 8000.
   debug dbg_port 8000 dbg_suspend - attach for debugging but do not start the container until debugger is attached. This allows for debugging activate. 
EOF
}

P_FLAG=false

while getopts "p:" OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         p)
             P_FLAG=true
             KEYPASS=$OPTARG
             if [ "$KEYPASS" = "clean" ] || [ "$KEYPASS" = "dbg_suspend" ] || [ "$KEYPASS" = "debug" ] || [ "$KEYPASS" = "dbg_port" ] || [ "$KEYPASS" = "-h" ] || [ "$KEYPASS" = "-p" ]; then
                 usage
                 exit 1
             fi
             ;;
         ?)
             usage
             exit 1
             ;;
     esac
done

# Exit if keytool is not installed.
command -v keytool >/dev/null 2>&1 || { echo >&2 "Java keytool not found.  Exiting."; exit 1; }

DIRNAME=`dirname "$0"`
ORIGIN=`pwd`
PREDIX_MACHINE_HOME=`cd "$DIRNAME/../../.."; pwd`
INI_FILES="$PREDIX_MACHINE_HOME/machine/bin/vms"

# Generate the full path for "predix.home.dir" system define for permission. This can not be passed in VM_ARGS.
echo "predix.home.dir=${PREDIX_MACHINE_HOME}" > "$DIRNAME/predix.home.prs"


##########################################################################################
# framework extension and property setup
##########################################################################################
EXTPRS="../../../../configuration/machine/predix.prs;../../predix/predix.home.prs;./machine.prs"
MBS_SERVER_JAR="../../../lib/framework/com.prosyst.util.log.buffer.jar"
VM_ARGS="-Dmbs.log.custom=com.prosyst.util.log.buffer.BufferedLogger -Dmbs.log.useEventThread=false -Dmbs.log.file.entriesThreshold=0 -Djava.security.egd=file:///dev/urandom -Dorg.osgi.framework.bootdelegation=org.iot.raspberry.*"
# turn on java security permissions in ../machine/bin/vms/policy.all. Comment out the line to turn it off.
#FWSECURITY=on

# Add javax.servlet-api if it exists.
if [ -e "$PREDIX_MACHINE_HOME/machine/bundles/javax.servlet-api-3.1.0.jar" ]; then 
    EXTRA_CP="../../bundles/javax.servlet-api-3.1.0.jar"
fi

# Add websocket-api if it exists to the classpath since they are needed for websockets.
if [ -e "$PREDIX_MACHINE_HOME/machine/bundles/javax.websocket-api-1.0.jar" ]; then 
    EXTRA_CP="$EXTRA_CP:../../bundles/javax.websocket-api-1.0.jar"
fi

if [ -e "$PREDIX_MACHINE_HOME/machine/bundles/bcpkix-jdk15on-1.52.jar" ]; then
    EXTRA_CP="$EXTRA_CP:../../bundles/bcpkix-jdk15on-1.52.jar"
fi

if [ -e "$PREDIX_MACHINE_HOME/machine/bundles/bcprov-jdk15on-1.52.jar" ]; then
    EXTRA_CP="$EXTRA_CP:../../bundles/bcprov-jdk15on-1.52.jar"
fi
 
# Add RXTX libraries for Modbus serial communication
if [ -e "$PREDIX_MACHINE_HOME/machine/lib/rxtx/rxtx-2.2pre2-bins/RXTXcomm.jar" ]; then
    EXTRA_CP="$EXTRA_CP:../../../lib/rxtx/rxtx-2.2pre2-bins/RXTXcomm.jar"
    if [ `uname` = "Darwin" ]; then
       	if [ -z "$RXTX_LIBRARY_PATH" ]; then 
            RXTX_LIBRARY_PATH="$PREDIX_MACHINE_HOME/machine/lib/rxtx/rxtx-2.2pre2-bins/mac-10.5";
        fi
        DYLD_LIBRARY_PATH=${RXTX_LIBRARY_PATH}:${DYLD_LIBRARY_PATH}
        export DYLD_LIBRARY_PATH
    else
       	if [ -z "$RXTX_LIBRARY_PATH" ]; then 
            RXTX_LIBRARY_PATH="$PREDIX_MACHINE_HOME/machine/lib/rxtx/rxtx-2.2pre2-bins/x86_64-unknown-linux-gnu";
       	fi
        LD_LIBRARY_PATH=${RXTX_LIBRARY_PATH}:${LD_LIBRARY_PATH}
        export LD_LIBRARY_PATH
    fi
fi

export EXTPRS
export MBS_SERVER_JAR
export VM_ARGS
export FWSECURITY
export EXTRA_CP
export LD_LIBRARY_PATH

##########################################################################################
# Boot feature (*.ini files) file setup.
##########################################################################################

FEATURE_INI="provision.ini messaging.ini machinegateway.ini websocket.ini solution.ini"
for inifile in ${FEATURE_INI}
do
    # If a the ".ini" file exists in the machine/bin/vms directory
    CHECK_FILE="$INI_FILES/$inifile"
    if [ -e "$CHECK_FILE" ]; then
        EXTBOOTFILE="$EXTBOOTFILE;../$inifile"
    fi
done

# Check if Technician console should be loaded. This is can also be based on a property enabled.
CHECK_FILE="$INI_FILES/webconsole.ini"
if [ -e "$CHECK_FILE" ]; then
    CHECK_FILE="$PREDIX_MACHINE_HOME/configuration/machine/com.ge.dspmicro.device.techconsole.config"
    if [ -e "$CHECK_FILE" ]; then
        if grep -iq "com.ge.dspmicro.device.techconsole.console.enabled=B\"true\"" "$PREDIX_MACHINE_HOME/configuration/machine/com.ge.dspmicro.device.techconsole.config"; then
            echo "Technician console enabled."
            EXTBOOTFILE="$EXTBOOTFILE;../webconsole.ini"
        else
            echo "Technician console disabled."
        fi
    else
        EXTBOOTFILE="$EXTBOOTFILE;../webconsole.ini"
    fi
fi

export EXTBOOTFILE

##########################################################################################
# Setup the machine environment variables if it is used.
##########################################################################################
if [ -e "$DIRNAME/setvars.sh" ]; then 
    . "$DIRNAME/setvars.sh"; 
fi

cd "$PREDIX_MACHINE_HOME/machine/bin/vms/jdk/"

##########################################################################################
# Generate new keystores and keys if they does not exist
##########################################################################################

# Sets a property value in the provided config file
# Arguments:
#  $1 the full path to the property file
#  $2 the key of the property to replace
#  $3 the value of the property
set_property()
{
    if test `uname` = 'Darwin'; then
    	# Mac needs the blank backup specified. Linux issue warnings if specified.
		sed -i '' -e "s;\($2 *= *\).*;\1$3;g" "$1"
	else
		sed -i -e "s;\($2 *= *\).*;\1$3;g" "$1"
    fi
}

# Sets a property value in the provided config file
# Arguments:
#  $1 the relative path to the property file
#  $2 the key of the property to replace
#  $3 the value of the property
set_property_opc()
{
    if test `uname` = 'Darwin'; then
		sed -i '' -e "s;\($2 *= *\).*;\1$3;g" "$PREDIX_MACHINE_HOME"/$1
	else
		sed -i -e "s;\($2 *= *\).*;\1$3;g" "$PREDIX_MACHINE_HOME"/$1
    fi
}

# Generates a random password of custom length using /dev/urandom
# Arguments:
#  $1 the length of the password to generate
generate_password()
{
    KEYPASS=`head -n 1 /dev/urandom | LC_CTYPE=C tr -dc "a-zA-Z0-9-_+{}|:<>?" | head -n 1`
    LEN=$(echo ${#KEYPASS})                                                                     
    if [ $LEN -lt 6 ]; then                                                                          
        KEYPASS=`head -n 1 /dev/urandom | LC_CTYPE=C tr -dc "a-zA-Z0-9-_+{}|:<>?" | head -n 1`
    fi  
}

# Tests if a property is set in a property file
# Arguments:
#   $1 the path to the property file
#   $2 the property key
# Returns: sets $VALUE_IS_SET to true if value is not blank
#
check_prop_set()
{
    VALUE_IS_SET=false
    grep -E "^$2[\s]*=[\s]*[^\s]+" "$1" > /dev/null 2>&1
    if [ $? = 0 ]; then
        VALUE_IS_SET=true
    fi
}

TLS_CLIENT_KEYSTORE_PATH=security/tls_client_keystore.jks
TLS_CLIENT_KEYSTORE_PATH_PROP=com.ge.dspmicro.securityadmin.sslcontext.client.keystore.path
TLS_CLIENT_KEYSTORE_TYPE_PROP=com.ge.dspmicro.securityadmin.sslcontext.client.keystore.type
TLS_CLIENT_KEYSTORE_PW_PROP=com.ge.dspmicro.securityadmin.sslcontext.client.keystore.password
TLS_CLIENT_KEYSTORE_KEY_PW_PROP=com.ge.dspmicro.securityadmin.sslcontext.client.keymanager.password
TLS_CLIENT_KEYSTORE_KEY_ALIAS_PROP=com.ge.dspmicro.securityadmin.sslcontext.client.keymanager.alias

TLS_SERVER_KEYSTORE_PATH=security/tls_server_keystore.jks
TLS_SERVER_KEYSTORE_PATH_PROP=com.ge.dspmicro.securityadmin.sslcontext.server.keystore.path
TLS_SERVER_KEYSTORE_TYPE_PROP=com.ge.dspmicro.securityadmin.sslcontext.server.keystore.type
TLS_SERVER_KEYSTORE_PW_PROP=com.ge.dspmicro.securityadmin.sslcontext.server.keystore.password
TLS_SERVER_KEYSTORE_KEY_PW_PROP=com.ge.dspmicro.securityadmin.sslcontext.server.keymanager.password
TLS_SERVER_KEYSTORE_KEY_ALIAS_PROP=com.ge.dspmicro.securityadmin.sslcontext.server.keymanager.alias

if [ -e "$PREDIX_MACHINE_HOME/machine/bundles/com.ge.dspmicro.machineadapter-opcua-16.2.0.jar" ]; then
    OPCUA_KEYSTORE_PATH=security/opcua_keystore.jks
fi
if [ -e "$PREDIX_MACHINE_HOME/machine/bundles/com.ge.dspmicro.opcua-server-16.2.0.jar" ]; then
    OPCUA_SERVER_KEYSTORE_PATH=security/opcuaserver_keystore.jks
fi

MISC_KEYSTORE_PATH=security/misc_keystore.jks
MISC_KEYSTORE_PATH_PROP=com.ge.dspmicro.securityadmin.default.keystore.path
MISC_KEYSTORE_TYPE_PROP=com.ge.dspmicro.securityadmin.default.keystore.type
MISC_KEYSTORE_PW_PROP=com.ge.dspmicro.securityadmin.default.keystore.password
MISC_KEY_PW_PROP=com.ge.dspmicro.securityadmin.default.keystore.aliasPassword
MISC_ALIAS_PW_PROP=com.ge.dspmicro.securityadmin.default.keystore.alias

USER_STORE_PATH=security/users.store
SECRET_KEYSTORE_PATH=security/secretkey_keystore.jceks
SECRET_KEYSTORE_PATH_PROP=com.ge.dspmicro.securityadmin.encryption.keystore.path
SECRET_KEYSTORE_TYPE_PROP=com.ge.dspmicro.securityadmin.encryption.keystore.type
SECRET_KEYSTORE_PW_PROP=com.ge.dspmicro.securityadmin.encryption.keystore.password
SECRET_KEY_PW_PROP=com.ge.dspmicro.securityadmin.encryption.alias.password
SECRET_KEY_ALIAS_PROP=com.ge.dspmicro.securityadmin.encryption.alias

SECURITYADMIN_CFG_PATH="$PREDIX_MACHINE_HOME"/security/com.ge.dspmicro.securityadmin.cfg
SECURITY_CFG_PROP_PATH="$PREDIX_MACHINE_HOME"/security/securityConfig.properties

PASSWORD_LENGTH=20

# Setup keystore for TLS
check_prop_set "$SECURITYADMIN_CFG_PATH" $TLS_CLIENT_KEYSTORE_PATH_PROP
if [ "$VALUE_IS_SET" = false ]; then
    if [ -e "$PREDIX_MACHINE_HOME/$TLS_CLIENT_KEYSTORE_PATH" ]; then
        echo "Removing previous TLS client keystore, generating a new one. WARNING: This may take several minutes on small devices"
        rm -f "$PREDIX_MACHINE_HOME/$TLS_CLIENT_KEYSTORE_PATH"
    else
        echo "Default Client TLS keystore not found, generating a new one. WARNING: This may take several minutes on small devices"
    fi
    if ! $P_FLAG; then    
        generate_password $PASSWORD_LENGTH
    fi     
    keytool -genkey \
            -keystore "$PREDIX_MACHINE_HOME/$TLS_CLIENT_KEYSTORE_PATH" \
            -alias dspmicro \
            -storepass $KEYPASS \
            -keypass $KEYPASS \
            -keyalg RSA \
            -sigalg SHA256withRSA \
            -keysize 2048 \
            -storetype JKS \
            -validity 3650 \
            -dname "CN=localhost, OU=Predix, O=GE L=San Ramon, S=CA, C=US"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_CLIENT_KEYSTORE_PW_PROP" "$KEYPASS"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_CLIENT_KEYSTORE_KEY_PW_PROP" "$KEYPASS"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_CLIENT_KEYSTORE_PATH_PROP" "$TLS_CLIENT_KEYSTORE_PATH"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_CLIENT_KEYSTORE_TYPE_PROP" "JKS"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_CLIENT_KEYSTORE_KEY_ALIAS_PROP" "dspmicro"
fi

# Setup keystore for TLS
check_prop_set "$SECURITYADMIN_CFG_PATH" $TLS_SERVER_KEYSTORE_PATH_PROP
if [ "$VALUE_IS_SET" = false ]; then
    if [ -e "$PREDIX_MACHINE_HOME/$TLS_SERVER_KEYSTORE_PATH" ]; then
        echo "Removing previous TLS server keystore, generating a new one. WARNING: This may take several minutes on small devices"
        rm -f "$PREDIX_MACHINE_HOME/$TLS_SERVER_KEYSTORE_PATH"
    else
        echo "Default Server TLS keystore not found, generating a new one. WARNING: This may take several minutes on small devices"
    fi
    if ! $P_FLAG; then
        generate_password $PASSWORD_LENGTH
    fi     
    keytool -genkey \
            -keystore "$PREDIX_MACHINE_HOME/$TLS_SERVER_KEYSTORE_PATH" \
            -alias dspmicro \
            -storepass $KEYPASS \
            -keypass $KEYPASS \
            -keyalg RSA \
            -sigalg SHA256withRSA \
            -keysize 2048 \
            -storetype JKS \
            -validity 3650 \
            -dname "CN=localhost, OU=Predix, O=GE L=San Ramon, S=CA, C=US"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_SERVER_KEYSTORE_PW_PROP" "$KEYPASS"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_SERVER_KEYSTORE_KEY_PW_PROP" "$KEYPASS"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_SERVER_KEYSTORE_PATH_PROP" "$TLS_SERVER_KEYSTORE_PATH"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_SERVER_KEYSTORE_TYPE_PROP" "JKS"
    set_property "$SECURITYADMIN_CFG_PATH" "$TLS_SERVER_KEYSTORE_KEY_ALIAS_PROP" "dspmicro"
fi

# Setup keystore for application key storage
check_prop_set "$SECURITYADMIN_CFG_PATH" $MISC_KEYSTORE_PATH_PROP
if [ "$VALUE_IS_SET" = false ]; then
    if [ -e "$PREDIX_MACHINE_HOME/$MISC_KEYSTORE_PATH" ]; then
        echo "Removing previous Misc keystore, generating a new one. WARNING: This may take several minutes on small devices"
        rm -f "$PREDIX_MACHINE_HOME/$MISC_KEYSTORE_PATH"
    else
        echo "Default Misc keystore not found, generating a new one. WARNING: This may take several minutes on small devices"
    fi
    if ! $P_FLAG; then
        generate_password $PASSWORD_LENGTH
    fi     
    keytool -genkey \
            -keystore "$PREDIX_MACHINE_HOME/$MISC_KEYSTORE_PATH" \
            -alias dspmicro \
            -storepass $KEYPASS \
            -keypass $KEYPASS \
            -keyalg RSA \
            -sigalg SHA256withRSA \
            -keysize 2048 \
            -storetype JKS \
            -validity 3650 \
            -dname "CN=dspmicro, OU=Predix, O=GE L=San Ramon, S=CA, C=US"
    set_property "$SECURITYADMIN_CFG_PATH" "$MISC_KEYSTORE_PW_PROP" "$KEYPASS"
    set_property "$SECURITYADMIN_CFG_PATH" "$MISC_KEY_PW_PROP" "$KEYPASS"
    set_property "$SECURITYADMIN_CFG_PATH" "$MISC_KEYSTORE_PATH_PROP" "$MISC_KEYSTORE_PATH"
    set_property "$SECURITYADMIN_CFG_PATH" "$MISC_KEYSTORE_TYPE_PROP" "JKS"
    set_property "$SECURITYADMIN_CFG_PATH" "$MISC_ALIAS_PW_PROP" "dspmicro"
fi

# Setup keystore for OPC-UA key storage only if OPC-UA bundle is present
if [ -e "$PREDIX_MACHINE_HOME/machine/bundles/com.ge.dspmicro.machineadapter-opcua-16.2.0.jar" ]; then
    if [ ! -e "$PREDIX_MACHINE_HOME/$OPCUA_KEYSTORE_PATH" ]; then
        echo "Default OPC-UA keystore not found, generating a new one. WARNING: This may take several minutes on small devices"
        # We do no generate the password since it must be exported for use.
        if ! $P_FLAG; then
           KEYPASS='dspmicro'
        fi     
        keytool -genkey \
                -keystore "$PREDIX_MACHINE_HOME/$OPCUA_KEYSTORE_PATH" \
                -alias dspmicro \
                -storepass $KEYPASS \
                -keypass $KEYPASS \
                -keyalg RSA \
                -sigalg SHA256withRSA \
                -keysize 2048 \
                -storetype JKS \
                -validity 3650 \
                -dname "CN=dspmicro, OU=Predix, O=GE L=San Ramon, S=CA, C=US"
         # Set no properties as the defaults in the configuration files are these defaults. 
    fi
fi

# Setup keystore for OPC-UA Server key storage only if OPC-UA server bundle is present
if [ -e "$PREDIX_MACHINE_HOME/machine/bundles/com.ge.dspmicro.opcua-server-16.2.0.jar" ]; then
    if [ ! -e "$PREDIX_MACHINE_HOME/$OPCUA_SERVER_KEYSTORE_PATH" ]; then
        echo "Default OPC-UA Server keystore not found, generating a new one. WARNING: This may take several minutes on small devices"
        # We do no generate the password since it must be exported for use.
        if ! $P_FLAG; then
            KEYPASS='dspmicro'
        fi     
        keytool -genkey \
                -keystore "$PREDIX_MACHINE_HOME/$OPCUA_SERVER_KEYSTORE_PATH" \
                -alias dspmicro \
                -storepass $KEYPASS \
                -keypass $KEYPASS \
                -keyalg RSA \
                -sigalg SHA256withRSA \
                -keysize 2048 \
                -storetype JKS \
                -validity 3650 \
                -dname "CN=dspmicro, OU=Predix, O=GE L=San Ramon, S=CA, C=US"
         # Set no properties as the defaults in the configuration files are these defaults. 
    fi
fi

# Setup keystore for symmetric encryption 
check_prop_set "$SECURITYADMIN_CFG_PATH" $SECRET_KEYSTORE_PATH_PROP
if [ "$VALUE_IS_SET" = false ]; then
    if [ -e "$PREDIX_MACHINE_HOME/$SECRET_KEYSTORE_PATH" ]; then
        echo "Removing previous secret keystore, generating a new one. WARNING: This may take several minutes on small devices"
        rm -f "$PREDIX_MACHINE_HOME/$SECRET_KEYSTORE_PATH"
        echo "Removing previous users.store."
        rm -f "$PREDIX_MACHINE_HOME/$USER_STORE_PATH"
    else
        echo "Default secret keystore not found, generating a new one. WARNING: This may take several minutes on small devices"
    fi
    if ! $P_FLAG; then
        generate_password $PASSWORD_LENGTH
    fi 

    keytool -genseckey \
            -alias manglekey \
            -keyalg AES \
            -keysize 128 \
            -keystore "$PREDIX_MACHINE_HOME/$SECRET_KEYSTORE_PATH" \
            -storetype JCEKS \
            -storepass $KEYPASS \
            -keypass $KEYPASS
    set_property "$SECURITYADMIN_CFG_PATH" "$SECRET_KEYSTORE_PW_PROP" "$KEYPASS"
    set_property "$SECURITYADMIN_CFG_PATH" "$SECRET_KEY_PW_PROP" "$KEYPASS"
    set_property "$SECURITYADMIN_CFG_PATH" "$SECRET_KEYSTORE_PATH_PROP" "$SECRET_KEYSTORE_PATH"
    set_property "$SECURITYADMIN_CFG_PATH" "$SECRET_KEYSTORE_TYPE_PROP" "JCEKS"
    set_property "$SECURITYADMIN_CFG_PATH" "$SECRET_KEY_ALIAS_PROP" "manglekey"
fi
#erase value from KEYPASS
unset KEYPASS
#elif $P_FLAG; then
#    echo "\nNOTE: -p argument ignored since default keystore exists\n" 
#fi

##########################################################################################
# startup options:
#   clean - clear the storage
#   debug - start debug listener for attaching from IDE on port 8000.
#   debug dbg_port 8000 dbg_suspend - attach for debugging but don't start the container until debugger is attached. This allows for debugging activate. 
# 
# "$@" invokes server with the same arguments this script received
##########################################################################################

# Container must be started with clean each time. No data should be read from cache.
. ./server.sh clean "$@"

cd "$ORIGIN"