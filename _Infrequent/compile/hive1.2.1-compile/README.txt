https://cwiki.apache.org/confluence/display/Hive/GettingStarted#GettingStarted-BuildingHivefromSource

1、安装好maven，在源码目录下  mvn clean install -Phadoop-2,dist -DskipTests
	-D 传递参数	-Dhadoop-0.23.version=2.7.2, -P 传递 profile, dist 的含义有空也研究一下
	
2、packaging/target下生成
==================================
貌似在windows下编译不成功，只能在linux
清空相关输出：
mvn eclipse:clean
编译成eclipse工程：
mvn eclipse:eclipse -DdownloadSources -DdownloadJavadocs -Phadoop-2
--org/pentaho/pentaho-aggdesigner-algorithm/5.1.5-jhyde/pentaho-aggdesigner-algorithm-5.1.5-jhyde.jar,缺少此jar包，手动下载
========================================
当我们通过模版（比如最简单的maven-archetype-quikstart插件）生成了一个maven的项目结构时，如何将它转换成eclipse支持的java project呢？
1. 定位到maven根目录下(该目录下必须有pom.xml)。
2. 使用maven命令 mvn eclipse:eclipse
3. 进入到根目录下，你会发现自动生成了熟悉的两个文件:.classpath 和 .project。
4. 打开eclipse，找到该项目路径，导入即可。
