#!/bin/bash
source /etc/profile
source /home/fengkai/shell/one/sqoop_to_mysql/sqoop.init
s_table=track_bi_sales_call
s_dir=/sqoop/count/track_bi_sales_call
today=`date "+%Y-%m-%d"`	#当前日期
yesterday=`date "+%Y-%m-%d" --date="-1 day"`
log=/home/fengkai/test/${yesterday}/log
id=${today}_${s_table}
exec 1>>$log
exec 2>>$log
time=`date "+%Y-%m-%d :%H:%M:%S"`
{
##################################
t=$1
x=$2
if [ -z $t ];then
begin=$yesterday
end=$today
else if [ -z $x ];then
begin=$t
end=$today
else
begin=$t
end=$x
fi
fi
echo "begin="$begin
echo "end="$end
###################################
sql2=${track_bi_sales_call_sql/"<begin>"/$begin}
hive_sql=${sql2/"<end>"/$end}
echo $hive_sql
##################################
mysql -u$user  -p$pass  -P $port -h$mysql_ip << EOF
use test;
insert into bi_extract_log(id,create_date,script_id,status) values("${id}","${time}","${name}","CREATE");
EOF
#######下单总量，1
${HIVE_HOME}/bin/hive -e "insert overwrite table new_bi.track_bi_sales_call \
${hive_sql}"
if [ $? -eq 0 ];then
       echo "hive success!" 
mysql -u$user  -p$pass  -P $port -h$mysql_ip << EOF
use test;
update bi_extract_log set status="HIVE_end",start="${begin}" where id="${id}"
EOF
else
       echo "error:hive is failed!"
fi
#################################
#sqoop hive to mysql
mysql -u$user  -p$pass  -P $port -h$mysql_ip << EOF
use test;
update bi_extract_log set status="export" where id="${id}";
EOF
${SQOOP_HOME}/bin/sqoop export \
--connect $connect \
--username $username \
--password $password \
--table $s_table \
--export-dir $s_dir \
--null-string '' \
--null-non-string '' \
--input-fields-terminated-by '\001'
###################################
finish=`date "+%Y-%m-%d :%H:%M:%S"`
sql="select count(1) from ${sql_db}.${s_table} nb  where date(nb.time)=\"${begin}\""
echo $sql
number=$(mysql -u$username -p$password -h192.168.200.101 -P3306  -e "$sql");
ab=`echo ${number}|awk  '{print $2}'`
echo $ab
mysql <<EOF
use test;
update bi_extract_log set status="FINISH",finish_time="${finish}", export_count=$ab  where id="${id}";
exit
EOF
}>>$log
