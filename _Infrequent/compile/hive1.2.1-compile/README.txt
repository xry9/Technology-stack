https://cwiki.apache.org/confluence/display/Hive/GettingStarted#GettingStarted-BuildingHivefromSource

1����װ��maven����Դ��Ŀ¼��  mvn clean install -Phadoop-2,dist -DskipTests
	-D ���ݲ���	-Dhadoop-0.23.version=2.7.2, -P ���� profile, dist �ĺ����п�Ҳ�о�һ��
	
2��packaging/target������
==================================
ò����windows�±��벻�ɹ���ֻ����linux
�����������
mvn eclipse:clean
�����eclipse���̣�
mvn eclipse:eclipse -DdownloadSources -DdownloadJavadocs -Phadoop-2
--org/pentaho/pentaho-aggdesigner-algorithm/5.1.5-jhyde/pentaho-aggdesigner-algorithm-5.1.5-jhyde.jar,ȱ�ٴ�jar�����ֶ�����
========================================
������ͨ��ģ�棨������򵥵�maven-archetype-quikstart�����������һ��maven����Ŀ�ṹʱ����ν���ת����eclipse֧�ֵ�java project�أ�
1. ��λ��maven��Ŀ¼��(��Ŀ¼�±�����pom.xml)��
2. ʹ��maven���� mvn eclipse:eclipse
3. ���뵽��Ŀ¼�£���ᷢ���Զ���������Ϥ�������ļ�:.classpath �� .project��
4. ��eclipse���ҵ�����Ŀ·�������뼴�ɡ�
