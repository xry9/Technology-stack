#bin/bash
file=`date "+%Y-%m-%d" --date="-1 day"`
dir=/home/fengkai/test/${file}/log
log=`grep "error" ${dir} -i -n`
#echo $log
if [ "${log}" ];then
echo ${log} |mailx -s "${dir}" weimengle@zhanghetianxia.com
fi
