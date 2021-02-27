#!/usr/bin/env python
# -*- coding: utf-8 -*-
# hive util with hive server2
import datetime
import os
import sys

import db

default_encoding = 'utf-8'

big_hive = db.Db("big_hive")
small_hive = db.Db("hive_stage")


def doMain(sourceDB, sourceTB, targetDB, targetTB, finalDB, finalTB, startDate, endDate):
    createSQLTemp = getCreateTableSQLTemplate(sourceDB, sourceTB)
    createAndLoadDataToParquetTable(sourceDB, sourceTB, targetDB, targetTB, createSQLTemp, startDate, endDate)
    createSmallCluster(targetDB, targetTB, finalDB, finalTB, createSQLTemp)


def createSmallCluster(sourceDB, sourceTB, targetDB, targetTB, createSQLTemp):
    createParquetTable(createSQLTemp, targetDB, targetTB, False)
    copyDataBTCluster(sourceDB, sourceTB, targetDB, targetTB)
    createPartitions(sourceDB, sourceTB, targetDB, targetTB)


def createAndLoadDataToParquetTable(sourceDB, sourceTB, targetDB, targetTB, createSQLTemp, startDate, endDate):
    createParquetTable(createSQLTemp, targetDB, targetTB, True)
    loadDataToParquetTB(sourceDB, sourceTB, targetDB, targetTB, startDate, endDate)


def createParquetTable(createSQLTemp, targetDB, targetTB, bigCluster):
    createSQL = createSQLTemp.format(targetDB, targetTB)
    print createSQL
    if bigCluster:
        big_hive.execute(createSQL)
    else:
        small_hive.execute(createSQL)
    print "create table done"


def loadDataToParquetTB(sourceDB, sourceTB, targetDB, targetTB, startDate, endDate):
    convertSQL = "set hive.exec.dynamic.partition=true;\n" \
                 + "set hive.exec.dynamic.partition.mode=nonstrict;\n" \
                 + "add jar /home/q/big_hive/udf_custom/f_data_hive_udf-1.0-SNAPSHOT.jar;\n" \
                 + "create temporary function qlib_defalut as 'com.qunar.flight.bigdata.QlibUDTF';\n" \
                 + "insert overwrite table {0}.{1} partition (day) " \
                 + "select " \
                 + "adTable.qlib_id," \
                 + "adTable.qlib_event_id," \
                 + "adTable.qlib_month," \
                 + "adTable.qlib_week," \
                 + "adTable.qlib_time," \
                 + "adTable.qlib_user_id," \
                 + "adTable.qlib_event_bucket," \
                 + "adTable.qlib__lib," \
                 + "adTable.qlib__lib_version," \
                 + "adTable.qlib__app_code," \
                 + "adTable.qlib__app_version," \
                 + "{3}.*," \
                 + "adTable.qlib_day " \
                 + "from {2}.{3} " \
                 + "lateral view qlib_defalut(substr(create_time,0,19),qunar_username,208) adTable as qlib_id,qlib_event_id,qlib_day, qlib_month,qlib_week,qlib_time,qlib_user_id,qlib_event_bucket,qlib__lib,qlib__lib_version,qlib__app_code,qlib__app_version " \
                 + "where dt between '{4}' and '{5}' distribute by qlib_day;"
    convertSQL = convertSQL.format(targetDB, targetTB, sourceDB, sourceTB, startDate, endDate)
    print convertSQL
    big_hive.bash_execute(convertSQL)
    print "load data to table done"


def copyDataBTCluster(sourceDB, sourceTB, targetDB, targetTB):
    chmodcmd = "sudo -uhadoop /home/q/hadoop-2.5.0-cdh5.2.0/bin/hdfs dfs -chmod -R 777 /user/hadoop/hive/warehouse/{0}.db/{1}"
    chmodcmd = chmodcmd.format(targetDB, targetTB)
    print chmodcmd
    os.system(chmodcmd)
    print "start copy data between cluster....."
    cmd = "sudo -uflightdev /home/q/hadoop-2.2.0/bin/hadoop distcp -overwrite -delete -i -m 10 hdfs://qunarcluster:8020/user/flightdev/hive/warehouse/{0}.db/{1}  " \
          "hdfs://flightdata:8020/user/hadoop/hive/warehouse/{2}.db/{3}"
    cmd = cmd.format(sourceDB, sourceTB, targetDB, targetTB)
    print cmd
    status = os.system(cmd)
    if status != 0:
        raise Exception("copy data between cluster error ....")
    print "distcp data from big cluster to small cluster done ....."


def createPartitions(sourceDB, sourceTB, targetDB, targetTB):
    partitions = getPartitions(sourceDB, sourceTB)
    sql = "alter table {0}.{1} add if not exists \n"
    for partition in partitions:
        sql = sql + "partition (" + partition[0] + ") \n"

    sql = sql.format(targetDB, targetTB)
    small_hive.execute(sql)
    print "add partition done ....."


def getPartitions(db, table):
    sql = "show partitions %s.%s" % (db, table)
    print sql
    result = big_hive.query(sql)
    print result
    return result


def getCreateTableSQLTemplate(db, table):
    columnInfos = getColumnsInfos(db, table)
    createSQL = "CREATE TABLE IF NOT EXISTS `{0}.{1}`(\n" + \
                "  `id` string, \n" + \
                "  `event_id` int, \n" + \
                "  `month_id` int, \n" + \
                "  `week_id` int, \n" + \
                "  `time` string, \n" + \
                "  `user_id` string, \n" + \
                "  `event_bucket` int, \n" + \
                "  `p__lib` string,\n" + \
                "  `p__lib_version` string,\n" + \
                "  `p__app_code` string,\n" + \
                "  `p__app_version` string,\n"
    i = 0
    for column in columnInfos:
        i = i + 1
        cname = column['columnName'].replace(table + '.', 'p_')
        ctype = column['type'][:-5]

        createSQL = createSQL + ("  `%s`  %s" % (cname, ctype))
        if i != len(columnInfos):
            createSQL = createSQL + ", \n"
        else:
            createSQL = createSQL + " )\n"

    createSQL = createSQL + "PARTITIONED BY (`day` int) \n" \
                + "STORED AS PARQUET"
    # print createSQL
    return createSQL


def getColumnsInfos(db, table):
    cursor = big_hive.getCursor()
    cursor.execute("select * from %s.%s limit 10" % (db, table))
    columnInfos = cursor.getSchema()
    cursor.close()
    # print columnInfos;
    return columnInfos

def getStartDate(endDate,dayNum):
    startDate = endDate - datetime.timedelta(days=dayNum)
    return startDate

if __name__ == "__main__":
    dayNum = sys.argv[1]
    endDate = datetime.datetime.now()
    startDate = getStartDate(endDate, int(dayNum))

    print dayNum
    print startDate.strftime("%Y%m%d")
    print endDate.strftime("%Y%m%d")

    doMain("f_wide", "wide_order", "qlibra", "event_wide_order_parquet", "qlibra", "event_wide_order_parquet", startDate.strftime("%Y%m%d"), endDate.strftime("%Y%m%d"))
    # getPartitions("test","test_event")
    # createPartitions("test","test_event","test","aaa")
    big_hive.close()
    small_hive.close()






