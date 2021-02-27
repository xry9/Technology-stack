#! /bin/sh
proc_name="HMaster"        #进程名
proc_num()                      #查询进程数量
{
	num=`ps -ef | grep $proc_name | grep -v grep | wc -l`
	return $num
}
proc_num
number=$?                       #获取进程数量
if [ $number -eq 0 ]            #如果进程数量为0
then                            #重新启动服务器，或者扩展其它内容
	echo `date` >> /home/tyx/hbase.txt
	echo "start server ..." >> /home/tyx/hbase.txt
	#cd /longwen/server/sbin/linux; ./WorldFrame_d -c 1
	cd $HBASE_HOME/bin; sh ./start-hbase.sh
else 
	echo `date` >> /home/tyx/hbase.txt
	echo "I am good  ..." >> /home/tyx/hbase.txt
fi
