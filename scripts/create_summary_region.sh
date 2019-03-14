#!/bin/bash
#

create_dataset() {
    export REGION=$1
    export DATE=$2
    export VIEW=$3
    export NAME=$4

    export REGIONUC=$(echo $REGION| awk '{print toupper($0)}')

    echo "Creating Region Summary for $REGIONUC for $DATE using $VIEW ($NAME)"

    export DATASET="$DATE-$REGION"

    if [[ -f "extracts/$REGIONUC/data/$NAME - $REGIONUC.csv" ]]; then
        rm -f "extracts/$REGIONUC/data/$NAME - $REGIONUC.csv"
    fi

    ./csvdb.pl -d -v "data/$DATASET/views/$VIEW.sql" -r -h -p _DELTA_="" >"extracts/$REGIONUC/data/$NAME - $REGIONUC.csv"
}


if [[ $# -lt 3 ]]; then
    echo "Usage: $0 emeas|emean|mee... 2018-09-14 rep_recoding_candidates|rep_pipeline \"Recoding Candidates\"|\"Pipeline Review\""
    exit 1
fi

create_dataset "$1" "$2" "$3" "$4"


export REGIONUC=$(echo $REGION| awk '{print toupper($0)}')

#
# MEE MUs
#
if [[ $REGIONUC == MEE ]]; then
    for i in Switzerland; do scripts/create_summary_mu.sh "$REGIONUC" "$i" "$2" "$3" "$4"; done
fi
