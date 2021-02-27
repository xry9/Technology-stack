#!/bin/bash
set -e

ARGS=$(getopt -q a:p:d:P:G: "$@")
eval set -- "$ARGS"


#sudo ./test.sh -p "root@l-mclt1.ops.cn2::CN2_GLFS_FLIGHT/CN5_f_data_self_query/l-report3.f.cn5/201701/catalina.out.2017-01-16.gz;root@l-mclt1.ops.cn2::CN2_GLFS_FLIGHT/CN5_f_data_self_query/l-report4.f.cn5/201701/catalina.out.2017-01-16.gz" -a "f_data_self_query"

while true
do
   case $1 in
        -"a")
        appcode=$2
        shift
        ;;
        -"p")
        log_path=$2
        shift
        ;;
        -"P")
        password_file_path=$2
        shift
        ;;
        -"d")
        pull_date=$2
        shift
        ;;
        -"G")
        is_direct=$2
        shift
        ;;
        --)
         shift
         break
       ;;
    esac
 shift
done

app_dir="/home/q/script/datawarehouse/logdata/"$pull_date"/"$appcode
if [ -d "$app_dir" ]; then
    echo "删除目录：$rapp_dir"
    rm -rf $app_dir
fi

rsync_prefix="sudo rsync -avPr --password-file="$password_file_path
echo ${rsync_prefix}
rsync_Suffix=$app_dir"/files/"
if [ -d "$rsync_Suffix" ]; then
    echo "删除目录：$rsync_Suffix"
    rm -rf $rsync_Suffix
fi
mkdir -p  "$rsync_Suffix"

log_path_arr=$(echo $log_path|tr ";" "\n")
i=0
exe_res="true"
for var in ${log_path_arr[@]};
do
    set +e
    echo "同步日志命令：sudo rsync -avPr --password-file=$password_file_path $var $rsync_Suffix"
    rsync -avPr --password-file=$password_file_path $var $rsync_Suffix
    if [ $? -ne 0 ]; then
       echo "rsync 执行失败,日志路径：$var"
       exe_res="false"
    fi

#   如果不是直接上传的形式需要解压
    if [ "${is_direct}" != "1" ]; then

        file_name=`echo $var | awk -F '/' '{print $NF}'`
        i=`expr $i + 1`
        touch $rsync_Suffix$file_name"."$i
        chmod 777 $rsync_Suffix$file_name"."$i
        gunzip -c $rsync_Suffix$file_name > $rsync_Suffix$file_name"."$i
        rm -f $rsync_Suffix$file_name

#   如果是直接上传，问了防止不同机器文件重名被覆盖，将文件重命名
    else

        file_name=$(echo $var | awk -F '/' '{print $NF}')
        new_name=$(echo $var | awk -F '/' '{print $3"_"$5}')
        mv ${rsync_Suffix}${file_name} ${rsync_Suffix}${new_name}

    fi

done

if [ $exe_res == "false" ]; then
   echo "程序由于日志文件不存在执行失败！exe_res="$exe_res
   exit 123
fi