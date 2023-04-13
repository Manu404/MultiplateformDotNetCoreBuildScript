#!/bin/bash

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

echo ""
echo "$headerColor -----------------------------------"
echo "$BheaderColor Settings up build"
echo "$headerColor -----------------------------------"
echo ""
echo "$Color_Off"

# Default variables
currentDir="$PWD"
outputFolder="$currentDir/output/"
selectedPlateform=""
zipOutput="$outputFolder/zip/"
projectName="";
projectVersion="";
embeded=false

#
# PARSE COMMAND PARAMETER
#
VALID_ARGS=$(getopt -l target:projet:name:version: -o ep:t:n:v:  -- "$@")
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
    --) shift; 
        break 
        ;;
  esac
done

#
# IF NO COMMAND PARAMETER GIVEN, ASK THE USE THE TARGET PLATEFORM IN THE OFFICIALLY SUPPORTED PLATEFORM
#
if [ -z "${selectedPlateform}" ]
then
	echo "Choose your plateform"
	PS3=Your choice: 
	plateform=("linux-x64" "win-x64" "linux-arm64" "linux-arm")
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
			*)
		esac
	done
fi

#
# BUILD OF THE PROJECT
#
echo ""
echo "$subheaderColot -----------------------------------"
echo "$BsubheaderColot Building project for $selectedPlateform"
echo "$subheaderColot -----------------------------------"
echo ""
echo "$Color_Off"

if $embeded
then
	echo "embed"
	buildFolder="$outputFolder/build/$selectedPlateform""_portable/"
else
	echo "normal"
	buildFolder="$outputFolder/build/$selectedPlateform/"
fi

#rm-rf $project"/obj"
dotnet clean $project -r $selectedPlateform
dotnet publish $project -c Release -r $selectedPlateform -p:PublishSingleFile=$embeded --self-contained True -o $buildFolder


#
# PACKING OF THE BUILD OUTPUT
#
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
cd $buildFolder
mkdir -p $zipOutput
zip -r $zipDestination ./*
cd -