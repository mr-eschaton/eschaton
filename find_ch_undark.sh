#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <DIRECTORY>"
    exit -1
fi

files=`find $1 -name "CallHistory.storedata"`

tval=`date +"%F.%H.%M.%S"`

for file in $files; do
    name=$(echo "$file" | sed -n 's/.*\(2017[0-9]*\)\/.*/\1/p')
    dbname="$tval$name.ch.db"
    csvname="$tval$name.ch.csv"
    undrname="$tval$name.undarked_raw.csv"
    finalundname="$tval$name.undarked.csv"
    cp $file $dbname

sqlite3 <<EOS
.open $dbname
.output $csvname
.mode csv
select Z_PK, Z_ENT, Z_OPT, ZANSWERED, CASE ZCALLTYPE WHEN 1 then "Mobile" WHEN 8 then "Facetime" ELSE "Unknown" END AS TYPE, ZDISCONNECTED_CAUSE, ZFACE_TIME_DATA, ZNUMBER_AVAILABILITY, case ZORIGINATED WHEN 1 then "Inbound" WHEN 0 then "Outbound" ELSE "Unknown" END AS ORIGINATED, ZREAD, strftime("%m-%d-%Y %H:%M:%S",ZDATE + 978307200, 'unixepoch'), ZDURATION, ZDEVICE_ID, ZISO_COUNTRY_CODE, ZLOCATION, ZNAME, ZUNIQUE_ID, ZADDRESS FROM ZCALLRECORD;
.output stdout
.quit
EOS

    undark -i $dbname > $undrname
    undark2csv $undrname $finalundname
done;
