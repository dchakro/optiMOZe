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

ENVIRONMENT:
    OPTIMOZE_HEIC_ENCODER       HEIC backend: auto (default), sips, magick
                                auto uses sips on macOS, magick elsewhere
    OPTIMOZE_MAX_JOBS             Max parallel HEIC jobs (default: min(ncpu, 4))

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


# Copy EXIF/XMP/GPS and filesystem dates from source to converted output.
# ImageMagick and sips do not reliably preserve metadata in HEIC; Photos uses these tags for import date.
require_exiftool() {
    command -v exiftool >/dev/null 2>&1 || {
        echo "exiftool not found. Required to preserve capture dates and other metadata."
        echo "Install with: brew install exiftool"
        exit 1
    }
}

copy_image_metadata() {
    local src="$1" dst="$2"
    shift 2
    command -v exiftool >/dev/null 2>&1 || return 1
    exiftool -overwrite_original -tagsFromFile "$src" -all:all "$dst" >/dev/null 2>&1 || return 1
    local sidecar
    for sidecar in "$@"; do
        [[ -f "$sidecar" ]] && exiftool -overwrite_original -tagsFromFile "$sidecar" -all:all "$dst" >/dev/null 2>&1
    done
    touch -r "$src" "$dst" 2>/dev/null
}

# HEIC backend: sips (macOS Media Engine) or magick (libheif/x265, cross-platform).
# OPTIMOZE_HEIC_ENCODER=auto|sips|magick
get_heic_encoder() {
    case "${OPTIMOZE_HEIC_ENCODER:-auto}" in
        sips)
            command -v sips >/dev/null 2>&1 || { echo "sips not found. Aborting..."; return 1; }
            echo sips
            ;;
        magick)
            command -v magick >/dev/null 2>&1 || { echo "magick not found. Aborting..."; return 1; }
            echo magick
            ;;
        auto)
            if [[ "$(uname -s)" == Darwin ]] && command -v sips >/dev/null 2>&1; then
                echo sips
            elif command -v magick >/dev/null 2>&1; then
                echo magick
            else
                echo "No HEIC encoder found (need sips on macOS or magick). Aborting..."
                return 1
            fi
            ;;
        *)
            echo "Unknown OPTIMOZE_HEIC_ENCODER='${OPTIMOZE_HEIC_ENCODER}'. Use auto, sips, or magick."
            return 1
            ;;
    esac
}

convert_to_heic() {
    local encoder="$1" src="$2" dst="$3"
    case "$encoder" in
        sips)   sips -s format heic "$src" --out "$dst" ;;
        magick) magick "$src" "$dst" ;;
        *)      return 1 ;;
    esac
}

# Cap parallel HEIC jobs so large folders cannot spawn thousands of processes.
# Default: min(ncpu, 4) for both sips and magick (benchmarked safe on Apple Silicon).
# Override with OPTIMOZE_MAX_JOBS (e.g. OPTIMOZE_MAX_JOBS=2 optiMOZe).
get_max_jobs() {
    if [[ -n "${OPTIMOZE_MAX_JOBS:-}" ]]; then
        echo "$OPTIMOZE_MAX_JOBS"
        return
    fi
    local n
    n=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 2)
    (( n > 4 )) && n=4
    echo "$n"
}

wait_for_job_slot() {
    local max="$1"
    while (( ${#job_pids[@]} >= max )); do
        wait "${job_pids[0]}" 2>/dev/null
        job_pids=("${job_pids[@]:1}")
    done
}

get_dimensions() {
    local f="$1"
    if command -v mdls >/dev/null 2>&1; then
        width=$(mdls -name kMDItemPixelWidth -raw "$f" 2>/dev/null | tr -d ' \n')
    	height=$(mdls -name kMDItemPixelHeight -raw "$f" 2>/dev/null | tr -d ' \n')
    elif command -v exiftool >/dev/null 2>&1; then
        read -r width height < <(exiftool -s3 -ImageWidth -ImageHeight "$f" 2>/dev/null)
    else
        read -r width height < <(identify -format "%w %h" "$f" 2>/dev/null)
    fi
    echo "$width $height"
}

mogrifyHEIC() {
	trap 'echo "Aborted."; trap - INT; return 1' INT
    require_exiftool
    command -v sips >/dev/null 2>&1 || { echo >&2 "Error: sips not found."; exit 1; }

    local files=(*.heic)
    [[ ${#files[@]} -eq 0 ]] && { echo "No HEIC files found in $PWD"; return; }

    echo "Checking and resizing HEIC files in $PWD..."
    for f in "${files[@]}"; do
        read -r width height < <(get_dimensions "$f")
        if [[ -n "$width" && -n "$height" ]]; then
            if (( width >= 2000 || height >= 2000 )); then
                echo "Downsizing '$f' (${width}x${height})..."
                local tmp="${f%.*}.optimoze.tmp.heic"
                sips -Z $((width > height ? width * 85 / 100 : height * 85 / 100)) "$f" --out "$tmp" &&
                copy_image_metadata "$f" "$tmp" &&
                mv "$tmp" "$f" || {
                    rm -f "$tmp"
                    echo "Failed to downsize '$f' (metadata may be unchanged)."
                }
            else
                echo "Skipping '$f' (${width}x${height}) — under 2000px."
            fi
        else
            echo "Could not get dimensions for '$f'. Skipping."
        fi
    done
	trap - INT
}

images_to_HEIC() {
    local label="$1"
    shift
    local files=("$@")
    [[ ${#files[@]} -eq 0 ]] && { echo "No ${label} files found in $PWD"; return; }

    require_exiftool
    local encoder max_jobs job_pids=() counter=0
    encoder=$(get_heic_encoder) || { echo "$encoder"; exit 1; }
    max_jobs=$(get_max_jobs)
    echo "Converting ${#files[@]} ${label} files via ${encoder} (max ${max_jobs} at a time)..."
    [[ "$encoder" == sips ]] && echo "Note: sips uses Apple Media Engine; output may be larger than magick/x265."

    for item in "${files[@]}"; do
        wait_for_job_slot "$max_jobs"
        local outname="${item%.*}.heic"
        local base="${item%.*}"
        local xmp=""
        [[ -f "${base}.xmp" ]] && xmp="${base}.xmp"
        [[ -f "${base}.XMP" ]] && xmp="${base}.XMP"
        mv "${item}" "moz.bak_${item}"
        (
            convert_to_heic "$encoder" "moz.bak_${item}" "${outname}" &&
            copy_image_metadata "moz.bak_${item}" "${outname}" ${xmp:+"$xmp"}
        ) &
        job_pids+=($!)
        ((counter++))
    done
    for pid in "${job_pids[@]}"; do wait "$pid" 2>/dev/null; done
    echo "${counter} ${label} files converted to HEIC."
}

JPEG_to_HEIC() {
    local files=(*.jpg *.jpeg)
    images_to_HEIC "JPEG" "${files[@]}"
}

PNG_to_HEIC() {
    local files=(*.png)
    images_to_HEIC "PNG" "${files[@]}"
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