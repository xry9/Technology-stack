use db;
show tables;
drop table if exists emp;
create table emp(id int,name string,age int,gender string,salary double,address string,birthday string,did int)row format delimited fields terminated by '\t' ;
load data local inpath '/home/tyx/data/emp0.txt' into table emp;
create table emp_lzo(id int,name string,age int,gender string,salary double,address string,birthday string,did int)STORED AS INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat';
create table emp_orc(id int,name string,age int,gender string,salary double,address string,birthday string,did int)stored as orc ;
create table emp_orc_sn(id int,name string,age int,gender string,salary double,address string,birthday string,did int)stored as orc tblproperties ("orc.compress"="SNAPPY");
----hive.exec.orc.default.compress	ZLIB	ORC文件的默认压缩方式，而且是默认压缩呀
create table emp_parquet stored as parquet as select * from emp;
set parquet.compression=SNAPPY;
create table emp_parquet_sn stored as parquet as select * from emp;
----parquet经测试parquet默认压缩格式为snappy
create table emp_rcfile stored as rcfile as select * from emp;
drop table if exists emp_rcfile_sn;
set rcfile.compression=SNAPPY;--没有生效
create table emp_rcfile_sn stored as rcfile as select * from emp;
=======================================
drop table if exists dept;
create table dept(id int,name string ,address string)row format delimited fields terminated by '\t' ;
load data local inpath '/root/data/dept.txt' into table dept;
desc formatted dept;
----------------------------------------
select d.id ,e.age,e.gender,avg(e.salary),max(e.birthday) from emp e
left join dept d on e.id =d.id
group by d.id,e.age,e.gender order by d.id desc,e.age desc,e.gender desc
limit 10;
