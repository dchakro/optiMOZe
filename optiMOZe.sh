#!/usr/bin/env bash

###########
# Shell script to compress PNG and JPEG files with mozjpeg
# author: Deepankar Chakroborty
# https://dchakro.com
# Leave feedback: https://github.com/dchakro
#
# Software provided as is without warranty.
# While running with the switches -rmq or --auto-remove-quietly ensure 
# you really do not need the original files.
###########

# Define colors
RED='\033[91m'
ORANGE='\033[95m'
GREEN='\033[92m'
NC='\033[0m'

## Function definitions:

HELP()
{
printf 'optiMOZe - allows you to use encode your PNG and JPEG files with MOZjpeg: an improved JPEG encoder.
By default optiMOZe saves the originals as "moz.bak.<original name>" in the same folder.
This behavior can be changed by using the following options to remove the orignal files.

Usage:
   optiMOZe [options]

OPTIONS:     
    -h   --help                 Show help (this text)
    -rm  --auto-remove          Remove original files (ask user to confirm)
    -rmq --auto-remove-quietly  Remove the original files without asking for 
                                confirmation

Copyright 2021, Deepankar Chakroborty, www.dchakro.com
Report issues: https://github.com/dchakro/optiMOZe/issues
';
  
}

ABORT()
{
	echo "mozcjpeg not found. Aborting..."
	exit 1
}

optimizePNG()
{ 
	command -v mozcjpeg >/dev/null 2>&1 || ABORT
	declare -a pngFiles
	# pngFiles=$(fd png) or pngFiles=`fd png` were not working as they were adding the files as a block of text.
	if ls | grep -Ei "png$" &> /dev/null ; then
		for file in *.png *.PNG
		do
	    	pngFiles=("${pngFiles[@]}" "$file")
		done
		
		# Processing the files
		declare -i counter
		counter=0
		for item in "${pngFiles[@]}"
		do 
			outname=$(echo "${item}" | sd "png" "jpg")
			mozcjpeg -quality 75 -quant-table 3 -progressive "${item}" >| "${outname}"
			mv "${item}" "moz.bak_${item}"
			counter=($counter+1)
		done
		echo "${counter} PNG files optimized!"
	else
		echo "No PNG files found in $(PWD)"
	fi
}

optimizeTIFF()
{ 
	command -v mozcjpeg >/dev/null 2>&1 || ABORT
	declare -a tifFiles
	# tifFiles=$(fd png) or tifFiles=`fd png` were not working as they were adding the files as a block of text.
	if ls | grep -Ei "tif[f]*$" &> /dev/null ; then
		# Loop through all files in current directory
		for file in * 
		do
		    # Convert filename to lowercase
		    lowercase_file=$(echo "$file" | tr '[:upper:]' '[:lower:]')

		    # Check if filename ends with .tif or .tiff
		    if [[ "$lowercase_file" == *.tif ]] || [[ "$lowercase_file" == *.tiff ]]
		    then
		        tifFiles=("${tifFiles[@]}" "$file")
		    fi
		done
		
		# Processing the files
		declare -i counter
		counter=0
		for item in "${tifFiles[@]}"
		do 
			# outname=$(echo "${item}" | sd "tif[f]*" "jpg")
			# mozcjpeg -quality 75 -quant-table 3 -progressive "${item}" >| "${outname}"
			convert -quality 85 "${item}" "${file%.*}.jpg"
			mv "${item}" "moz.bak_${item}"
			counter=($counter+1)
		done
		echo "${counter} TIFF files optimized!"
	else
		echo "No TIFF files found in $(PWD)"
	fi
}

optimizeJPEG()
{
	command -v mozcjpeg >/dev/null 2>&1 || ABORT
	declare -a jpgFiles
	declare -i counter
	counter=0
	if ls | grep -Ei "jpg$" &> /dev/null ; then
		for file in *.jpg *.jpeg *.JPEG *.JPG
		do
	    	jpgFiles=("${jpgFiles[@]}" "$file")
		done
		
		# Processing the files
		for item in "${jpgFiles[@]}"
		do 
			mv "${item}" "moz.bak_${item}"
			mozcjpeg -quality 75 -quant-table 3 -progressive "moz.bak_${item}" >| "${item}"
			counter=($counter+1)
		done
		echo "${counter} JPG files optimized!"
	else
		echo "No JPG files found in $(PWD)"
	fi
	jpgFiles=()
	counter=0
	if ls | grep -Ei "jpeg$" &> /dev/null ; then
		for file in *.jpeg
		do
	    	jpgFiles=("${jpgFiles[@]}" "$file")
		done
		
		# Processing the files
		
		for item in "${jpgFiles[@]}"
		do 
			mv "${item}" "moz.bak_${item}"
			mozcjpeg -quality 75 -quant-table 3 -progressive "moz.bak_${item}" >| "${item}"
			counter=($counter+1)
		done
		echo "${counter} JPEG files optimized!"
	else
		echo "No JPEG files found in $(PWD)"
	fi
}

removeMozBackups()
{
	# ls moz.bak_*
	if ls moz.bak_* &> /dev/null ; then
		rm -i moz.bak_*
	fi
}

removeMozBackupsQuietly()
{
	if ls moz.bak_* &> /dev/null ; then
		echo "These files have been deleted:"
		ls moz.bak_*
		rm moz.bak_*
	fi
}



while true
do
	if [ "$#" -eq 0 ]; then
		echo -e "Autoremove: ${GREEN}OFF${NC}"
	elif [ "$1" == "-rmq" ]; then
		echo -e "Autoremove: ${RED}ON${NC}"
	elif [ "$1" == "--auto-remove-quietly" ]; then
		echo -e "Autoremove: ${RED}ON${NC}"
	elif [ "$1" == "-rm" ]; then
		echo -e "Autoremove: ${ORANGE}Ask${NC}"
	elif [ "$1" == "--auto-remove" ]; then
		echo -e "Autoremove: ${ORANGE}Ask${NC}"
	elif [ "$1" == "--help" ]; then
		HELP
		exit 0
	elif [ "$1" == "-h" ]; then
		HELP
		exit 0
	fi

	printf 'Moz-optimize:
		1) PNGs only
		2) JPEGs only
		3) TIFFs only
		4) All files
		5) Exit
		  
		Enter: ';
	read var;
	case $var in
	    1)  
	        optimizePNG
	        if [ "$1" == "-rmq" ]; then
				removeMozBackupsQuietly
			elif [ "$1" == "--auto-remove-quietly" ]; then
				removeMozBackupsQuietly
			elif [ "$1" == "-rm" ]; then
				removeMozBackups
			elif [ "$1" == "--auto-remove" ]; then
				removeMozBackups
			fi
	        exit 0
	        ;;
	   2) 
	        optimizeJPEG
	        if [ "$1" == "-rmq" ]; then
				removeMozBackupsQuietly
			elif [ "$1" == "--auto-remove-quietly" ]; then
				removeMozBackupsQuietly
			elif [ "$1" == "-rm" ]; then
				removeMozBackups
			elif [ "$1" == "--auto-remove" ]; then
				removeMozBackups
			fi
	        exit 0
	        ;;
	   3) 
		        optimizeTIFF
		        if [ "$1" == "-rmq" ]; then
					removeMozBackupsQuietly
				elif [ "$1" == "--auto-remove-quietly" ]; then
					removeMozBackupsQuietly
				elif [ "$1" == "-rm" ]; then
					removeMozBackups
				elif [ "$1" == "--auto-remove" ]; then
					removeMozBackups
				fi
		        exit 0
		        ;;
		4)
	        optimizeJPEG
			optimizeTIFF
	        optimizePNG
	        if [ "$1" == "-rmq" ]; then
				removeMozBackupsQuietly
			elif [ "$1" == "--auto-remove-quietly" ]; then
				removeMozBackupsQuietly
			elif [ "$1" == "-rm" ]; then
				removeMozBackups
			elif [ "$1" == "--auto-remove" ]; then
				removeMozBackups
			fi
	        exit 0
	        ;;
	    5)
	        echo "Bye!"
	        exit 0
	        ;;
	    *)
	        echo
	        echo -e "${RED}Wrong input.${NC} Valid range of choices [${GREEN}1-4${NC}]."
	        echo "Try again..."
	        echo
	        sleep 0.5
	        continue
	esac
done