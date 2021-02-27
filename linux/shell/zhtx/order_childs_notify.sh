#!/bin/bash
source /etc/profile
source /home/fengkai/shell/one/connfi.sh
echo ${notifysql}
file=`date "+%Y-%m-%d" --date="-1 day"`
file2=`date "+%Y-%m-%d"` #特定日期前一天
t=$1
x=$2
if [ -z $t ];then
sql1=${o_c_notifysql/"<startsql>"/$file}
echo $sql1
sql2=${sql1/"<endsql>"/$file2}
 echo ${sql2}
else if [ -z $x ];then
sql1=${o_c_notifysql/"<startsql>"/$1}
sql2=${sql1/"<endsql>"/$file2}
else
sql1=${o_c_notifysql/"<startsql>"/$1}
sql2=${sql1/"<endsql>"/$2}
fi
fi
echo ${sql2}
#file2=`date "+%Y-%m-%d"` #特定日期前一天
#file=`date "+%Y-%m-%d" --date="-1 day"`
logtime=`date "+%Y-%m-%d %H:%M:%S"`
dir=/home/fengkai/test
name=order_childs_notify                                    #需要声明的文件夹目录
`mkdir -p ${dir}/${file}/${name}`               #创建一个存放文件夹     #创建特定文件夹
hdfsfile=${file}/${name}
hfile=${dir}/${file}/${name}
echo 0>>${dir}/${file}/log              #生成log文件
log=${dir}/${file}/log
exec 1>>$log
exec 2>>$log
{
id=${file2}_order_childs_notify
echo $id
time=`date  +"%Y-%m-%d %H:%M:%S"`
mysql <<EOF
use test;
insert into bi_extract_log(id,create_date,script_id,status) values("${id}","${time}","order_childs_notify","CREATE");
exit
EOF
echo $i
start=`date "+%Y-%m-%d %H:%M:%S"`
echo "${0}--------------------------------------------------------${start}----------------------------------------------">>$log
HADOOP_HOME=/root/software/hadoop-2.5.2         #声明环境变量
SQOOP_HOME=/root/software/sqoop-1.4.5.bin__hadoop-2.0.4-alpha    #声明那个环境变量
start=`date "+%Y-%m-%d %H:%M:%S"`               #sh开启的时间
startsql=$file
endsql=$file2
connect='jdbc:mysql://192.168.200.182:34306/prdorddb?useUnicode=true&characterEncoding=utf-8&tinyInt1isBit=false'
username=fengkai
password=iC68Wqui$
${HADOOP_HOME}/bin/hadoop fs -test -e /sqoop/$hdfsfile  #test -e 验证文件夹是否存在
if [ $? -eq 0 ]; then                                   #验证文件夹是否存在，存在就删除
${HADOOP_HOME}/bin/hadoop fs -rmr /sqoop/${hdfsfile}
echo "--delet---${hdfsfile}------OK"
fi
echo $0
date "+%Y-%m-%d %H:%M:%S"
time=`date  +"%Y-%m-%d %H:%M:%S"`
mysql <<EOF
use test;
update bi_extract_log set status="export",export_time="${time}" where id="${id}";
exit
EOF
sql="select a.child_order_id\
,a.child_order_no\
,a.ss_id\
,a.ss_name\
,a.sm_id\
,a.sm_user_name\
,a.sm_name\
,a.shop_id\
,a.shop_user_name\
,a.shop_name\
,a.order_id\
,a.pay_way\
,a.amount\
,a.account_balance\
,a.frozen_balance\
,a.red_money\
,a.child_coupon_money\
,a.status\
,a.pay_status\
,a.distribution_type\
,a.logistics_fee\
,DATE_FORMAT(a.create_time,'%Y-%m-%d %T') create_time\
,DATE_FORMAT(a.receive_time,'%Y-%m-%d %T')\
,DATE_FORMAT(a.send_time,'%Y-%m-%d %T') send_time\
,DATE_FORMAT(a.print_time,'%Y-%m-%d %T') print_time\
,DATE_FORMAT(a.apply_cancel_time,'%Y-%m-%d %T') apply_cancel_time\
,DATE_FORMAT(a.sure_cancel_time,'%Y-%m-%d %T') sure_cancel_time\
,a.remark,\
DATE_FORMAT(a.delivered_time,'%Y-%m-%d %T') delivered_time\
,a.delivered_status\
,a.sm_shopsaleman_id\
,a.yyyymmdd\
,a.is_history\
,a.is_del\
,a.sm_saleman_id\
,a.shop_saleman_id\
,a.midcloudpurchaseid\
,a.midcloudpurchasecode\
,DATE_FORMAT(a.midcloudaddcallbacktime,'%Y-%m-%d %T') midcloudaddcallbacktime\
,a.commission\
,a.saleman_commission_rate\
,a.ss_commission_rate\
,a.sm_sssaleman_id \
,DATE_FORMAT(b.notify_time,'%Y-%m-%d %T')\
 from orders b\
 join order_childs a \
on a.order_id=b.order_id\
 where b.notify_time >=\"${startsql}\" \
and b.notify_time <\"${endsql}\" \
and a.pay_status=1 \
and a.ss_id not in (4,44,73,179,413,686,687,704,705,922,930,950,951,952,954,955,956,957,958,959,960,961,962) \
and \$CONDITIONS"
echo $sql
${SQOOP_HOME}/bin/sqoop import --connect \"${connect}\"\
 --username ${username} --password ${password}\
 --query "\"${sql2}\"" --fields-terminated-by '\001' --null-string '' --null-non-string '' --hive-drop-import-delims\
 -m 1 --target-dir /sqoop/${hdfsfile}
#${SQOOP_HOME}sqoop import --connect ${connect}\
# --username ${username} --password ${password}\
# --query "\"${sql}\"" --fields-terminated-by '\001' --null-string '' --null-non-string '' --hive-drop-import-delims\
# -m 1 --target-dir /sqoop/"${hdfsfile}"
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
if [ -z $t ];then
sql="select count(1) from prdorddb.orders b\
 join prdorddb.order_childs a \
on a.order_id=b.order_id\
 where b.notify_time >=\"${file}\" \
and b.notify_time <\"${file2}\" \
and a.pay_status=1 \
and a.ss_id not in (${ss_id})"
else if [ -z $x ];then
sql="select count(1) from prdorddb.orders b\
 join prdorddb.order_childs a \
on a.order_id=b.order_id\
 where b.notify_time >=\"${t}\" \
and b.notify_time <\"${file2}\" \
and a.pay_status=1 \
and a.ss_id not in (${ss_id})"
else
sql="select count(1) from prdorddb.orders b\
 join prdorddb.order_childs a \
on a.order_id=b.order_id\
 where b.notify_time >=\"${t}\" \
and b.notify_time <\"${x}\" \
and a.pay_status=1 \
and a.ss_id not in (${ss_id})"
fi
fi
echo $sql
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
${HIVE_HOME}/bin/hive -e "load data local inpath '${hfile}' into table ${hive_db}.order_childs_notify"
if [ $? -ne 0 ];then
echo "error:order_childs_notify to hive "
fi
else
echo "error:sqoop to order_childs_notify error"
bash /home/fengkai/shell/one/order_childs_notify.sh
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
#${SQOOP_HOME}/bin/sqoop list-tables --connect jdbc:mysql://192.168.102.142:3306/xxx --username hadoop --password hadoop
}>>$log
#done
