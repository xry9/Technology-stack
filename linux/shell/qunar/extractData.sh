#!/bin/bash

ARGS=$(getopt -q d:b:t:e: "$@")

[ $? -ne 0 ] && exit 1

eval set -- "$ARGS"

while true 
do
   case $1 in
        -"d")
          inputdate=$2
          shift
        ;;
        -"t")
          table_name=$2
          shift
        ;;
        -"b")
          business_type=$2
          shift
        ;;
        -"e")
          errorAgain=$2
          shift
        ;;
        --)
         shift
         break
       ;;
    esac
 shift
done

echo $table_name
echo $business_type
echo $inputdate
echo $errorAgain

if [[ $table_name == "" ]];then
   echo "$sysTime Table Name Is Not Exists ........." 
   exit 1
fi

if [[ $business_type == "" ]];then
   echo "$sysTime Business Type Is Not Exists ........." 
   exit 1
fi

if [[ $inputdate == "" ]];then
   echo "$sysTime date Is Not Exists ........." 
   exit 1
fi

lengid=`echo $inputdate | wc -L`

if [[ $lengid == "17" ]];then
    days=$(date +'%Y-%m-%d' -d "$inputdate 0 day")
    second=$(date +%H:%M:%S -d "$inputdate 0 day")
    pumpdate=$days"%20"$second
else
    pumpdate=$(date +%Y-%m-%d -d "$inputdate -1 day")
fi

slaveInfo="127.0.0.1:9896"

echo "ETL Action Beginning ......:
http://$slaveInfo/etlManager/getDataFromMysql.do?date=$pumpdate&tables=$table_name&businesstype=$business_type&isErrorAgain=$errorAgain"

res=`curl "http://$slaveInfo/etlManager/getDataFromMysql.do?date=$pumpdate&tables=$table_name&businesstype=$business_type&isErrorAgain=$errorAgain"`

if [[ $res != "true" ]];then
   echo " Extract Transform Load Error ...... Exit" $currDate [StartTime]:$StartTime  [FinishTime]:$(date -d "today" '+%H:%M:%S')
   exit 1
fi
