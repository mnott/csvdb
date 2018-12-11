#!/bin/bash
#
# We assume that we already created the regional data sets.
#


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

#
# Template Dataset
#
SOURCE=template

#
# Output Dataset
#
TARGET="$TS-global"

if [[ -d "$OUTPUT/$TARGET" ]]; then
    echo "$OUTPUT/$TARGET exists, removing..."
    rm -rf "$OUTPUT/$TARGET"
fi

cp -av "data/$INPUT/$SOURCE" "$OUTPUT/$TARGET"


#
# Create Global Pipeline
#
head -1 $OUTPUT/$TS-apj/data/pipeline.csv >$OUTPUT/$TARGET/data/pipeline.csv
head -1 $OUTPUT/$TS-apj/data/pipeline_d.csv >$OUTPUT/$TARGET/data/pipeline_d.csv
for i in apj emean emeas gc la mee na; do
    tail +2 $OUTPUT/$TS-$i/data/pipeline.csv >>$OUTPUT/$TARGET/data/pipeline.csv
    tail +2 $OUTPUT/$TS-$i/data/pipeline_d.csv >>$OUTPUT/$TARGET/data/pipeline_d.csv
done

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

