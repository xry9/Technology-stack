#!/usr/bin/env python
# -*- coding: utf-8 -*-
# hive util with hive server2
import sys,json,os,subprocess,datetime,time
import db
import re
from impala.dbapi import connect
from db import dbconfig

# sudo -uhadoop /home/q/hadoop-2.5.0-cdh5.2.0/bin/hdfs dfs -chmod -R 777 hdfs://flightdata:8020/user/hadoop/hive/warehouse/qlibra.db
#dbconfig.configs['impala_kudu'] = {'type':'hive','host':'l-spark3.f.cn5.qunar.com','username':'','password':'','encoding':'utf8','port':'21050','database':'impala_kudu','hadoop_path':'/home/q/hadoop-2.5.0-cdh5.2.0','hive_path':'/home/q/hive/apache-hive-1.0.0-bin/bin/hive'}
default_encoding = 'utf-8'

#参数传入方法 key=value
def getArgParam(arg_list):
    arg_dic = {}
    current_date = datetime.datetime.now()
    start_date_default = (current_date-datetime.timedelta(days=1)).strftime("%Y%m%d")
    end_date_default = (current_date-datetime.timedelta(days=1)).strftime("%Y%m%d")
    if len(arg_list) >= 1:
        for i in xrange(len(arg_list)):
            if i == 0:
                continue
            arg_key_value = arg_list[i].split('=')
            arg_key = arg_key_value[0]
            arg_value = arg_key_value[1]
            arg_dic[arg_key] = arg_value
        if not arg_dic.has_key('startDate'):
            arg_dic['startDate'] = start_date_default
        if not arg_dic.has_key('endDate'):
            arg_dic['endDate'] = end_date_default
    else:
        print 'args not enough!'
        sys.exit(1)
    return arg_dic

def runShell(cmd):
    print(cmd)
    handle = subprocess.call(cmd,shell=True)
    if handle:
        print cmd +': failed'
        sys.exit(1)

big_hive = db.Db("big_hive")
small_hive = db.Db("hive_stage")
#impala_kudu = db.Db("impala_kudu")

def kudu2small_hive_qlibra(tableName,day):
    conn=connect(host='l-spark3.f.cn5.qunar.com',port=21050,timeout=3600)
    ETLSQL='show create table impala_kudu.%s' % tableName
    cur=conn.cursor()
    cur.execute(ETLSQL)
    SQL=''
    meta=[]
    createSQL='create table if not exists qlibra.%s_parquet ( \n' % tableName
    for row in cur:
        for col in row:
            SQL=col

    columns=re.findall('.* NULL',SQL)
    for column in columns:
        if 'day INT' in column:
            continue
        column=column.replace('NOT','').replace('NULL','')
        meta.append(column.strip().split(' ')[0])
        createSQL+=column+',\n'
    createSQL=createSQL[:-2]
    createSQL+=' \n) \n PARTITIONED BY (day int) STORED as PARQUET'
    print(createSQL)

    columnsByTableChanged=getColumnsByTableChanged(tableName)

    if len(columnsByTableChanged)>0:
        print('Table columns changed : %s' % tableName )
        for column in columnsByTableChanged:
            ALTER_SQL='alter table qlibra.%s_parquet add columns (%s %s)' % (tableName,column[0],column[1])
            print(ALTER_SQL)
            small_hive.execute(ALTER_SQL)
            big_hive.execute(ALTER_SQL)
    else:
        small_hive.execute(createSQL)
        big_hive.execute(createSQL) 
    cur.execute('INVALIDATE METADATA qlibra.%s_parquet' % tableName )

     # 文件权限
    cmd='sudo -uhadoop /home/q/hadoop-2.5.0-cdh5.2.0/bin/hdfs dfs -chmod -R 777 hdfs://flightdata:8020/user/hadoop/hive/warehouse/qlibra.db/%s_parquet' %(tableName)
    runShell(cmd)

    cols=','.join(meta)
    ETLSQL=('insert overwrite qlibra.%s_parquet partition(day=%d) select '+cols+' from impala_kudu.%s where day=%d') % (tableName,day,tableName,day)
    cur.execute(ETLSQL)
    cur.execute('INVALIDATE METADATA qlibra.%s_parquet' % tableName )
    conn.close()

def distcp_small2big(tableName,day,dt):
     
     cmd = '''sudo -uflightdev /home/q/hadoop-2.2.0/bin/hadoop distcp -overwrite -i \
            hdfs://flightdata:8020/user/hadoop/hive/warehouse/qlibra.db/%s_parquet/day=%d   \
            hdfs://qunarcluster:8020/user/flightdev/hive/warehouse/qlibra.db/%s_parquet/day=%s ''' % (tableName,day,tableName,dt)
     runShell(cmd)
     big_hive.execute('alter table qlibra.%s_parquet add if not exists partition(day=%s)' % (tableName,dt))

# 获取变化的字段名,目前仅支持新增
def getColumnsByTableChanged(tableName):
        EXESQL='''show tables from qlibra like '%s_parquet' ''' % tableName
        tables=small_hive_execute(EXESQL)
        if len(tables)==1 and tables[0]!='%s_parquet' % tableName:
            return []
        #EXESQL='show columns in %s from impala_kudu ' % tableName
        EXESQL='desc impala_kudu.%s' % tableName
        meta_kudu=small_hive.query(EXESQL)
        #EXESQL='show columns in %s_parquet from qlibra ' % tableName
        EXESQL='desc qlibra.%s_parquet' % tableName
        meta_qlibra=small_hive.query(EXESQL)
        meta_qlibra_column_name_set=[]
        for i in xrange (0,len(meta_qlibra)):
            if meta_qlibra[i][1]==None:
                break
	    meta_qlibra_column_name_set.append(meta_qlibra[i][0])
		               
        if len(meta_kudu)==len(meta_qlibra_column_name_set):
            return []
        else:
            result=[]
            for x in meta_kudu:
                if not x[0] in meta_qlibra_column_name_set:
                    result.append(x)
        print(result)
        return result

def small_hive_execute(EXESQL):
        cursor=small_hive.getCursor()
        meta=[]
        try:
            cursor.execute(EXESQL)
            for row in cursor:
                for col in row:
                    meta.append(col) 
        except Exception, e:
            raise e
        finally:
            cursor.close()
        return meta
    
if __name__ == '__main__':
    argv_dic=getArgParam(sys.argv)
    if not argv_dic.has_key('kuduTable'):
        print('args must kuduTable eg. event_self_query')
        sys.exit(1)
    begin=datetime.datetime.strptime(argv_dic['startDate'],'%Y%m%d')
    end=datetime.datetime.strptime(argv_dic['endDate'],'%Y%m%d')
    d1970=datetime.datetime(1970, 01, 01)
   
    while begin<=end:
        dt=datetime.datetime.strftime(begin,'%Y%m%d')
        day=(begin-d1970).days
        tableName=argv_dic['kuduTable']
        print('exeDate:%s,kuduTable=%s,days=%s' % (dt,tableName,day))
        kudu2small_hive_qlibra(tableName,day)
        distcp_small2big(tableName,day,dt)
        begin=begin+datetime.timedelta(days = 1)
    
    big_hive.close() 
    small_hive.close()
