#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <DB> <OUTFILE>"
    exit -1
fi

dbfile=$1

tval=`date +"%F.%H.%M.%S"`

outfile="$tval$2"

sqlite3 $dbfile <<EOS
.bail off
.mode csv
.output $outfile
select Z_PK, 
    Z_ENT, 
    Z_OPT, 
    ZANSWERED, 
    CASE ZCALLTYPE
    WHEN 1 then "Mobile"
    WHEN 8 then "Facetime"
    ELSE "Unknown"
    END AS TYPE, 
    ZDISCONNECTED_CAUSE, 
    ZFACE_TIME_DATA, 
    ZNUMBER_AVAILABILITY, 
    case ZORIGINATED
        WHEN 1 then "Inbound"
        WHEN 0 then "Outbound"
        ELSE "Unknown"
        END AS ORIGINATED,
        ZREAD, 
        strftime("%m-%d-%Y %H:%M:%S",ZDATE + 978307200, 'unixepoch'), 
        ZDURATION, 
        ZDEVICE_ID, 
        ZISO_COUNTRY_CODE, 
        ZLOCATION, 
        ZNAME, 
        ZUNIQUE_ID, 
        ZADDRESS 
        FROM ZCALLRECORD;
.quit
EOS



