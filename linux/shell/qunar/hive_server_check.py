#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import sys ,time
import pyhs2
import MySQLdb
import urllib
import urllib2

from hive_service import ThriftHive
from hive_service.ttypes import HiveServerException
from thrift import Thrift
from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol

config = {
    'type':'mysql',
    'host':'l-dw1.f.cn5',
    'username':'f_qmd_w',
    'password':'dmF8GK0HxYoR3I5t',
    'encoding':'utf8',
    'port':'3306',
    'database':'f_check'
}

mobiles = "18611427353,15210645015,18810019014,18811445785,15510581695,18600527468"

def post(url, data):
    req = urllib2.Request(url)
    data = urllib.urlencode(data)
    opener = urllib2.build_opener(urllib2.HTTPCookieProcessor())
    response = opener.open(req, data)
    return response.read()

def testHive(host,port,username,auth,timeout):
    conn = None
    try:
        print "[" + time.strftime("%Y-%m-%d %X",time.localtime()) + "] 访问 %(host)s:%(port)s " % {'host':host,'port':port}
        print auth
        conn = pyhs2.connect(host=host,port=port,authMechanism=auth,user=username,timeout=timeout)
        cur = conn.cursor()
        cur.execute("select 1")
        cur.fetchall()
        return "1"
    except Exception, e:
        print "[" + time.strftime("%Y-%m-%d %X",time.localtime()) + "] %(e)s" % {'e':e}
        return "0"
    finally:
        if conn != None:
            try:
                conn.close()
            except Exception, e:
                print "[" + time.strftime("%Y-%m-%d %X",time.localtime()) + "] %(e)s" % {'e':e}
        print "[" + time.strftime("%Y-%m-%d %X",time.localtime()) + "] 访问 %(host)s:%(port)s 结束" % {'host':host,'port':port}

def testHiveMetaStore(host,port):
    transport = None
    try:
        transport = TSocket.TSocket(host, port)
        transport = TTransport.TBufferedTransport(transport)
        protocol = TBinaryProtocol.TBinaryProtocol(transport)
        client = ThriftHive.Client(protocol)
        transport.open()
        dbs = client.get_all_databases()
        return "1"
    except Thrift.TException, e:
        print "[" + time.strftime("%Y-%m-%d %X",time.localtime()) + "] %(e)s" % {'e':e.message}
        return "0"
    finally:
        if transport != None:
            try:
                transport.close()
            except Exception, e:
                print "[" + time.strftime("%Y-%m-%d %X",time.localtime()) + "] %(e)s" % {'e':e}
        print "[" + time.strftime("%Y-%m-%d %X",time.localtime()) + "] 访问 %(host)s:%(port)s 结束" % {'host':host,'port':port}

def hiveServerCheck(id):
    min = time.strftime('%M',time.localtime(time.time()))
    conn = None
    message = ""
    try:
        conn = MySQLdb.connect(config["host"],config["username"],config["password"],config["database"],charset=config["encoding"],port=int(config["port"]))
        cur = conn.cursor()
        cur.execute(" select host,port,username,password,id,result,timeout,server_type,auth,hostname from hive_server_check where valid=1 and id=%s " % id)
        alldatas = cur.fetchall()
        print "查询hiveserver，id=%s,共查询出%s条数据" %(id,len(alldatas))
        for data in alldatas:
            host = str(data[0])
            port = int(data[1])
            username = str(data[2])
            password = str(data[3])
            id = str(data[4])
            result = str(data[5])
            timeout = int(data[6])
            server_type = str(data[7])
            auth = str(data[8]).upper()
            hostname = str(data[9])
            if server_type == "hive" or server_type == "spark":
                result1 = testHive(host,port,username,auth,timeout)
            elif server_type == "metastore":
                result1 = testHiveMetaStore(host,port)

            if result1 != result:
                sql = " update hive_server_check set result=%(result)s where id=%(id)s and result<>%(result)s " %{'result':result1,'id':id}
                print sql
                cur.execute(sql)
                conn.commit()
                if result1=="1":
                    message += "%(host)s:%(port)s %(username)s %(server_type)s 恢复正常;" % {'host':hostname,'port':port,'server_type':server_type,'username':username}
                else:
                    message += "%(host)s:%(port)s %(username)s %(server_type)s 进入异常状态;" % {'host':hostname,'port':port,'server_type':server_type,'username':username}
            elif result1 == "0":
                message += "%(host)s:%(port)s %(username)s %(server_type)s 处于异常状态;" % {'host':hostname,'port':port,'server_type':server_type,'username':username}

            #做一步特殊处理，如果是spark，那么每个小时的50分的时候重启一次（如果等到每三个小时杀一次，而且正好是任务执行比较多的时候会报错）
            if server_type=="spark" and min>="50" and min<="54":
                sql = " update hive_server_check set result=0 where id=%(id)s " %{'id':id}
                cur.execute(sql)
                conn.commit()

        if len(message)>0:
            message = "["+time.strftime("%Y-%m-%d %X",time.localtime())+"]" + message
            print message
            post_url="http://schedule.flightdata.corp.qunar.com/api/alert/sendSms?"
            param={'mobiles':mobiles,'message':message,'source':'test'}
            post(post_url,param)        
        
    except Exception, e:
        print e
    finally:
        if conn != None:
            conn.close()
  
if __name__ == '__main__': 
    id = sys.argv[1]
    
    hiveServerCheck(id)
