#!/bin/bash
#

#
# Input directory
#
INPUT=input

#
# Output directory
#
OUTPUT=data

#
# Definitions
#
DATASET1=cloud_consolidated_pipeline
DATASET2=global_salesprogram_incentive

SOURCE11=data/$INPUT/$DATASET1/data/pipeline_emea.csv
SOURCE12=data/$INPUT/$DATASET1/data/pipeline_mee.csv

SOURCE21=data/$INPUT/$DATASET2/data/q3_emea.csv
SOURCE22=data/$INPUT/$DATASET2/data/q4_emea.csv
SOURCE23=data/$INPUT/$DATASET2/data/q1_emea.csv
SOURCE24=data/$INPUT/$DATASET2/data/q3_mee.csv
SOURCE25=data/$INPUT/$DATASET2/data/q4_mee.csv
SOURCE26=data/$INPUT/$DATASET2/data/q1_mee.csv

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

if [[ ! -f "$SOURCE11" ]]; then
    echo "$SOURCE11 not found. Exiting."
    exit 1
fi

if [[ ! -f "$SOURCE12" ]]; then
    echo "$SOURCE11 not found. Exiting."
    exit 1
fi

if [[ ! -f "$SOURCE21" ]]; then
    echo "$SOURCE21 not found. Exiting."
    exit 1
fi

if [[ ! -f "$SOURCE22" ]]; then
    echo "$SOURCE22 not found. Exiting."
    exit 1
fi

if [[ ! -f "$SOURCE23" ]]; then
    echo "$SOURCE23 not found. Exiting."
    exit 1
fi

if [[ ! -f "$SOURCE24" ]]; then
    echo "$SOURCE24 not found. Exiting."
    exit 1
fi

if [[ ! -f "$SOURCE25" ]]; then
    echo "$SOURCE24 not found. Exiting."
    exit 1
fi

if [[ ! -f "$SOURCE26" ]]; then
    echo "$SOURCE24 not found. Exiting."
    exit 1
fi

if [[ ! -d "data/$INPUT/$SOURCE" ]]; then
    echo "data/$INPUT/$SOURCE not found. Exiting."
    exit 1
fi



#
# Timestamp
#
TS=`date +"%Y-%m-%d"`

#
# Output Dataset
#
TARGET="joined_pipeline - $TS"



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

cp -av "data/$INPUT/$SOURCE" "$OUTPUT/$TARGET"

#
# Combine SOURCE21 and SOURCE22 into TARGET2
#
echo ""
echo ""
echo "Joining $SOURCE21, $SOURCE22, $SOURCE23, $SOURCE24 into data/$INPUT/$DATASET2/pipeline.csv"
echo ""

cat     "$SOURCE21" >  "data/$INPUT/$DATASET2/data/pipeline.csv"
tail +2 "$SOURCE22" >> "data/$INPUT/$DATASET2/data/pipeline.csv"
tail +2 "$SOURCE23" >> "data/$INPUT/$DATASET2/data/pipeline.csv"
tail +2 "$SOURCE24" >> "data/$INPUT/$DATASET2/data/pipeline.csv"
tail +2 "$SOURCE25" >> "data/$INPUT/$DATASET2/data/pipeline.csv"
tail +2 "$SOURCE26" >> "data/$INPUT/$DATASET2/data/pipeline.csv"


#
# Join SOURCE12 and SOURCE22
#
echo ""
echo ""
echo "Joining $SOURCE11, $SOURCE12 into data/$INPUT/$DATASET1/pipeline.csv"
echo ""

cat     "$SOURCE11" >  "data/$INPUT/$DATASET1/data/pipeline.csv"
tail +2 "$SOURCE12" >> "data/$INPUT/$DATASET1/data/pipeline.csv"


#
# Extract Dataset 2
#
echo ""
echo ""
echo Extracting columns from $INPUT/$DATASET2/pipeline.csv into $OUTPUT/$TARGET/data/temp.csv
echo ""

export DATASET="$INPUT/$DATASET2"
./csvdb.pl -d -v "data/$INPUT/$DATASET2/views/extract.sql"     -r >"$OUTPUT/$TARGET/data/temp.csv"


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
# Create Archive
#
echo ""
echo ""
echo "Creating archive $OUTPUT/$TARGET.zip"
echo ""
if [[ -f "$OUTPUT/$TARGET.zip" ]]; then
    rm -f "$OUTPUT/$TARGET.zip"
fi

zip -ver "$OUTPUT/$TARGET.zip" "$OUTPUT/$TARGET"

#
# Create Symlink for other scripts
#
if [[ -L "$OUTPUT/current" ]]; then
    rm -f "$OUTPUT/current";
fi
ln -s "$TARGET" "$OUTPUT/current"

#
# Done.
#
echo ""
echo ""
echo Done. New Dataset is $TARGET
echo ""
