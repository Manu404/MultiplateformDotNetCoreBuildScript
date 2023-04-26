#!/bin/bash
# Default variables
currentDir="$PWD"
outputFolder="$currentDir/output/"
zipOutput="$outputFolder/zip/"
projectName="";
projectVersion="";
embeded=""
target=""
selectedPlateform=""

#
# COLORS
#
#https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
Green=$'\033[0;32m'        # Green
Yellow=$'\033[0;33m'       # Yellow
Color_Off=$'\033[0m'	   # Reset color
Purple=$'\033[0;35m'       # Purple
Cyan=$'\033[0;36m'         # Cyan
BPurple=$'\033[1;35m'      # Purple
BCyan=$'\033[1;36m'        # Cyan

headerColor=$Purple
subheaderColot=$Cyan
BheaderColor=$BPurple
BsubheaderColot=$BCyan

#
# REQUEST FOR PORTABLE OR MULTIFILE IF NOT MENTIONNED
#
function requesteEmbed() {
	if [ -z "${embeded}" ]
	then
		echo " > Portable or multifile ?"
		PS3="Your choice: "
		kind=("portable" "multi")
		select p in "${kind[@]}"; do
			case $p in
				"portable")
					embeded=true;
					break;
					;;
				"multi")
					embeded=false;
					break;
					;;
				*)
			esac
		done
	fi
}

#
# IF NO COMMAND PARAMETER GIVEN, ASK THE USE THE TARGET PLATEFORM IN THE OFFICIALLY SUPPORTED PLATEFORM
#
function selectPlateform() {
	if [ -z "$selectedPlateform" ]
	then
		if [ ! $target == 'all' ]
		then 
			echo " > Choose your plateform : "
			PS3="Your choice:" 
			plateform=("win-x64" "win-x86" "win-arm64" "linux-x64" "linux-arm" "linux-arm64")
			select p in "${plateform[@]}"; do
				case $p in
					"linux-x64")
						selectedPlateform=linux-x64
						break;
						;;
					"linux-arm64")
						selectedPlateform=linux-arm64
						break;
						;;
					"linux-arm")
						selectedPlateform=linux-arm
						break;
						;;
					"win-x64")
						selectedPlateform=win-x64
						break;
						;;
					"win-x86")
						selectedPlateform=win-x86
						break;
						;;
					"win-arm64")
						selectedPlateform=win-arm64
						break;
						;;
					*)
				esac
			done
		fi
	fi
}

function selectSingleOrAll() {
	if [ -z "${target}" ]
	then
		echo " > Build for a single or all plateforms ?"
		PS3="Your choice:" 
		plateform=("single" "all")
		select p in "${plateform[@]}"; do
			case $p in
				"single")
					target="single"
					break;
					;;
				"all")
					target="all"
					break;
					;;
				*)
			esac
		done
	fi
}


#
# BUILD ALL SUPPORTED TARGET PORTABLE AND SINGLE FILE
#
function buidForAll() {
	array=("win-x64" "win-x86" "win-arm64" "linux-x64" "linux-arm" "linux-arm64")
	echo "List of plateforme: ${array[*]}"
	for i in ${array[@]}
	do
		echo "Target platforme: '$i'"	
		selectedPlateform="$i"
		buildSingle
		pack
	done
	exit
}

#
# BUILD OF THE PROJECT
#

function buildSingle() {
	echo ""
	echo "$subheaderColot -----------------------------------"
	echo "$BsubheaderColot Building project for $selectedPlateform"
	echo "$subheaderColot -----------------------------------"
	echo ""
	echo "$Color_Off"

	if $embeded
	then
		buildFolder="$outputFolder/build/$selectedPlateform""_portable/"
	else
		buildFolder="$outputFolder/build/$selectedPlateform/"
	fi
	
	cleanup
	dotnet clean $project -r NET7_0  
	dotnet publish $project -c Release -r $selectedPlateform -p:PublishSingleFile=$embeded --self-contained True -o $buildFolder
	
	cd $buildFolder
}

#
# BUILD CROSSROADS
#
function build(){

	if [ $target = "all" ]
	then
	echo "all"
		buidForAll
	else
	echo "singl"
		buildSingle
		pack
	fi
}

function cleanup(){
	find . -iname "bin/Release" | xargs rm -rf
	find . -iname "obj" | xargs rm -rf
}

#
# PACKING OF THE BUILD OUTPUT
#
function pack() {
	echo ""
	echo "$subheaderColot -----------------------------------"
	echo "$BsubheaderColot Packing project"
	echo "$subheaderColot -----------------------------------"
	echo ""
	echo "$Color_Off"

	echo "Project Name: '$projectName'"
	echo "Project Version: '$projectVersion'"
	echo "PlateformName: $selectedPlateform"

	zipDestination="$zipOutput/$projectName"

	if [ ! -z projectVersion ]
	then
		zipDestination+="_"
	fi
	zipDestination+=$projectVersion;

	if [ ! -z projectVersion ] || [ ! -z projectName ]
	then
		zipDestination+="_"
	fi
	zipDestination+=$selectedPlateform;

	if $embeded
	then
		zipDestination+="_portable"
	fi

	zipDestination+=".zip"

	echo "Desitnation zip: $zipDestination"
	mkdir -p $zipOutput
	rm -rf zipDestination
	zip -r $zipDestination ./*
	cd -
}

#
# SCRIPT START
#
echo ""
echo "$headerColor -----------------------------------"
echo "$BheaderColor Settings up build"
echo "$headerColor -----------------------------------"
echo ""
echo "$Color_Off"

#
# PARSE COMMAND PARAMETER
#
VALID_ARGS=$(getopt -l all:target:projet:name:version: -o eap:t:n:v:  -- "$@")
if [[ $? -ne 0 ]]; then
	exit 1;
fi

eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
	-e)
		embeded=true
		echo "Produce single file assembly"
		shift 1
		;;
	-t | --target)
		selectedPlateform="$2"
		echo "Provided plateform is $2"
		shift 2
		;;
	-p | --project)
		project="$2"
		echo "Provided project is $2"
		shift 2
		;;
	-n | --name)
		projectName="$2"
		echo "Provided projet name is $2"
		shift 2
		;;
	-v | --version)
		projectVersion="$2"
		echo "Provided verison is $2"
		shift 2
		;;
	-a | --all)
		target="all"
		echo "Build all plateform"
		break 
		;;
	--) shift; 
		break 
		;;
  esac
done

cleanup
requesteEmbed
selectSingleOrAll
selectPlateform
build
cleanup