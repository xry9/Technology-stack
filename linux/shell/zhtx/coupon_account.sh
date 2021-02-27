#!/bin/bash
source /home/fengkai/shell/one/connfi.sh
echo ${coupon_accountsql}
file2=`date "+%Y-%m-%d"` #特定日期前一天
file=`date "+%Y-%m-%d" --date="-1 day"`
logtime=`date "+%Y-%m-%d %H:%M:%S" --date="-1 day"`
dir=/home/fengkai/test
name=coupon_account                        #需要声明的文件夹目录
`mkdir -p ${dir}/${file}/${name}`               #创建一个存放文件夹     #创建特定文件夹
hdfsfile=${file}/${name}
hfile=${dir}/${file}/${name}
echo 0>>${dir}/${file}/log              #生成log文件
log=${dir}/${file}/log
exec 1>>$log
exec 2>>$log
t=$1
x=$2
if [ -z $t ];then
sql1=${coupon_accountsql/"<startsql>"/$file}
sql2=${sql1/"<endsql>"/$file2}
st=$file
en=$file2
else if [ -z $x ];then
sql1=${coupon_accountsql/"<startsql>"/$t}
sql2=${sql1/"<endsql>"/$file2}
st=$t
en=$file2
else
sql1=${coupon_accountsql/"<startsql>"/$t}
sql2=${sql1/"<endsql>"/$x}
st=$t
en=$x
fi
fi
echo $sql2
{
echo $i
id=${file2}_${name}
echo $id
time=`date  +"%Y-%m-%d %H:%M:%S"`
mysql <<EOF
use test;
insert into bi_extract_log(id,create_date,script_id,status) values("${id}","${time}","${name}","CREATE");
exit
EOF
start=`date "+%Y-%m-%d %H:%M:%S"`
echo "${0}--------------------------------------------------------${start}----------------------------------------------">>$log
HADOOP_HOME=/root/software/hadoop-2.5.2         #声明环境变量
SQOOP_HOME=/root/software/sqoop-1.4.5.bin__hadoop-2.0.4-alpha  #声明那个环境变量
start=`date "+%Y-%m-%d %H:%M:%S"`               #sh开启的时间
startsql="2010-01-01"
endsql=$file2
connect='jdbc:sqlserver://192.168.200.76:1433;username=prdbigdata;password=*q1dr1mBO;database=Gos;useUnicode=true&characterEncoding=utf-8&tinyInt1isBit=false&Bit=fales'
username=fengkai
password=iC68Wqui$
db=gos
${HADOOP_HOME}/bin/hadoop fs -test -e /sqoop/$hdfsfile  #test -e 验证文件夹是否存在
if [ $? -eq 0 ]; then                                   #验证文件夹是否存在，存在就删除
${HADOOP_HOME}/bin/hadoop fs -rmr /sqoop/${hdfsfile}
echo "--delet---${hdfsfile}------OK"
fi
time=`date  +"%Y-%m-%d %H:%M:%S"`
mysql <<EOF
use test;
update bi_extract_log set status="export",export_time="${time}",start="${st}",end="${en}" where id="${id}";
exit
EOF
echo $0
${SQOOP_HOME}/bin/sqoop import --connect ${connect}\
 --query "\"${sql2}\"" --fields-terminated-by '\001' \
--map-column-java is_del=String \
--null-string '' --null-non-string '' --hive-drop-import-delims\
 -m 1 --target-dir /sqoop/"${hdfsfile}"
echo $?
echo $?
echo $?
${SQOOP_HOME}/bin/sqoop eval

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
eval={sqoop eval --connect 'jdbc:sqlserver://192.168.200.76:1433;username=prdbigdata;password=*q1dr1mBO;database=Gos'  --query "SELECT COUNT(1) FROM marketing.coupon_account WHERE create_time >='2017-05-30'"}
$eval
mysql <<EOF
use test;
update bi_extract_log set status="check",check_time="${time}" where id="${id}";
exit
EOF
#sql="select count(1) from paydb.channel_bank"
#number=$(mysql -ufengkai -piC68Wqui$ -h192.168.200.182 -P34306  -e \
#"${sql}");
#echo $number
#ab=`echo ${number}|awk  '{print $2}'`
#echo $?
#echo $ab
cc=${clo%% *}
ab=$cc
echo $cc >>/home/fengkai/init/maillog
end=`date "+%Y-%m-%d %H:%M:%S"`
#if [ $ab -eq $cc ];then
mysql <<EOF
use test;
update bi_extract_log set status="FINISH",finish_time="${end}", export_count=$ab  where id="${id}";
exit
EOF
#else
#bash /home/fengkai/shell/one/supermarket.sh
#fi
cc="${clo%% *}----${0}---${logtime}"
echo $cc >>/home/fengkai/init/maillog
end=`date "+%Y-%m-%d %H:%M:%S"`
echo  "end" $end
time1=`date -d "$start" +%s`
time2=`date -d "$end" +%s`
time=`expr $time2 - $time1`
echo ${time} "秒"
echo
#${SQOOP_HOME}/bin/sqoop list-tables --connect jdbc:mysql://192.168.102.142:3306/xxx --username hadoop --password hadoop
#系统分配的区总量  
mem_total=`free -m | awk 'NR==2' | awk '{print $2}'` 
#当前剩余的大小  
mem_free=`free -m | awk 'NR==3' | awk '{print $4}'`   
#当前已使用的used大小  
mem_used=`free -m | grep Mem | awk '{print  $3}'`  
mem_perp=`echo "scale=2;$mem_free*100/$mem_total" | bc`%
if (($mem_used != 0)); then 
#如果已被使用，则计算当前剩余free所占总量的百分比，用小数来表示，要在小数点前面补一个整数位0  
mem_per=0`echo "scale=2;$mem_free/$mem_total" | bc`  
DATA="$(date  +"%Y-%m-%d %H:%M:%S") www.slave3.com  free percent is : $mem_perp"
echo $DATA >> /home/fengkai/init/maillog
#设置的告警值为20%(即使用超过80%的时候告警)。  
mem_warn=0.20  
#当前剩余百分比与告警值进行比较（当大于告警值(即剩余20%以上)时会返回1，小于(即剩余不足20%)时会返回0 ）  
mem_now=`expr $mem_per \> $mem_warn`
#如果当前使用超过80%（即剩余小于20%，上面的返回值等于0），释放内存
if (($mem_now == 0)); then  
sync
echo 3 > /proc/sys/vm/drop_caches
fi 
fi 
for i in 2 4
do
ssh root@www.slave${i}.com "bash /home/fengkai/init/free.sh "
sleep 3
ssh root@www.slave${i}.com 'cat /home/fengkai/init/maillog' >>/home/fengkai/init/maillog
done
}>>$log
