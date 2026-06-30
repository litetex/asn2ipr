#!/bin/bash

mkdir -p /zonefiles

asn6zonefile_dwl_url=https://raw.githubusercontent.com/litetex/rbldnsd-zone-asn/refs/heads/generated/asn6.zone
asn6zonefile=/zonefiles/asn6.zone

if [[ $FORCE_DOWNLOAD_ZONEFILE || ! -f $asn6zonefile ]]; then
    echo "Downloading $asn6zonefile_dwl_url to $asn6zonefile"
    if wget --tries=2 --timeout=600 -qO - $asn6zonefile_dwl_url > $asn6zonefile; then
        echo "Downloaded $asn6zonefile"
    else
        echo "Download failed!"
        exit 1
    fi
fi

asn6ipr_line_counter=0
asn6ipr_total_line_counter=$(wc -l < $asn6zonefile)

declare -A asn6ipr
echo "Building asn6ipr (will import $asn6ipr_total_line_counter lines)"
while IFS= read -r zline; do
    IFS='|' read -ra zlparts <<< "$zline"
    IFS=' ' read -ra zparts <<< "${zlparts[0]}"

    ipr=${zparts[0]}
    asn=${zparts[1]}
    asn6iprVal=${asn6ipr[$asn]}
    if [ -z "$asn6iprVal" ]; then
        asn6ipr[$asn]="$ipr"
    else
        asn6ipr[$asn]+=" $ipr"
    fi

    ((asn6ipr_line_counter++))
    if [ $((asn6ipr_line_counter % 5000)) -eq 0 ]; then
        echo "Processed $asn6ipr_line_counter/$asn6ipr_total_line_counter lines"
    fi

done < $asn6zonefile
echo "Done building asn6ipr"

echo "Preparing: Cleaning out dir"
rm -rf /out/ipv6
mkdir -p /out/ipv6

unset asn6iprVal

for sourcefile in *.txt; do
    outfile=/out/ipv6/$sourcefile

    echo "Processing $sourcefile to $outfile"
    echo "# Generated at $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > $outfile

    dos2unix $sourcefile

    while IFS= read -r line; do
        if [[ -z "$line" || $line == '#'* ]]; then
            continue
        fi

        if [[ $line == AS* || $line == as* ]]; then
            line="${line:2}"
        fi

        asn=$line

        echo "Processing AS$asn"
        echo "# $asn" >> $outfile

        asn6iprVal=${asn6ipr[$asn]}
        if [ -z "$asn6iprVal" ]; then
            continue
        fi

        IFS=' '; for ipr in $asn6iprVal; do
            echo $ipr >> $outfile
        done

    done < $sourcefile

    echo ""
done

