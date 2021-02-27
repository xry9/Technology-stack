#!/bin/bash
source /etc/profile
source /home/fengkai/shell/one/connfi.sh
echo ${banksql}
file2=`date "+%Y-%m-%d"` #特定日期前一天
file=`date "+%Y-%m-%d" --date="-1 day"`
logtime=`date "+%Y-%m-%d %H:%M:%S"`
dir=/home/fengkai/test
name=bank_info                                  #需要声明的文件夹目录
`mkdir -p ${dir}/${file}/${name}`               #创建一个存放文件夹     #创建特定文件夹
hdfsfile=${file}/${name}
hfile=${dir}/${file}/${name}
echo 0>>${dir}/${file}/log              #生成log文件
log=${dir}/${file}/log
exec 1>>$log
exec 2>>$log
{
id=${file2}_${name}
echo $id
time=`date  +"%Y-%m-%d %H:%M:%S"`
mysql <<EOF
use test;
insert into bi_extract_log(id,create_date,script_id,status) values("${id}","${time}","${name}","CREATE");
exit
EOF
echo $i
start=`date "+%Y-%m-%d %H:%M:%S"`
echo "${0}--------------------------------------------------------${start}----------------------------------------------">>$log
HADOOP_HOME=/root/software/hadoop-2.5.2         #声明环境变量
SQOOP_HOME=/root/software/sqoop-1.4.5.bin__hadoop-2.0.4-alpha   #声明那个环境变量
start=`date "+%Y-%m-%d %H:%M:%S"`               #sh开启的时间
startsql=$file
endsql=$file2
connect='jdbc:mysql://192.168.200.182:34306/paydb?useUnicode=true&characterEncoding=utf-8&tinyInt1isBit=false'
username=fengkai
password=iC68Wqui$
db=prdorddb
${HADOOP_HOME}/bin/hadoop fs -test -e /sqoop/$hdfsfile  #test -e 验证文件夹是否存在
if [ $? -eq 0 ]; then                                   #验证文件夹是否存在，存在就删除
${HADOOP_HOME}/bin/hadoop fs -rmr /sqoop/${hdfsfile}
echo "--delet---${hdfsfile}------OK"
fi
time=`date  +"%Y-%m-%d %H:%M:%S"`
mysql <<EOF
use test;
update bi_extract_log set status="export",export_time="${time}" where id="${id}";
exit
EOF
echo $0
sql="select id,bank_name from bank_info  where create_time >=\"2010-01-01 00:00:00\" and \$CONDITIONS"
echo $sql
${SQOOP_HOME}/bin/sqoop import --connect ${connect}\
 --username ${username} --password ${password}\
 --query "\"${banksql}\"" --fields-terminated-by '\001' --null-string '' --null-non-string '' --hive-drop-import-delims\
 -m 1 --target-dir /sqoop/"${hdfsfile}"
echo $?
echo $?
echo $?
ls $hfile
if [ $? -eq 0 ]; then
`rm -rf $hfile`
echo "${delet}--delet---${hfile}------OK"
fi
echo `mkdir -p ${hfile}`
${HADOOP_HOME}/bin/hadoop fs -get /sqoop/${hdfsfile}/part-m-00000 ${hfile}
echo "${?}下载文件/sqoop/${hdfsfile}/part-m-00000到${hfile}"
echo ${0}
cloum=`wc -l ${hfile}/part-m-00000`
clo=$cloum
time=`date  +"%Y-%m-%d %H:%M:%S"`
mysql <<EOF
use test;
update bi_extract_log set status="check",check_time="${time}" where id="${id}";
exit
EOF
sql="select count(1) from paydb.bank_info"
number=$(mysql -ufengkai -piC68Wqui$ -h192.168.200.182 -P34306  -e \
"${sql}");
echo $number
ab=`echo ${number}|awk  '{print $2}'`
echo $?
echo $ab
cc=${clo%% *}
echo $cc >>/home/fengkai/init/maillog
end=`date "+%Y-%m-%d %H:%M:%S"`
if [ $ab -eq $cc ];then
mysql <<EOF
use test;
update bi_extract_log set status="FINISH",finish_time="${end}", export_count=$ab  where id="${id}";
exit
EOF
${HIVE_HOME}/bin/hive -e "load data local inpath '${hfile}' overwrite into table ${hive_db}.bank_info"
else
echo "error:bank_info.sh error"
bash /home/fengkai/shell/one/bank_info.sh
fi
cc="${clo%% *}----${0}---${logtime}"
echo $cc >>/home/fengkai/init/maillog
end=`date "+%Y-%m-%d %H:%M:%S"`
echo  "end" $end
time1=`date -d "$start" +%s`
time2=`date -d "$end" +%s`
time=`expr $time2 - $time1`
echo ${time} "秒"
echo
}>>$log





======================================
${HADOOP_HOME}/bin/hadoop fs -test -e /sqoop/$hdfsfile  #test -e 验证文件夹是否存在
if [ $? -eq 0 ]; then                                   #验证文件夹是否存在，存在就删除
${HADOOP_HOME}/bin/hadoop fs -rmr /sqoop/${hdfsfile}


========================================
end=`date "+%Y-%m-%d %H:%M:%S"`
echo  "end" $end
time1=`date -d "$start" +%s`
time2=`date -d "$end" +%s`
time=`expr $time2 - $time1`
echo ${time} "秒"
