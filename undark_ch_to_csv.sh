#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <CSV INFILE> <OUTFILE>"
    exit -1
fi

undarked=$1
outfile=$2

tval=`date +"%F.%H.%M.%S"`
tval_out=".$tval.csv"
tval_sql=".$tval.sql"
tval_mod_sql=".$tval.mod.sql"
tval_qry_out="$tval.out.csv"

cat $undarked | awk -F "," \
    '{print $1","$3","$4","$5","$6","$7","$8","$9","$10","$11","$12","$13","$14","$15","$16","$17","$18","$19}' | sed -e "s/[xX]'/X'/g" > $tval_out

#.trace stderr

sqlite3 <<EOS
.bail off
CREATE TABLE undarked (Z_PK INTEGER, Z_ENT INTEGER, Z_OPT INTEGER, ZANSWERED INTEGER, ZCALLTYPE INTEGER, ZDISCONNECTED_CAUSE INTEGER, ZFACE_TIME_DATA INTEGER, ZNUMBER_AVAILABILITY INTEGER, ZORIGINATED INTEGER, ZREAD INTEGER, ZDATE TIMESTAMP, ZDURATION FLOAT, ZDEVICE_ID VARCHAR, ZISO_COUNTRY_CODE VARCHAR, ZLOCATION VARCHAR, ZNAME VARCHAR, ZUNIQUE_ID VARCHAR, ZADDRESS BLOB);
.mode csv
.import $tval_out undarked
.output $tval_sql
.dump
.quit
EOS

cat $tval_sql | sed -e "s/'X''/X'/g; s/''')/')/g" > $tval_mod_sql

sqlite3 <<EOS
.bail off
.read $tval_mod_sql
.mode csv
.headers on
.output $tval_qry_out
select Z_PK, Z_ENT, Z_OPT, ZANSWERED, CASE ZCALLTYPE WHEN 1 then "Mobile" WHEN 8 then "Facetime" ELSE "Unknown" END AS TYPE, ZDISCONNECTED_CAUSE, ZFACE_TIME_DATA, ZNUMBER_AVAILABILITY, case ZORIGINATED WHEN 1 then "Inbound" WHEN 0 then "Outbound" ELSE "Unknown" END AS ORIGINATED, ZREAD, strftime("%m-%d-%Y %H:%M:%S",ZDATE + 978307200, 'unixepoch') as DATE, ZDURATION, ZDEVICE_ID, ZISO_COUNTRY_CODE, ZLOCATION, ZNAME, ZUNIQUE_ID, ZADDRESS FROM undarked;
.output stderr
.quit
EOS

rm $tval_out $tval_sql $tval_mod_sql

mv $tval_qry_out $outfile
