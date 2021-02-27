hadoop3 版本slaves文件改为works了
要在start-dfs.sh，stop-dfs.sh脚本顶部中加入
HDFS_DATANODE_USER=root
HADOOP_SECURE_DN_USER=hdfs
HDFS_NAMENODE_USER=root
HDFS_SECONDARYNAMENODE_USER=root
start-yarn.sh，stop-yarn.sh加入
YARN_NODEMANAGER_USER=root
YARN_RESOURCEMANAGER_USER=root
