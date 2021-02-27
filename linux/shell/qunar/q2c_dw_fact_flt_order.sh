#加入行程单地址
#!/bin/sh
set -e

#引入公共脚本
source /home/q/script/utils.sh $@

#获取变量，如果公共脚本中没有定义，需要定义
hive_user=${hive_user}
_day=${day}
_reload=${reload}

if [ ! -n "${_day}" ]; then
  _day=$(date +"%Y%m%d")
fi
start_dt=$(date -d"${_day} 365 days ago" +"%Y%m%d")
start_last_dt=$(date -d"${_day} 365 days ago" +"%Y%m%d")
end_dt=$(date +"%Y%m%d")

#start_dt=20170101
#end_dt=20170605

start_c_dt=$(date -d"${start_dt} 10 days ago" +"%Y%m%d")
end_c_dt=$(date -d"${end_dt} 10 days" +"%Y%m%d")

start_date=$(date -d"${start_dt}" +"%Y-%m-%d")
end_date=$(date -d"${end_dt}" +"%Y-%m-%d")

table_name="dw_fact_flt_order_q2c"
db_name="qc"

_directory="/home/q/script/datawarehouse/report/data/${table_name}"
_filepath="${_directory}/${table_name}.txt"
_directory_new="${_directory}/${table_name}_order_info"

if [ ! -d ${_directory} ];then
    sudo -uhadoop mkdir ${_directory}
    sudo -uhadoop mkdir ${_directory_new}
fi

