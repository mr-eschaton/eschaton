#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <DBFILE> <OUTFILE>"
    exit -1
fi

dbfile="$1"
outfile="$2"

tval=`date +"%F.%H.%M.%S"`
mkdir "$tval" && cd "$tval"

cp "../$dbfile" . &&  chmod +w $dbfile

tval_message_out="$tval.message.csv"
tval_chat_out="$tval.chat.csv"
tval_handle_out="$tval.handle.csv"
tval_attachment_out="$tval.attachment.csv"
tval_sql="$tval.sql"
tval_mod_sql="$tval.mod.sql"
tval_qry_out="$tval.out.csv"
tval_handle_qry_out="$tval.handle.out.csv"

handle_outfile="handle_$2"
undarked="$tval.undarked.csv"

undark -i $dbfile > $undarked

if [ $? -ne 0 ]; then
    echo "undark had errors"
fi

cat $undarked | awk -F "," \
    'NF==5{print $1","$3","$4","$5}'| sed -e "s/[xX]'/X'/g" > $tval_handle_out

cat $undarked | awk -F "," '{print $1","$3","$4","$5","$6","$7","$8","$9","$10","$11","$12","$13","$14","$15","$16","$17","$18","$19","$20","$22","$22","$23","$24","$25","$26","$27","$28","$29","$30","$31","$32","$33}' | sed -e "s/[xX]'/X'/g" > $tval_message_out

#cat $undarked | awk -F "," \
    #'NF==16{print $1","$3","$4","$5","$6","$7","$8","$9","$10","$11","$12","$13","$14","$15","$16}'| sed -e "s/[xX]'/X'/g" > $tval_chat_out

#cat $undarked | awk -F "," \
    #'NF==12{print $1","$3","$4","$5","$6","$7","$8","$9","$10","$11","$12}'| sed -e "s/[xX]'/X'/g" > $tval_attachment_out

#.trace stderr

sqlite3 <<EOS
.bail off
CREATE TABLE undarked_message(
ROWID INTEGER,
guid TEXT,
text TEXT,
replace INTEGER, 
service_center TEXT,
handle_id INTEGER,
subject TEXT,
country TEXT,
attributedBody BLOB,
version INTEGER,
type INTEGER,
service TEXT,
account TEXT,
account_guid TEXT,
error INTEGER,
date INTEGER,
date_read INTEGER,
date_delivered INTEGER,
is_delivered INTEGER,
is_finished INTEGER,
is_emote INTEGER,
is_from_me INTEGER,
is_empty INTEGER,
is_delayed INTEGER,
is_auto_reply INTEGER,
is_prepared INTEGER,
is_read INTEGER,
is_system_message INTEGER,
is_sent INTEGER,
has_dd_results INTEGER,
is_service_message INTEGER,
is_forward INTEGER,
was_downgraded INTEGER,
is_archive INTEGER,
cache_has_attachments INTEGER,
cache_roomnames TEXT,
was_data_detected INTEGER,
was_deduplicated INTEGER,
is_audio_message INTEGER,
is_played INTEGER,
date_played INTEGER,
item_type INTEGER,
other_handle INTEGER,
group_title TEXT,
group_action_type INTEGER,
share_status INTEGER,
share_direction INTEGER,
is_expirable INTEGER,
expire_state INTEGER,
message_action_type INTEGER,
message_source INTEGER);
CREATE TABLE undarked_handle ( 
ROWID INTEGER, id TEXT, country TEXT, service TEXT, uncanonicalized_id TEXT);
--CREATE TABLE undarked_attachment (ROWID INTEGER, guidTEXT, created_date INTEGER, start_date INTEGER, filename TEXT, uti TEXT, mime_type TEXT, transfer_state INTEGER, is_outgoing INTEGER, user_info BLOB, transfer_name TEXT, total_bytes);
--CREATE TABLE undarked_chat ( ROWID INTEGER, guid TEXT, style INTEGER, state INTEGER, account_id TEXT, properties BLOB, chat_identifier TEXT, service_name TEXT, room_name TEXT, account_login TEXT, is_archived INTEGER, last_addressed_handle TEXT, display_name TEXT, group_id TEXT, is_filtered INTEGER, successful_query INTEGER);
--CREATE TABLE undarked_chat_handle_join (chat_id INTEGER, handle_id INTEGER);
--CREATE TABLE undarked_chat_message_join (chat_id INTEGER, message_id INTEGER);
--CREATE TABLE undarked_message_attachment_join (message_id INTEGER, attachment_id INTEGER);
--CREATE TABLE undarked_sqlite_sequence (name TEXT, seq TEXT); 
.mode csv
.import $tval_handle_out undarked_handle
.import $tval_message_out undarked_message
--.import $tval_chat_out undarked_message
--.import $tval_attachment_out undarked_message
.output $tval_sql
.dump
.quit
EOS

