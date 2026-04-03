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
shopt -s nocaseglob nullglob

RED='\033[91m'
ORANGE='\033[95m'
GREEN='\033[92m'
NC='\033[0m'

HELP() {
printf 'optiMOZe - encode PNG/JPEG files with MOZjpeg.
Originals saved as "moz.bak_<name>" by default.

Usage: optiMOZe [options]

OPTIONS:
    -h   --help                 Show help
    -rm  --auto-remove          Remove originals (with confirmation)
    -rmq --auto-remove-quietly  Remove originals silently

Copyright 2021, Deepankar Chakroborty, www.dchakro.com
Issues: https://github.com/dchakro/optiMOZe/issues
'
}

ABORT() {
    echo "mozcjpeg or mogrify not found. Aborting..."
    exit 1
}

# Run autoremove based on flag
handle_autoremove() {
    case "$1" in
        -rmq|--auto-remove-quietly) removeMozBackupsQuietly ;;
        -rm|--auto-remove)          removeMozBackups ;;
    esac
}

optimizePNG() {
    command -v mozcjpeg >/dev/null 2>&1 || ABORT
    local files=(*.png)
    [[ ${#files[@]} -eq 0 ]] && { echo "No PNG files found in $PWD"; return; }

    local counter=0
    for item in "${files[@]}"; do
        local outname="${item%.png}.jpg"
        mozcjpeg -quality 75 -quant-table 3 -progressive "${item}" >| "${outname}" && \
            mv "${item}" "moz.bak_${item}"
        ((counter++))
    done
    echo "${counter} PNG files optimized!"
}

optimizeTIFF() {
    command -v convert >/dev/null 2>&1 || { echo "convert not found. Aborting..."; exit 1; }
    # nocaseglob handles case; match both .tif and .tiff
    local files=(*.tif *.tiff)
    [[ ${#files[@]} -eq 0 ]] && { echo "No TIFF files found in $PWD"; return; }

    local counter=0
    for item in "${files[@]}"; do
        convert -quality 85 "${item}" "${item%.*}.jpg" && \
            mv "${item}" "moz.bak_${item}"
        ((counter++))
    done
    echo "${counter} TIFF files optimized!"
}

optimizeJPEG() {
    command -v mozcjpeg >/dev/null 2>&1 || ABORT
    local files=(*.jpg *.jpeg)
    [[ ${#files[@]} -eq 0 ]] && { echo "No JPG/JPEG files found in $PWD"; return; }

    local counter=0
    for item in "${files[@]}"; do
        mv "${item}" "moz.bak_${item}"
        mozcjpeg -quality 75 -quant-table 3 -progressive "moz.bak_${item}" >| "${item}"
        ((counter++))
    done
    echo "${counter} JPEG files optimized!"
}

mogrifyJPEG() {
    command -v mogrify >/dev/null 2>&1 || ABORT
    local files=(*.jpg *.jpeg)
    [[ ${#files[@]} -eq 0 ]] && { echo "No JPG/JPEG files found in $PWD"; return; }
    mogrify -resize 85% "${files[@]}"
    echo "${#files[@]} JPEG files resized."
}

mogrifyHEIC() {
    command -v mogrify >/dev/null 2>&1 || { echo >&2 "Error: mogrify not found."; exit 1; }
    command -v identify >/dev/null 2>&1 || { echo >&2 "Error: identify not found."; exit 1; }

    local files=(*.heic)
    [[ ${#files[@]} -eq 0 ]] && { echo "No HEIC files found in $PWD"; return; }

    echo "Checking and resizing HEIC files in $PWD..."
    for f in "${files[@]}"; do
        read -r width height < <(identify -format "%w %h" "$f" 2>/dev/null)
        if [[ -n "$width" && -n "$height" ]]; then
            if (( width >= 2000 || height >= 2000 )); then
                echo "Downsizing '$f' (${width}x${height})..."
                mogrify -resize 85% "$f"
            else
                echo "Skipping '$f' (${width}x${height}) — under 2000px."
            fi
        else
            echo "Could not get dimensions for '$f'. Skipping."
        fi
    done
}

JPEG_to_HEIC() {
    command -v magick >/dev/null 2>&1 || { echo "magick not found. Aborting..."; exit 1; }
    local files=(*.jpg *.jpeg)
    [[ ${#files[@]} -eq 0 ]] && { echo "No JPG/JPEG files found in $PWD"; return; }

    local counter=0
    for item in "${files[@]}"; do
        local outname="${item%.*}.heic"          # fix: was "${item}.heic"
        mv "${item}" "moz.bak_${item}"
        magick "moz.bak_${item}" "${outname}" &  # parallel: mozcjpeg is single-threaded
        ((counter++))
    done
    wait
    echo "${counter} JPEG files converted to HEIC."
}

PNG_to_HEIC() {
    command -v magick >/dev/null 2>&1 || { echo "magick not found. Aborting..."; exit 1; }
    local files=(*.png)
    [[ ${#files[@]} -eq 0 ]] && { echo "No PNG files found in $PWD"; return; }

    local counter=0
    for item in "${files[@]}"; do
        local outname="${item%.*}.heic"          # fix: was "${item}.heic"
        mv "${item}" "moz.bak_${item}"
        magick "moz.bak_${item}" "${outname}" &
        ((counter++))
    done
    wait
    echo "${counter} PNG files converted to HEIC."
}

removeMozBackups() {
    local baks=(moz.bak_*)
    [[ ${#baks[@]} -eq 0 ]] && return
    rm -i moz.bak_*
}

removeMozBackupsQuietly() {
    local baks=(moz.bak_*)
    [[ ${#baks[@]} -eq 0 ]] && return
    echo "Deleting:"
    printf '  %s\n' "${baks[@]}"
    rm moz.bak_*
}

# --- Main ---

case "$1" in
    -rmq|--auto-remove-quietly) echo -e "Autoremove: ${RED}ON${NC}" ;;
    -rm|--auto-remove)          echo -e "Autoremove: ${ORANGE}Ask${NC}" ;;
    --help|-h)                  HELP; exit 0 ;;
    "")                         echo -e "Autoremove: ${GREEN}OFF${NC}" ;;
esac

while true; do
    printf 'Moz-optimize:
    1) PNGs only
    2) JPEGs only
    3) TIFFs only
    4) PNG + JPEG + TIFF
    5) HEIC downsize (>=2000px → 85%%, overwrites)
    6) Resize JPEGs 85%% (overwrites)
    7) Convert JPEGs to HEIC
    8) Convert PNGs to HEIC
    9) Exit

    Enter: '
    read -r var
    case $var in
        1) optimizePNG;                          handle_autoremove "$1"; exit 0 ;;
        2) optimizeJPEG;                         handle_autoremove "$1"; exit 0 ;;
        3) optimizeTIFF;                         handle_autoremove "$1"; exit 0 ;;
        4) optimizeJPEG; optimizeTIFF; optimizePNG; handle_autoremove "$1"; exit 0 ;;
        5) mogrifyHEIC;                          exit 0 ;;
        6) mogrifyJPEG;                          exit 0 ;;
        7) JPEG_to_HEIC;             			 handle_autoremove "$1"; exit 0 ;;
        8) PNG_to_HEIC;                      	 handle_autoremove "$1"; exit 0 ;;
        9) echo "Bye!"; exit 0 ;;
        *) echo -e "\n${RED}Wrong input.${NC} Valid range [${GREEN}1-9${NC}].\n"; sleep 0.5 ;;
    esac
done