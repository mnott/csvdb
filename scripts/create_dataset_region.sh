#!/bin/bash
#




create_dataset() {
    REGION="$1"

    #
    # Definitions
    #
    DATASET1=global_cloud_all_status
    DATASET2=global_pipeline
    DATASET3=services

    SOURCE11=data/$INPUT/$DATASET1/data/global_cloud_all_status_$REGION.csv

    SOURCE21=data/$INPUT/$DATASET2/data/global_pipeline_$REGION.csv

    SOURCE31=data/$INPUT/$DATASET3/data/services_$REGION.csv

    #
    # Template Dataset
    #
    SOURCE=template

    #
    # Checks
    #
    if [[ ! -d "data/$INPUT/$DATASET1" ]]; then
        echo "data/$INPUT/$DATASET1 not found. Exiting."
        exit 1
    fi

    if [[ ! -d "data/$INPUT/$DATASET2" ]]; then
        echo "data/$INPUT/$DATASET2 not found. Exiting."
        exit 1
    fi

    if [[ ! -d "data/$INPUT/$DATASET3" ]]; then
        echo "data/$INPUT/$DATASET3 not found. Exiting."
        exit 1
    fi

    if [[ ! -f "$SOURCE11" ]]; then
        echo "$SOURCE11 not found. Exiting."
        exit 1
    fi

    if [[ ! -f "$SOURCE21" ]]; then
        echo "$SOURCE21 not found. Exiting."
        exit 1
    fi

    if [[ ! -f "$SOURCE31" ]]; then
        echo "$SOURCE31 not found. Exiting."
        exit 1
    fi

    if [[ ! -d "data/$INPUT/$SOURCE" ]]; then
        echo "data/$INPUT/$SOURCE not found. Exiting."
        exit 1
    fi


    #
    # Output Dataset
    #
    TARGET="$TS-$REGION"

    echo "Creating Database $TARGET"


    #
    # Copy Template
    #
    echo ""
    echo ""
    echo "Copying template data/$INPUT/$SOURCE into target $OUTPUT/$TARGET"
    echo ""

    if [[ -d "$OUTPUT/$TARGET" ]]; then
        echo "$OUTPUT/$TARGET exists, removing..."
        rm -rf "$OUTPUT/$TARGET"
    fi


    #
    # Remember old Dataset
    #
    for i in $(ls -latrd1 $OUTPUT/20*$REGION | tail -1); do export OLDDATA=data/$(basename "$i")/data; done

    cp -av "data/$INPUT/$SOURCE" "$OUTPUT/$TARGET"

    #
    # Combine SOURCE21 and SOURCE22 into TARGET2
    #
    echo ""
    echo ""
    echo "Joining $SOURCE21, $SOURCE22, $SOURCE23 into data/$INPUT/$DATASET2/pipeline.csv"
    echo ""

    cat     "$SOURCE21" >  "data/$INPUT/$DATASET2/data/pipeline.csv"


    #
    # Join SOURCE12 and SOURCE22
    #
    echo ""
    echo ""
    echo "Joining $SOURCE11 into data/$INPUT/$DATASET1/pipeline.csv"
    echo ""

    cat     "$SOURCE11" >  "data/$INPUT/$DATASET1/data/pipeline.csv"


    #
    # Join SOURCE31
    #
    echo ""
    echo ""
    echo "Joining $SOURCE31 into data/$INPUT/$DATASET3/pipeline.csv"
    echo ""

    cat     "$SOURCE31" >  "data/$INPUT/$DATASET3/data/pipeline.csv"


    #
    # Extract Dataset 3
    #
    echo ""
    echo ""
    echo Extracting columns from $INPUT/$DATASET3/pipeline.csv into $OUTPUT/$TARGET/data/temp.csv
    echo ""

    export DATASET="$INPUT/$DATASET3"
    ./csvdb.pl -d -v "data/$INPUT/$DATASET3/views/extract.sql"  -r >"$OUTPUT/$TARGET/data/temp.csv"


    #
    # Extract Dataset 2
    #
    echo ""
    echo ""
    echo Extracting columns from $INPUT/$DATASET2/pipeline.csv into $OUTPUT/$TARGET/data/temp.csv
    echo ""

    export DATASET="$INPUT/$DATASET2"
    ./csvdb.pl -d -v "data/$INPUT/$DATASET2/views/extract.sql" -h -r >>"$OUTPUT/$TARGET/data/temp.csv"


    #
    # Extract Dataset 1
    #
    echo ""
    echo ""
    echo Extracting columns from $INPUT/$DATASET1/pipeline.csv into $OUTPUT/$TARGET/data/temp.csv
    echo ""

    export DATASET="$INPUT/$DATASET1"
    ./csvdb.pl -d -v "data/$INPUT/$DATASET1/views/extract.sql" -h -r >>"$OUTPUT/$TARGET/data/temp.csv"


    #
    # Remove Duplicates
    #
    echo ""
    echo ""
    echo Removing duplicates from $OUTPUT/$TARGET/data/temp.csv, creating $OUTPUT/$TARGET/data/pipeline.csv
    echo ""

    export DATASET=$OUTPUT/$TARGET/data
    scripts/join.pl temp >"$OUTPUT/$TARGET/data/pipeline.csv"

    #
    # Remove Temp Database
    #
    echo ""
    echo ""
    echo Removing temporary database $OUTPUT/$TARGET/data/temp.csv
    echo ""
    rm "$OUTPUT/$TARGET/data/temp.csv"


    #
    # Create Delta Database
    #
    echo ""
    echo ""
    echo Creating Delta Database: $TARGET vs. previous data: $OLDDATA
    echo ""
    export DATASET=${TARGET}

    if [[ -f "$OLDDATA/pipeline.csv" ]]; then
        cp "$OLDDATA/pipeline.csv"             "$OUTPUT/${TARGET}/data/temp1.csv"
        cp "$OUTPUT/$TARGET/data/pipeline.csv" "$OUTPUT/${TARGET}/data/temp2.csv"

        ./csvdb.pl -d -v "$OUTPUT/${TARGET}/views/extract_delta.sql" -r -h -p "_TABLE_=temp1" | sort >"$OUTPUT/${TARGET}/data/temp1j.csv"
        ./csvdb.pl -d -v "$OUTPUT/${TARGET}/views/extract_delta.sql" -r -h -p "_TABLE_=temp2" | sort >"$OUTPUT/${TARGET}/data/temp2j.csv"

        echo -n "testchen," >"$OUTPUT/${TARGET}/data/temp_pipeline.csv"

        head -1 "$OUTPUT/$TARGET/data/pipeline.csv" >>"$OUTPUT/${TARGET}/data/temp_pipeline.csv"
        diff --unchanged-line-format= --old-line-format= --new-line-format='%L' "$OUTPUT/${TARGET}/data/temp1j.csv" "$OUTPUT/${TARGET}/data/temp2j.csv" >>"$OUTPUT/${TARGET}/data/temp_pipeline.csv"

        ./csvdb.pl -d -v "$OUTPUT/${TARGET}/views/compress_delta.sql" -r -p "_TABLE_=temp_pipeline" >"$OUTPUT/${TARGET}/data/pipeline_d.csv"

        if [[ -f "$OUTPUT/${TARGET}/data/pipeline_d.csv" ]] && [[ ! -s "$OUTPUT/${TARGET}/data/pipeline_d.csv" ]]; then
            echo "Delta was empty. Copying original dataset.";
            cp "$OUTPUT/$TARGET/data/pipeline.csv" "$OUTPUT/${TARGET}/data/pipeline_d.csv"
        fi

        rm "$OUTPUT/${TARGET}"/data/temp*.csv
    else
        echo "Old dataset not found. Using new dataset."
        cp "$OUTPUT/$TARGET/data/pipeline.csv" "$OUTPUT/${TARGET}/data/pipeline_d.csv"
    fi

    #
    # Create Archive
    #
    echo ""
    echo ""
    echo "Creating archive $OUTPUT/$TARGET.zip"
    echo ""
    if [[ -f "$OUTPUT/$TARGET.zip" ]]; then
        rm -f "$OUTPUT/$TARGET.zip"
    fi

    (
      cd "$OUTPUT"

      zip -P $PW -vr "$TARGET.zip" "$TARGET"
    )

    #
    # Create Symlink for other scripts
    #
    if [[ -L "$OUTPUT/current" ]]; then
        rm -f "$OUTPUT/current";
    fi
    ln -s "$TARGET" "$OUTPUT/current"
}


#
# Input directory
#
export INPUT=input

#
# Output directory
#
export OUTPUT=data

#
# Timestamp
#
export TS=`date +"%Y-%m-%d"`
export PW=sap`date +"%m%d"`


if [[ $# -lt 1 ]]; then
    echo "Usage: $0 emeas|emean|mee..."
    exit 1
fi

create_dataset $1

#
# Create Regional Summary
#
echo ""
scripts/create_summary_region.sh $1 $TS rep_pipeline "Pipeline Review"
scripts/create_summary_region.sh $1 $TS rep_recoding_candidates "Recoding Candidates"


#
# Done.
#
echo ""
echo ""
echo Done. New Dataset is $TARGET
echo ""