_create_sql="
drop table if exists ${db_name}.${table_name};
create table ${db_name}.${table_name}(
  order_no  string,
  share_order_no string,
  flight_type  int,
  dom_inter  int,
  agent_name  string,
  agent_domain  string,
  source  string,
  business_type  string,
  has_xcd  int,
  has_express  int,
  qunar_username  string,
  total_price  double,
  adult_tax  double,
  child_tax double,
  express_price  double,
  flight_size  int,
  passenger_count  int,
  create_time  string,
  status  string,
  pay_ok  int,
  is_ticket_success  int,
  ip  string,
  ticket_time  string,
  pay_time  string,
  contact_name  string,
  contact_mob  string,
  contact_city  string,
  ip_city  string,
  child_count  int,
  adult_count  int,
  total_naked_ticket_price  double,
  total_ticket_price  double,
  add_price  double,
  adult_price  double,
  child_price  double,
  distribute_type  string,
  address string,
  address_src string,
  last_updated string,
  contact_mobile_sha256 string
)
partitioned by (dt string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS ORC
"


if [ -n "${_reload}" ]; then
  echo "${_create_sql}"
  sudo -u ${hive_user} hive -e"
    ${_create_sql}
  "
fi

sql=" 
  SET mapreduce.reduce.memory.mb=8192;
  SET mapreduce.reduce.java.opts='-Xmx8192M';
  SET mapreduce.map.memory.mb=4096;
  SET mapreduce.map.java.opts='-Xmx3900M';
  SET mapred.child.map.java.opts='-Xmx3900M';
  SET mapreduce.job.name=${db_name}.${table_name}.mandy.zhu;
  set hive.exec.dynamic.partition=true;
  set hive.exec.dynamic.partition.mode=nonstrict;
  SET hive.exec.max.dynamic.partitions=100000;
  SET hive.exec.max.dynamic.partitions.pernode=100000;
  add jar /home/q/script/datawarehouse/report/q2c_dw_fact_flt/data_deal.jar;
  create temporary function getdata as 'hive.udf.AESUtil';
  
  insert overwrite table ${db_name}.${table_name} partition(dt)
  select 
    a.order_no,
    COALESCE(g.ctrip_order_no,h.ctrip_order_no,j.ctrip_order_no,i.ctrip_order_no,k.ctrip_order_no) as share_order_no,
    flight_type,
    dom_inter,
    b.company_name as agent_name,
    agent_domain,
    case 
      when source like '%touch%' then 'touch' 
      when source like '%android%' then 'adr'
      when source like '%iphone%' then 'ios' 
      else 'www' 
    end as source,
    a.business_type,
    has_xcd,
    has_express,
    qunar_username,
    total_price,
    adult_tax,
    child_tax,
    express_price,
    flight_size,
    passenger_count,
    create_time,
    f.ctrip_status as status,
    a.pay_ok,
    a.is_ticket_success,
    ip,
    ticket_time,
    pay_time,
    contact_name,
    c.qctransform_phone as contact_mob,
    m.city as contact_city,
    d.city as ip_city,
    child_count,
    adult_count,
    total_naked_ticket_price,
    total_ticket_price,
    add_price,
    adult_price,
    child_price,
    distribute_type,
    case 
      when COALESCE(e.address,o.address,p.address) is null then null 
      else getdata(COALESCE(e.address,o.address,p.address),1)
    end as address,
    COALESCE(e.address,o.address,p.address) as address_src,
    last_updated,
    m.contact_mobile_sha256 as contact_mobile_sha256,
    a.dt
  from(
    select 
      order_no,
      flight_type,
      dom_inter,
      wrapper_id,
      agent_domain,
      source,
      business_type,
      has_xcd,
      has_express,
      qunar_username,
      total_price,
      adult_tax,
      child_tax,
      express_price,
      flight_size,
      passenger_count,
      create_time,
      status,
      type,
      pay_ok,
      is_ticket_success,
      ip,
      ticket_time,
      pay_time,
      contact_name,
      contact_mob,
      child_count,
      adult_count,
      total_naked_ticket_price,
      total_ticket_price,
      add_price,
      adult_price,
      child_price,
      distribute_type,
      last_updated,
      db_host,
      db_name,
      order_id,
      main_order_no,
      dt
    from f_wide.wide_order
    where dt>='${start_dt}' and dt<'${end_dt}'
  ) a
  left join dim.dim_order_status1 f on a.type=f.business_type and a.status=f.status
  left join (select company_name,domain from dim.dim_wrapper where domain is not null and domain not in ('','null','NULL') group by company_name,domain) b on a.agent_domain=b.domain
  left join user.user_qcTransform_phone c on a.contact_mob=c.contact_mobile
  left join dim.dim_contact_mobile_info m on a.contact_mob=m.contact_mobile
  left join dim.dim_client_ip d on (if(a.ip is null or a.ip='null',rand(),a.ip)=d.client_ip)
  left join(
    select 
      regexp_replace(address,' ','') as address,
      order_no
    from stage.sg_express_domestictts
    where dt>='${start_c_dt}' and dt<'${end_c_dt}' and address is not null and address!='' and address!='null'
  ) e on a.order_no=e.order_no
  left join(
    select 
      biz_order_no,
      regexp_replace(
        concat(
          get_json_object(product_info_json,'$.province'),
          get_json_object(product_info_json,'$.city'),
          get_json_object(product_info_json,'$.restrict'),
          get_json_object(product_info_json,'$.addressReminder')
        ),' ',''
      ) as address
    from stage.sg_product_info_fuwuorderpool
    where dt>='${start_c_dt}' and dt<'${end_c_dt}' 
  ) o on (a.order_no=o.biz_order_no and o.address<>'')
  left join(
    select 
      biz_order_no,
      regexp_replace(
        concat(
          get_json_object(product_info_json,'$.province'),
          get_json_object(product_info_json,'$.city'),
          get_json_object(product_info_json,'$.restrict'),
          get_json_object(product_info_json,'$.addressReminder')
        ),' ',''
      ) as address
    from stage.sg_product_info_fuwuorderpool
    where dt>='${start_c_dt}' and dt<'${end_c_dt}' 
  ) p on (if(a.main_order_no is null or a.main_order_no='',rand(),a.main_order_no)=p.biz_order_no and o.address<>'')
  left join(
    select 
      a.qnc_order_no,
      b.ctrip_order_no
    from stage.sg_f_n_order_info_domestictts a
    join stage.sg_order_info_pifa_ctrip_domestic_direct b on a.order_no=b.tts_order_no
    where b.ctrip_order_no is not null and b.ctrip_order_no !='' and b.ctrip_order_no!='null' 
      and a.dt>='${start_c_dt}' and a.dt<'${end_c_dt}' and b.dt>='${start_c_dt}' and b.dt<'${end_c_dt}'
  ) g on a.order_no=g.qnc_order_no
  left join (
    select 
      tts_order_no,
      ctrip_order_no
    from stage.sg_order_info_pifa_tts_ctrip_domestic_direct
    where ctrip_order_no is not null and ctrip_order_no !='' and ctrip_order_no!='null' and dt>='${start_c_dt}' and dt<'${end_c_dt}'
  ) h on a.order_no=h.tts_order_no
  left join(
    select 
      l.order_no,
      j.ctrip_order_no
    from(
      select 
        out_order_no as ctrip_order_no,
        tts_order_no
      from stage.sg_order_info_f_b2b_ctrip_direct2itts
      where out_order_no is not null and out_order_no !='' and out_order_no!='null' and dt>='${start_c_dt}' and dt<'${end_c_dt}'
    ) j
    join(
      select 
        a.order_no,
        b.dispatch_order_no
      from stage.sg_ticket_order_pangolinticket a
      left join stage.sg_dispatch_order_pangolinticket b on a.task_no=b.task_no
      where a.dt>='${start_c_dt}' and a.dt<'${end_c_dt}' and b.dt>='${start_c_dt}' and b.dt<'${end_c_dt}'
    ) l on j.tts_order_no=l.dispatch_order_no
  ) j on a.order_no=j.order_no
  left join(
    select 
      a.qunar_order_no,
      b.order_no as ctrip_order_no
    from 
      stage.sg_adapter_order_info_ittsadapter a
    join stage.sg_sub_order_info_ittsadapter b on a.id=b.order_id 
    where a.dt>='${start_c_dt}' and a.dt<'${end_c_dt}' and b.dt>='${start_c_dt}' and b.dt<'${end_c_dt}'
  ) i on a.order_no=i.qunar_order_no
  left join(
    select 
      order_id,
      db_host,
      db_name,
      order_no as ctrip_order_no
    from stage.sg_flight_order_interflight
    where db_name='tfair' and dt>='${start_c_dt}' and dt<'${end_c_dt}'
  ) k on a.db_host=k.db_host and a.db_name=k.db_name and a.order_id=k.order_id
  distribute by a.dt;
"

echo "${sql}"

sudo -u ${hive_user} hive -e "${sql}"
#sudo -u flightbigdata  spark-sql --master yarn-client --conf spark.yarn.queue=flightbigdata --name spark_dw_fact_flt_order_q2c.mandy.zhu --executor-memory 7G --num-executors 40 -e"
#  ${sql}
#"

###########当日新增和更新的数据############
get_data(){
  sql="
  SET mapreduce.reduce.memory.mb=8192;
  SET mapreduce.reduce.java.opts='-Xmx8192M';
  SET mapreduce.map.memory.mb=8192;
  SET mapreduce.map.java.opts='-Xmx900M';
  SET mapred.child.map.java.opts='-Xmx1024M';
  SET mapreduce.job.name=${db_name}.${table_name}.mandy.zhu;
  set hive.auto.convert.join=false;
  select
    order_no,
    share_order_no,
    flight_type,
    dom_inter,
    agent_name,
    agent_domain,
    source,
    business_type,
    has_xcd,
    has_express,
    qunar_username,
    total_price,
    adult_tax,
    child_tax,
    express_price,
    flight_size,
    passenger_count,
    create_time,
    status,
    pay_ok,
    is_ticket_success,
    ip,
    ticket_time,
    pay_time,
    contact_name,
    contact_mob,
    contact_city,
    ip_city,
    child_count,
    adult_count,
    total_naked_ticket_price,
    total_ticket_price,
    add_price,
    adult_price,
    child_price,
    distribute_type,
    address,
    substr(last_updated,0,10) as last_updated,
    contact_mobile_sha256,
    dt
  from ${db_name}.${table_name}
  where dt='$1'
  union
  select 
    order_no,
    share_order_no,
    flight_type,
    dom_inter,
    agent_name,
    agent_domain,
    source,
    business_type,
    has_xcd,
    has_express,
    qunar_username,
    total_price,
    adult_tax,
    child_tax,
    express_price,
    flight_size,
    passenger_count,
    create_time,
    status,
    pay_ok,
    is_ticket_success,
    ip,
    ticket_time,
    pay_time,
    contact_name,
    contact_mob,
    contact_city,
    ip_city,
    child_count,
    adult_count,
    total_naked_ticket_price,
    total_ticket_price,
    add_price,
    adult_price,
    child_price,
    distribute_type,
    address,
    substr(last_updated,0,10) as last_updated,
    contact_mobile_sha256,
    dt
  from ${db_name}.${table_name}
  where dt>='$2' and regexp_replace(substr(last_updated,1,10),'-','')='$1' and dt!='$1'
  "

  echo "${sql}"

  sudo -u${hive_user} hive -e "${sql}">${_directory_new}/${1:0:4}-${1:4:2}-${1:6:2}
}

sudo rm -f ${_directory_new}/*

#cur_dt=$start_dt
cur_dt=$(date -d"${end_dt} 1 days ago" +"%Y%m%d")

while [ $cur_dt -lt $end_dt ]
do
    start_last_dt=$(date -d"${cur_dt} 90 days ago" +"%Y%m%d")
    get_data $cur_dt $start_last_dt
    cur_dt=`date +%Y%m%d -d "$cur_dt 1 days"`
done


_filename_news=$(sudo ls ${_directory_new}/)
cd ${_directory_new}
for _filename_new in ${_filename_news}
do
  #echo ${_filename_new}
  file_name=${_filename_new:0-10}
  echo ${file_name}
  sudo rm -f dw_factfltorder_increment-${file_name}.gz
  sudo rm -f dw_factfltorder_increment-${file_name}.gz.md5
  
  sudo gzip -c ${file_name} > dw_factfltorder_increment-${file_name}.gz
  sudo md5sum dw_factfltorder_increment-${file_name}.gz | awk -F" " '{print $1}'> dw_factfltorder_increment-${file_name}.gz.md5
  set +e
  sudo -u${hive_user} /home/q/hadoop-2.2.0/bin/hadoop dfs -rm -r /cqedata/cqedataflight/qunar/dw_factfltorder_increment/${file_name}
  set -e
  sudo -u${hive_user} /home/q/hadoop-2.2.0/bin/hadoop dfs -mkdir /cqedata/cqedataflight/qunar/dw_factfltorder_increment/${file_name}
  sudo -u${hive_user} /home/q/hadoop-2.2.0/bin/hadoop dfs -put ./dw_factfltorder_increment-${file_name}.gz.md5 /cqedata/cqedataflight/qunar/dw_factfltorder_increment/${file_name}
  sudo -u${hive_user} /home/q/hadoop-2.2.0/bin/hadoop dfs -put ./dw_factfltorder_increment-${file_name}.gz /cqedata/cqedataflight/qunar/dw_factfltorder_increment/${file_name}
done












