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

optimizePNG()
{
	declare -a pngFiles
	# pngFiles=$(fd png) or pngFiles=`fd png` were not working as they were adding the files as a block of text.
	if ls *.png &> /dev/null ; then
		for file in *.png
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

optimizeJPEG()
{
	declare -a jpgFiles
	if ls *.jpg &> /dev/null ; then
		for file in *.jpg
		do
	    	jpgFiles=("${jpgFiles[@]}" "$file")
		done
		
		# Processing the files
		declare -i counter
		counter=0
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
	fi

	printf 'Moz-optimize:
		1) PNGs only
		2) JPEGs only
		3) Both PNG & JPEGs
		4) Exit
		  
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
	        optimizeJPEG
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
	    4)
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