#!/bin/sh
set -e
source /etc/profile

_mobiles="18611427353,15210645015,18810019014,18811445785,15510581695,18600527468"
restart_server(){
#id、用户名、路径、端口号
_id=$1
_port=$2
_username=$3
_hive_path=$4
_server_type=$5
# _hostname参数 只有启动spark时会用到
_hostname=$6
echo ${_id} == ${_port} == ${_username} == ${_hive_path} == ${_server_type}  == ${_hostname}

#if [ -n "${_data}" ]; then 

  echo $(date +"%Y-%m-%d %H:%M:%S") " ${_local_ip}:${_port} ${_server_type}链接不上，尝试重启"

  #_pid=$(ps -ef|grep "HiveServer2"|grep -v "grep"|awk '{print $2}')
  _pid=$(sudo netstat -tpnl |grep ${_port}| awk '{print $7}')
  _pid=${_pid%/java}
  if [ -n "${_pid}" ]; then
    echo $(date +"%Y-%m-%d %H:%M:%S") "  杀掉进程${_pid}"
    sudo kill -9 ${_pid}
  fi
  
  sleep 1s
  if [ "${_server_type}" == "hive" ]; then 
    echo $(date +"%Y-%m-%d %H:%M:%S") "  执行启动命令:cd ${_hive_path};nohup sudo -u${_username} HIVE_SERVER2_THRIFT_PORT=${_port} ${_hive_path}/bin/hive --service hiveserver2 &"
    cd ${_hive_path}
    nohup sudo -u${_username} HIVE_SERVER2_THRIFT_PORT=${_port} ${_hive_path}/bin/hive --service hiveserver2 &
  elif [ "${_server_type}" == "metastore" ]; then
    echo $(date +"%Y-%m-%d %H:%M:%S") "  执行启动命令:cd ${_hive_path};nohup sudo -u${_username} METASTORE_PORT=${_port} ${_hive_path}/bin/hive --service metastore &"
    cd ${_hive_path}
    sudo -u ${_username} METASTORE_PORT=${_port} ${_hive_path}/bin/hive --service metastore &
  elif [ "${_server_type}" == "spark" ]; then
      echo "sudo -u ${_username} HIVE_SERVER2_THRIFT_PORT=${_port} ${_hive_path}/sbin/start-thriftserver.sh --name sparkserver.${_hostname} --master yarn-client --executor-memory 14G --num-executors 40 --driver-memory 10G "

      cd ${_hive_path}
      sudo -u ${_username} HIVE_SERVER2_THRIFT_PORT=${_port} ${_hive_path}/sbin/start-thriftserver.sh --name sparkserver.bidb1.f.cn2 --master yarn-client --executor-memory 14G --num-executors 40 --driver-memory 10G
  fi
  
  # 循环120次，每次阻塞1s，判断进程是否真正启动，如果启动则break ，120s后仍不能启动则报警
  for((i=1;i<=120;i++))
  do
    #_process_num=$(ps -ef|grep HiveServer2|grep -v grep|wc -l)
    _process_num=$(sudo netstat -tpnl |grep ${_port}| awk '{print $7}'|wc -l)
    if [ "${_process_num}" -eq "1" ]; then
      _message="[$(date +"%Y-%m-%d %H:%M:%S")] ${_local_ip}:${_port} ${_server_type}重启成功"
      mysql -h'l-dw1.f.cn5' -u'f_qmd_w' -p'dmF8GK0HxYoR3I5t' --default-character-set=utf8 -Df_check -N -e"
        update hive_server_check set result=1 where id='${_id}'
      "
      echo ${_message}
      break
    elif [ ${i} -eq 120 ]; then
      _message="[$(date +"%Y-%m-%d %H:%M:%S")] ${_local_ip}:${_port} ${_server_type}重启失败"
      echo "http://schedule.flightdata.corp.qunar.com/api/alert/sendSms?mobiles=${_mobiles}&message=${_message}&source=test"
      curl -d "mobiles=${_mobiles}&message=${_message}&source=test" "http://schedule.flightdata.corp.qunar.com/api/alert/sendSms"
    else
      echo "${_server_type} ${_port} sleep 第 ${i}s"
      sleep 1s
    fi
  done
 
#fi
}

_local_ip=$(/sbin/ifconfig -a |grep "inet addr"|grep -v "127.0.0.1" |awk '{print $2}'|tr -d "addr:")
if [ -n "${_local_ip}" ]; then
  echo ${_local_ip}
else
  _local_ip=$(/sbin/ifconfig -a |grep "inet"|grep -v "127.0.0.1" |awk '{print $2}'|tr -d "[a-z][A-Z]|:")
fi

_data=$(mysql -h'l-dw1.f.cn5' -u'f_qmd_w' -p'dmF8GK0HxYoR3I5t' --default-character-set=utf8 -Df_check -N -e"select CONCAT_WS(',',id,port,username,hive_path,server_type,hostname) from hive_server_check where host='${_local_ip}' and result=0")

array=(${_data})
for line in ${array[@]}
do
  arr=(${line//,/ })
  _id=${arr[0]}
  _port=${arr[1]}
  _username=${arr[2]}
  _hive_path=${arr[3]}
  _server_type=${arr[4]}
  # _hostname参数 只有启动spark时会用到
  _hostname=${arr[5]}
  restart_server ${_id} ${_port} ${_username} ${_hive_path} ${_server_type} ${_hostname} &
done
wait
#restart_server "metastore"
exit 0
