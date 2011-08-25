@echo on

set EXIST_HOME=..\..\trunk\eXist
set ANT_HOME=%EXIST_HOME%\tools\ant
set _LIBJARS=%CLASSPATH%;%ANT_HOME%\lib\ant-launcher.jar;%EXIST_HOME%\lib\test\junit-4.8.2.jar;%JAVA_HOME%\lib\tools.jar;%EXIST_HOME%\lib\user\svnkit.jar;%EXIST_HOME%\lib\user\svnkit-cli.jar
set JAVA_ENDORSED_DIRS=%EXIST_HOME%\lib\endorsed

rem You must set
rem -Djavax.xml.transform.TransformerFactory=org.apache.xalan.processor.TransformerFactoryImpl
rem Otherwise Ant will fail to do junitreport with Saxon, as it has a direct dependency on Xalan.

set JAVA_OPTS=-Djava.endorsed.dirs="%JAVA_ENDORSED_DIRS%" -Dant.home="%ANT_HOME%" -Dexist.home="%EXIST_HOME%" -Djavax.xml.transform.TransformerFactory="org.apache.xalan.processor.TransformerFactoryImpl"





@echo Building...
@"%JAVA_HOME%\bin\java" -Xms512m -Xmx512m %JAVA_OPTS% -classpath "%_LIBJARS%" org.apache.tools.ant.launch.Launcher %1 %2 %3 %4 %5 %6 %7 %8 %9
