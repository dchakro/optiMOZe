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

# Enable case-insensitive globbing
shopt -s nocaseglob

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
	echo "mozcjpeg or mogrify not found. Aborting..."
	exit 1
}

optimizePNG()
{ 
	command -v mozcjpeg >/dev/null 2>&1 || ABORT
	declare -a pngFiles
	# pngFiles=$(fd png) or pngFiles=`fd png` were not working as they were adding the files as a block of text.
	if /bin/ls | grep -Ei "png$" &> /dev/null ; then
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

optimizeTIFF()
{ 
	command -v mozcjpeg >/dev/null 2>&1 || ABORT
	declare -a tifFiles
	# tifFiles=$(fd png) or tifFiles=`fd png` were not working as they were adding the files as a block of text.
	if /bin/ls | grep -Ei "tif[f]*$" &> /dev/null ; then
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
			convert -quality 85 "${item}" "${item%.*}.jpg"
			mv "${item}" "moz.bak_${item}"
			counter=($counter+1)
		done
		echo "${counter} TIFF files optimized!"
	else
		echo "No TIFF files found in $(PWD)"
	fi
}

mogrifyJPEG()
{
	command -v mogrify >/dev/null 2>&1 || ABORT
	declare -a jpgFiles
	declare -i counter
	counter=0
	if /bin/ls | grep -Ei "jpg$" &> /dev/null ; then
		mogrify -resize 85% *.jpg
	else
		echo "No JPG files found in $(PWD)"
	fi
	if /bin/ls | grep -Ei "jpeg$" &> /dev/null ; then
		mogrify -resize 85% *.jpeg
	else
		echo "No JPEG files found in $(PWD)"
	fi
}

#mogrifyHEIC()
#{
#	command -v mogrify >/dev/null 2>&1 || ABORT
#	declare -a jpgFiles
#	declare -i counter
#	counter=0
#	if /bin/ls | grep -Ei "heic$" &> /dev/null ; then
#		mogrify -resize 70% *.heic
#	else
#		echo "No HEIC files found in $(PWD)"
#	fi
#	if /bin/ls | grep -Ei "HEIC$" &> /dev/null ; then
#		mogrify -resize 70% *.HEIC
#	else
#		echo "No JPEG files found in $(PWD)"
#	fi
#}

mogrifyHEIC() # Written by Gemini 2.5 Flash
{
    # Check if mogrify and identify commands exist
    command -v mogrify >/dev/null 2>&1 || { echo >&2 "Error: mogrify not found. Please install ImageMagick."; exit 1; }
    command -v identify >/dev/null 2>&1 || { echo >&2 "Error: identify not found. Please install ImageMagick."; exit 1; }

    local heic_files=()
    # Find all HEIC files (case-insensitive) and store them in an array
    while IFS= read -r -d $'\0'; do
        heic_files+=("$REPLY")
    done < <(find . -maxdepth 1 -iname "*.heic" -print0)

    if [ ${#heic_files[@]} -eq 0 ]; then
        echo "No HEIC files found in $(PWD)"
        return 0
    fi

    echo "Checking and resizing HEIC files in $(PWD)..."

    for heic_file in "${heic_files[@]}"; do
        # Get image width and height using identify
        # The format specifiers %w for width and %h for height are used
        read -r width height < <(identify -format "%w %h" "$heic_file" 2>/dev/null)

        # Check if identify successfully retrieved dimensions and if resolution is >= 2000 in either dimension
        if [[ -n "$width" && -n "$height" ]]; then
            if (( width >= 2000 || height >= 2000 )); then
                echo "Downsizing '$heic_file' (${width}x${height})..."
                mogrify -resize 85% "$heic_file"
            else
                echo "Skipping '$heic_file' (${width}x${height}) - resolution is less than 2000px."
            fi
        else
            echo "Could not get dimensions for '$heic_file' using identify. Skipping."
        fi
    done
}

optimizeJPEG()
{
	command -v mozcjpeg >/dev/null 2>&1 || ABORT
	declare -a jpgFiles
	declare -i counter
	counter=0
	if /bin/ls | grep -Ei "jpg$" &> /dev/null ; then
		for file in *.jpg
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
	if /bin/ls | grep -Ei "jpeg$" &> /dev/null ; then
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

JPEG_to_HEIC()
{
	command -v magick >/dev/null 2>&1 || ABORT
	declare -a jpgFiles
	declare -i counter
	counter=0
	if /bin/ls | grep -Ei "jpg$" &> /dev/null ; then
		for file in *.jpg
		do
	    	jpgFiles=("${jpgFiles[@]}" "$file")
		done
		
		# Processing the files
		for item in "${jpgFiles[@]}"
		do 
			mv "${item}" "moz.bak_${item}"
			magick "moz.bak_${item}" "${item}.heic"
			counter=($counter+1)
		done
		echo "${counter} JPG files optimized!"
	else
		echo "No JPG files found in $(PWD)"
	fi
	jpgFiles=()
	counter=0
	if /bin/ls | grep -Ei "jpeg$" &> /dev/null ; then
		for file in *.jpeg
		do
	    	jpgFiles=("${jpgFiles[@]}" "$file")
		done
		
		# Processing the files
		
		for item in "${jpgFiles[@]}"
		do 
			mv "${item}" "moz.bak_${item}"
			magick "moz.bak_${item}" "${item}.heic"
			counter=($counter+1)
		done
		echo "${counter} JPG files optimized!"
	else
		echo "No JPG files found in $(PWD)"
	fi
}

PNG_to_HEIC()
{
	command -v magick >/dev/null 2>&1 || ABORT
	declare -a jpgFiles
	declare -i counter
	counter=0
	if /bin/ls | grep -Ei "png$" &> /dev/null ; then
		for file in *.png
		do
	    	jpgFiles=("${jpgFiles[@]}" "$file")
		done
		
		# Processing the files
		for item in "${jpgFiles[@]}"
		do 
			mv "${item}" "moz.bak_${item}"
			magick "moz.bak_${item}" "${item}.heic"
			counter=($counter+1)
		done
		echo "${counter} JPG files optimized!"
	else
		echo "No PNG files found in $(PWD)"
	fi
}

removeMozBackups()
{
	# /bin/ls moz.bak_*
	if /bin/ls moz.bak_* &> /dev/null ; then
		rm -i moz.bak_*
	fi
}

removeMozBackupsQuietly()
{
	if /bin/ls moz.bak_* &> /dev/null ; then
		echo "These files have been deleted:"
		/bin/ls moz.bak_*
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
		4) Both PNG and JPG
		5) HEIC 70pct downsize (overwrites original)
		6) Resize JPEGs (overwrites original)
		7) Convert JPEGs to HEIC
		8) Convert PNGs to HEIC
		9) Exit
		  
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
	        mogrifyHEIC
	        exit 0
	        ;;
		6)
	        mogrifyJPEG
	        exit 0
	        ;;
		7)
			JPEG_to_HEIC
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
		8)
			PNG_to_HEIC
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
		9)
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