cat $tval_sql | sed -e "s/'X''/X'/g; s/'''/'/g" > $tval_mod_sql
# SELECT m.rowid as RowID, DATETIME(date + 978307200, 'unixepoch', 'localtime') as Date, h.id as "Phone Number", m.service as Service, CASE is_from_me WHEN 0 THEN "Received" WHEN 1 THEN "Sent" ELSE "Unknown" END as Type, CASE WHEN date_read > 0 then DATETIME(date_read + 978307200, 'unixepoch') WHEN date_delivered > 0 THEN DATETIME(date_delivered + 978307200, 'unixepoch') ELSE NULL END as "Date Read/Sent", text as Text FROM undarked_message m, undarked_handle h WHERE h.rowid = m.handle_id ORDER BY m.rowid ASC;

sqlite3 <<EOS
.bail off
.read $tval_mod_sql
.mode csv
.headers on
.output $tval_qry_out
ATTACH '$dbfile' AS 'orig';
.databases
--SELECT m.rowid as RowID, DATETIME(date + 978307200, 'unixepoch', 'localtime') as Date, handle_id as "Handle ID", m.service as Service, CASE is_from_me WHEN 0 THEN "Received" WHEN 1 THEN "Sent" ELSE "Unknown" END as Type, CASE WHEN date_read > 0 then DATETIME(date_read + 978307200, 'unixepoch') WHEN date_delivered > 0 THEN DATETIME(date_delivered + 978307200, 'unixepoch') ELSE NULL END as "Date Read/Sent", text as Text FROM undarked_message m ORDER BY m.rowid ASC;
--SELECT m.rowid as RowID, DATETIME(date + 978307200, 'unixepoch', 'localtime') as Date, h.id as "Phone Number", m.service as Service, CASE is_from_me WHEN 0 THEN "Received" WHEN 1 THEN "Sent" ELSE "Unknown" END as Type, CASE WHEN date_read > 0 then DATETIME(date_read + 978307200, 'unixepoch') WHEN date_delivered > 0 THEN DATETIME(date_delivered + 978307200, 'unixepoch') ELSE NULL END as "Date Read/Sent", text as Text FROM undarked_message m, orig.handle h WHERE h.rowid = m.handle_id ORDER BY m.rowid ASC;
--qry with handle
SELECT m.rowid as RowID, DATETIME(date + 978307200, 'unixepoch', 'localtime') as Date, orig.handle.id as "Phone Number", m.service as Service, CASE is_from_me WHEN 0 THEN "Received" WHEN 1 THEN "Sent" ELSE "Unknown" END as Type, CASE WHEN date_read > 0 then DATETIME(date_read + 978307200, 'unixepoch') WHEN date_delivered > 0 THEN DATETIME(date_delivered + 978307200, 'unixepoch') ELSE NULL END as "Date Read/Sent", text as Text FROM undarked_message m LEFT JOIN orig.handle on orig.handle.rowid=m.handle_id ORDER by m.rowid ASC;
--qry no handle matches
--SELECT m.rowid as RowID, DATETIME(date + 978307200, 'unixepoch', 'localtime') as Date, h.id as "Phone Number", m.service as Service, CASE is_from_me WHEN 0 THEN "Received" WHEN 1 THEN "Sent" ELSE "Unknown" END as Type, CASE WHEN date_read > 0 then DATETIME(date_read + 978307200, 'unixepoch') WHEN date_delivered > 0 THEN DATETIME(date_delivered + 978307200, 'unixepoch') ELSE NULL END as "Date Read/Sent", text as Text FROM undarked_message m left join orig.handle h on m.handle_id = h.rowid where h.rowid is null ORDER BY m.rowid ASC;
.output $tval_handle_qry_out
SELECT * from undarked_handle;
.output stderr
.quit
EOS

cp $tval_qry_out ../$outfile
cp $tval_handle_qry_out ../$handle_outfile
cat $tval_qry_out $tval_handle_qry_out  > "total_$outfile"
cp "total_$outfile" ..
#rm $tval_out $tval_sql $tval_mod_sql
cd ..
