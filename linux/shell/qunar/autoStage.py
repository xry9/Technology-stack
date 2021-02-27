#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os, sys, time, getopt, datetime
print(sys.path)
from time import strftime,localtime
import dateutil,db,dbutil,fileutil
from util import *
argv_dic={}
argv_dic=getAgrParam(sys.argv)

hive_conn = db.Db(argv_dic['db_conn']) 
tgt_table = argv_dic['table']
all_columns = ''
dt_key = argv_dic['dt_key']
update_key = argv_dic['update_key']
unique_keys = argv_dic['unique_keys']

def merge(tgt_table,src_table,delta):
    
    start_dt = dateutil.getPreDate(argv_dic['end_date'], delta)
    date_range = dateutil.getPreDate(start_dt,argv_dic['date_rank'])
    end_date = dateutil.getPreDate(argv_dic['end_date'], -1)
    sql='''
        insert overwrite table stage.%(tgt_table)s partition(dt)
        select
            %(all_columns)s,
            regexp_replace(substr(%(dt_key)s,1,10),'-','') as dt
        from (
          select  
            %(all_columns)s,
            row_number() over (partition by %(unique_keys)s order by %(update_key)s desc,b.dt desc) as rank_value
          from(
            select 
              %(all_columns)s
              ,dt
            from stage.%(tgt_table)s
            where dt >= '%(date_range)s' and dt<='%(end_date)s'
            union all
            select 
              %(all_columns)s
              ,dt
            from ods.%(src_table)s
            where dt>='%(start_dt)s'
              and regexp_replace(substr(%(dt_key)s,1,10),'-','') >= '%(date_range)s' and regexp_replace(substr(%(dt_key)s,1,10),'-','')<='%(end_date)s'
          ) b
        ) a
        where rank_value=1
        distribute by dt
    '''%{'all_columns':all_columns,'dt_key':dt_key,'unique_keys':unique_keys,'update_key':update_key,'tgt_table':tgt_table,'src_table':src_table,'date_range':date_range,'end_date':end_date,'start_dt':start_dt}
#    print 'merge sql:',sql
    hive_conn.execute(sql)

def init_table(tgt_table,src_table,type=''):
    if type=='cleanup':
        sql_drop='drop table if exists stage.%s'%(tgt_table)
        hive_conn.execute(sql_drop)
        sql = '''
            create table stage.%(tgt_table)s
			like ods.%(src_table)s
            '''%{'tgt_table':tgt_table,'src_table':src_table}
        #print sql
        hive_conn.execute(sql)

        sql_orc='alter table stage.%s set fileformat orc'%(tgt_table)
        hive_conn.execute(sql_orc)
    sql='''
        insert overwrite table stage.%(tgt_table)s partition(dt)
        select
            %(all_columns)s,
            regexp_replace(substr(%(dt_key)s,1,10),'-','') as dt
        from(
            select 
              %(all_columns)s,
              row_number() over (partition by %(unique_keys)s order by %(update_key)s desc,dt desc) as rank_value
            from ods.%(src_table)s
        ) a
        where a.rank_value=1
        distribute by dt
        '''%{'tgt_table':tgt_table,'src_table':src_table,'all_columns':all_columns,'dt_key':dt_key,'unique_keys':unique_keys,'update_key':update_key}
    #print sql
    hive_conn.execute(sql)

def get_ods_columns(src_table):
    sql='''
       desc ods.%(src_table)s
       '''%{'src_table':src_table}
    global all_columns
    ret = hive_conn.query(sql)
    clist =[];
    for k,v in enumerate(ret):
	if v[0] =='dt':
	    break
	v[0] = '%s%s%s' % ('`', v[0], '`')
	clist.append(v[0])
    all_columns=','.join(clist)
    print all_columns


if __name__ == "__main__":
    src_table='ods_'+tgt_table[3:]

    setHiveDynamicPartition(hive_conn)
    setHiveCompress(hive_conn,'orc')
    
    setHiveMapReduceMemory(hive_conn,8192)
    get_ods_columns(src_table)

    if argv_dic.has_key('reload'):
        c_type=''
        if argv_dic.has_key('cleanup') and argv_dic.has_key('cleanup')==1:
            c_type='cleanup'
        init_table(tgt_table,src_table,c_type)
    elif argv_dic.has_key('delta') and argv_dic.has_key('delta')>0:
        merge(tgt_table,src_table,int(argv_dic['delta']))
    hive_conn.close()
    print time.strftime("%Y-%m-%d %X",time.localtime()) + " complete"


