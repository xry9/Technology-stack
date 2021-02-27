drop table if exists ff;
create table ff as select * from tj t1 left join tt t2 on t1.did=t2.id;
