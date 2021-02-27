#!/bin/sh
source /etc/profile
set -e


_local_ip=$(/sbin/ifconfig -a |grep "inet addr"|grep -v "127.0.0.1" |awk '{print $2}'|tr -d "addr:")
_mobiles="15210645015,18810019014,18811445785"

_port=""
_username=""
_hive_path=""


restart_server(){
    _server_type=$1
    _sql="select port,username,hive_path,server_name from hive_server_check where host='${_local_ip}' and server_type='${_server_type}' and valid=1 and result=0"
    echo "${_sql}"
    _data=$(mysql -h'l-dw1.f.cn5' -u'f_qmd_w' -p'dmF8GK0HxYoR3I5t' --default-character-set=utf8 -Df_check -N -e" ${_sql} ")
    #查出用户名、路径、端口号
    _port=$(echo ${_data} | awk '{print $1}')
    _username=$(echo ${_data} | awk '{print $2}')
    _hive_path=$(echo ${_data} | awk '{print $3}')
    _server_name=$(echo ${_data} | awk '{print $4}')

  if [ -n "${_data}" ]; then 

    echo $(date +"%Y-%m-%d %H:%M:%S") " ${_local_ip}:${_port} ${_server_name} 链接不上，尝试重启"

    _pid=$(ps -ef|grep "${_server_name}"|grep -v "grep"|awk '{print $2}')

    if [ -n "${_pid}" ]; then
      echo $(date +"%Y-%m-%d %H:%M:%S") "  杀掉进程${_pid}"
      sudo kill -9 ${_pid}
    fi
  
    sleep 1s

    ###########启动命令#######################
    if [ "${_server_type}" == "hive" ]; then
      echo $(date +"%Y-%m-%d %H:%M:%S") "  执行启动命令:cd ${_hive_path};nohup sudo -u${_username} HIVE_SERVER2_THRIFT_PORT=${_port} ${_hive_path}/bin/hive --service hiveserver2 &"

      cd ${_hive_path}
      nohup sudo -u${_username} HIVE_SERVER2_THRIFT_PORT=${_port} ${_hive_path}/bin/hive --service hiveserver2 &

    else
      echo "sudo -u ${_username} HIVE_SERVER2_THRIFT_PORT=${_port} ${_hive_path}/sbin/start-thriftserver.sh --name sparkserver.bidb1.f.cn2 --master yarn-client --executor-memory 14G --num-executors 40 --driver-memory 10G "
      
      cd ${_hive_path}
      sudo -u ${_username} HIVE_SERVER2_THRIFT_PORT=${_port} ${_hive_path}/sbin/start-thriftserver.sh --name sparkserver.bidb1.f.cn2 --master yarn-client --executor-memory 14G --num-executors 40 --driver-memory 10G
    fi
    ############启动命令#######################

    #等待10秒之后，查看进程是否还在
    sleep 5s
    _process_num=$(ps -ef|grep ${_server_name}|grep -v grep|wc -l)   
    _message="[$(date +"%Y-%m-%d %H:%M:%S")] ${_local_ip}:${_port} ${_server_type}重启失败"

    if [ "${_process_num}" -eq "1" ]; then
      _message="[$(date +"%Y-%m-%d %H:%M:%S")] ${_local_ip}:${_port} ${_server_type}重启成功"
      mysql -h'l-dw1.f.cn5' -u'f_qmd_w' -p'dmF8GK0HxYoR3I5t' --default-character-set=utf8 -Df_check -N -e"
        update hive_server_check set result=1 where host='${_local_ip}' and server_type='${_server_type}' and valid=1 and result=0
      "
    else
      echo "http://schedule.flightdata.corp.qunar.com/api/alert/sendSms?mobiles=${_mobiles}&message=${_message}&source=test"
      curl -d "mobiles=${_mobiles}&message=${_message}&source=test" "http://schedule.flightdata.corp.qunar.com/api/alert/sendSms"
    fi
  else
    echo $(date +"%Y-%m-%d %H:%M:%S") " ${_local_ip} ${_server_type}未发现异常"
  fi       

}


restart_server "hive"
restart_server "spark"
restart_server "metastore"

echo "restart complete"
exit 0
