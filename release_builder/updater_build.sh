#!/bin/bash

##################################################################
# Useful Functions
##################################################################

function display_help {
cat << EOF

	SOGo Release builder script
	------------------------------------------------------------
	Please refer to ./release_builder.conf file

	Command line arguments:	
		-s|--site=SITEID	: Site ID
		-t|--skipthunderbird	: Skip thunderbird Download
		-h|--help		: Display this help
	
EOF
exit
}

function delete_dir {
	#Delete Dir only if exists
	if [ -d $1 ]; then
		rm -rf $1
	fi
}

function create_dir_and_cd {
	#Delete Dir only if exists
	if [ -d $1 ]; then
		rm -rf $1
	fi
	mkdir $1
	cd $1
}

function download_file {
if [ -f $1  ]; then
	return 0
fi
	echo -n "Downloading File $1..."	
	wget -nv -O $1 $2 > $LOG_FILE 2>&1
	if [ $? -eq 0 ]; then
		echo "[OK]"
		return 0
	else
		echo "[!!]"
		return 1
	fi
}


function pack_extension {
	echo "Packing extension ${EXTENSIONS_NAME[$1]}"

	if [ "${EXTENSIONS_URL_WIN[$1]}" != "" ]; then	
		download_file WINNT_x86-msvc/${EXTENSIONS_FILENAME[$1]} ${EXTENSIONS_URL_WIN[$1]}
	fi
	
	if [ "${EXTENSIONS_URL_LINUX32[$1]}" != "" ]; then
                download_file Linux_x86-gcc3/${EXTENSIONS_FILENAME[$1]} ${EXTENSIONS_URL_LINUX32[$1]}
        fi	

	if [ "${EXTENSIONS_URL_LINUX64[$1]}" != "" ]; then
                download_file Linux_x86_64-gcc3/${EXTENSIONS_FILENAME[$1]} ${EXTENSIONS_URL_LINUX64[$1]}
        fi	

	if [ "${EXTENSIONS_URL_MAC[$1]}" != "" ]; then
                download_file Darwin_x86-gcc3/${EXTENSIONS_FILENAME[$1]} ${EXTENSIONS_URL_MAC[$1]}
        fi	

        if [ "${EXTENSIONS_URL[$1]}" != "" ]; then
		download_file ${EXTENSIONS_FILENAME[$1]} ${EXTENSIONS_URL[$1]}
	fi

	cat << EOF >> ../extensions.pack
	 <li>
      	 	<Description
        	em:id="${EXTENSIONS_ID[$1]}"
        	em:name="${EXTENSIONS_NAME[$1]}"/>
    	 </li>		
EOF

	cat << EOF >> ../php_vars.pack
 	"${EXTENSIONS_ID[$1]}"
         => array( "application" => "thunderbird",
                   "version" => "${EXTENSIONS_VER[$1]}",
                   "filename" => "${EXTENSIONS_FILENAME[$1]}" ),
EOF

 }


##################################################################
# Init
##################################################################
RELEASE="default"
DL_THUNDERBIRD=1

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_PATH=$SCRIPT_PATH/build
LOG_FILE=$SCRIPT_PATH/build.log

##################################################################
# Argument Parsing
##################################################################

for i in "$@"
do
case $i in
    -e=*|--extensions=*)
    EXTENSIONS="${i#*=}"
    shift # past argument=value
    ;;
    -s=*|--site=*)
    RELEASE="${i#*=}"
    shift # past argument=value
    ;;
    -t|--skipthunderbird)
    DL_THUNDERBIRD=0
    echo "Thunderbird Download Disabled"
    shift # past argument=value
    ;;
    -h|--help)
    display_help
    shift # past argument with no value
    ;;
    *)
            # unknown option
    ;;
esac
done

##################################################################
# Config
##################################################################

echo "Building release $RELEASE"
source ./updater_build.conf
if [ -e "./extensions-$RELEASE.conf" ]; then
	source ./extensions-$RELEASE.conf
else
	source ./extensions.conf
fi
if [ "$RELEASE" != "default" ]; then
	SOGO_FRONTENDS_VERSION_APPEND=.$RELEASE$SOGO_FRONTENDS_VERSION_APPEND
	EXTENSIONS_VER[1]="${SOGO_FRONTENDS_VERSION}${SOGO_FRONTENDS_VERSION_APPEND}"
fi


echo "Release is ${RELEASE}, Version is: ${EXTENSIONS_VER[1]}"

echo "Script Path is" . $SCRIPT_PATH > $LOG_FILE


cd $SCRIPT_PATH

##################################################################
# Build
##################################################################

create_dir_and_cd build

create_dir_and_cd release
mkdir Darwin_x86-gcc3 Linux_x86-gcc3 Linux_x86_64-gcc3 WINNT_x86-msvc

echo "Preparing Extensions..."

for i in "${!EXTENSIONS_ID[@]}"
do
	pack_extension $i
done

if [ "$DL_THUNDERBIRD" == "1" ]; then
	echo "Downloading Thunderbird"
	download_file "thunderbird-${TB_VERSION}-setup.exe" $TB_URL
fi

cd $BUILD_PATH

echo "Packing SOGo Integrator..."

create_dir_and_cd sogo_integrator

unzip ../release/sogo-integrator-${SOGO_FRONTENDS_VERSION}.xpi > /dev/null
rm ../release/sogo-integrator-${SOGO_FRONTENDS_VERSION}.xpi

#Replace Values
sed -i "s|America/Montreal|$SOGO_DEFAULT_TIMEZONE|g" ./defaults/preferences/site.js
sed -i "s|public|$SOGO_USER_SOURCE|g" ./defaults/preferences/site.js

#echo $EXTENSIONS
SOGO_UPDATE_URL=$( echo "$SOGO_UPDATE_URL" | sed "s|default|$RELEASE|g" )
sed "s|SOGO_UPDATE_URL|$SOGO_UPDATE_URL|g" ../../extensions.rdf.tpl > ../extensions.rdf.work
sed -i -f ../../extensions.sed ../extensions.rdf.work
sed -i "s|$SOGO_FRONTENDS_VERSION|${SOGO_FRONTENDS_VERSION}${SOGO_FRONTENDS_VERSION_APPEND}|g" ./install.rdf


#Moving Files
cp -f ../extensions.rdf.work chrome/content/extensions.rdf

# Zipping
echo "Zipping Sogo-Integrator..."
zip -r ../sogo-integrator-${SOGO_FRONTENDS_VERSION}.xpi ./* > /dev/null

cp ../sogo-integrator-${SOGO_FRONTENDS_VERSION}.xpi ../release/

#Php Configuration
echo "Configuring PHP Script..."
cd $BUILD_PATH
sed '$ s/.$//' ./php_vars.pack > /dev/null
sed "s|TB_MIN_VERSION|$TB_MIN_VERSION|g" ../php_vars.tpl > ./php_vars.work
sed -i "s|TB_MAX_VERSION|$TB_MAX_VERSION|g" ./php_vars.work
sed -i "s|TB_VERSION|$TB_VERSION|g" ./php_vars.work
sed -i "s|SOGO_FE_VERSION|$SOGO_FRONTENDS_VERSION$|g" ./php_vars.work
sed -i -f ../php_vars.sed ./php_vars.work

cp ./php_vars.work ./release/updater_config.php

rm -rf $SCRIPT_PATH/../$RELEASE
cp -rf ./release $SCRIPT_PATH/../$RELEASE

cd $SCRIPT_PATH

echo "Done."
