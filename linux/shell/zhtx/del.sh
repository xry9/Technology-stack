#bin/bash
source /etc/profile
today=`date "+%Y-%m-%d %H:%M:%S"`
sallday=`date "+%Y-%m-%d" --date="-7 day"`
file=`date "+%Y-%m-%d" --date="-31 day"`
dir=/home/fengkai/test/$file
sall=/home/fengkai/test/sall${sallday}
hdfs=/sqoop/$file
log=/home/fengkai/test/del.sh.log
exec 1>>$log
exec 2>>$log
#########删除31天以前的每日数据
echo "--------------------------------------"
if [ -d ${dir} ];then
rm -rf $dir
if [ $? -eq 0 ];then
echo "${today} delete file name ${file}"
else
echo "${today} delete file name ${file} is error"
fi
fi
########删除7天前的汇总数据
if [ -d ${sall} ];then
`rm -rf ${sall}`
if [ $? -eq 0 ];then
echo "${today} delete file name ${sall}"
else
echo "${today} delete file name ${sall} is error"
fi
fi
##########删除31天前的hdfs数据
${HADOOP_HOME}/bin/hadoop fs -test -e /sqoop/$file  #test -e 验证文件夹是否存在
if [ $? -eq 0 ]; then                                   #验证文件夹是否存在，存在就删除
${HADOOP_HOME}/bin/hadoop fs -rmr /sqoop/${file}
echo "${today} delete hdfs file name sqoop/${file}"
fi

################## 删除每日sqoop产生的java文件
for i in summary_page_info.java summary_top.java QueryResult.java nohup.out summary_bank_channel.java summary_order_cannel_reason.java track_bi_sales_gmv.java summary_map.java summary_order_status.java track_bi_sales_pay_way.java sqoop.java summary_new_old.java summary_pay_way.java track_bi_sales_call.java track_bi_sales_type_distribution.java;
do
rm -rf /root/$i
if [ $? -eq 0 ];then
echo "${today} delete file name /root/${i}"
fi
done
