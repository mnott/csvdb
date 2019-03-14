#!/bin/bash
#
# scripts/create_summary_test.sh ch 2019-03-12 rep_pipeline "Pipeline Review"
#
# Region: mee
# MU    : Switzerland
# Date  : 2019-03-12
# View  : rep_pipeline
# Name  : Pipeline Review
#
# Subsets: analytics, ibso, leonardo_tech, scp

create_dataset() {
    export REGION=$1
    export MU=$2
    export DATE=$3
    export VIEW=$4
    export NAME=$5

    export REGIONUC=$(echo $REGION| awk '{print toupper($0)}')

    echo "Creating Region Summary for $REGIONUC/$MU for $DATE creating $NAME"

    export DATASET="$DATE-$REGION"

    if [[ ! -d "extracts/$REGIONUC/MUs/$MU/data" ]]; then
      mkdir -p "extracts/$REGIONUC/MUs/$MU/data"
    fi

    if [[ -f "extracts/$REGIONUC/MUs/$MU/data/$NAME - $REGIONUC.csv" ]]; then
        rm -f "extracts/$REGIONUC/MUs/$MU/data/$NAME - $REGIONUC.csv"
    fi

    ./csvdb.pl -d -v "data/$DATASET/views/${VIEW}_analytics.sql"     -r -h -p _DELTA_="" _MU_="$MU"  >"extracts/$REGIONUC/MUs/$MU/data/$NAME - $REGIONUC - $MU.csv"
    ./csvdb.pl -d -v "data/$DATASET/views/${VIEW}_ibso.sql"          -r -h -p _DELTA_="" _MU_="$MU" >>"extracts/$REGIONUC/MUs/$MU/data/$NAME - $REGIONUC - $MU.csv"
    ./csvdb.pl -d -v "data/$DATASET/views/${VIEW}_leonardo_tech.sql" -r -h -p _DELTA_="" _MU_="$MU" >>"extracts/$REGIONUC/MUs/$MU/data/$NAME - $REGIONUC - $MU.csv"
    ./csvdb.pl -d -v "data/$DATASET/views/${VIEW}_scp.sql"           -r -h -p _DELTA_="" _MU_="$MU" >>"extracts/$REGIONUC/MUs/$MU/data/$NAME - $REGIONUC - $MU.csv"

#    ./csvdb.pl -d -v "data/$DATASET/views/$VIEW.sql" -r -h -p _DELTA_="" >"extracts/$REGIONUC/data/$NAME - $REGIONUC.csv"
}


if [[ $# -lt 3 ]]; then
    echo "Usage: $0 emeas|emean|mee... Switzerland|Germany... 2018-09-14 rep_recoding_candidates|rep_pipeline \"Recoding Candidates\"|\"Pipeline Review\""
    exit 1
fi

create_dataset "$1" "$2" "$3" "$4" "$5"

