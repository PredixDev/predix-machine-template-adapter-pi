git clone https://github.com/emoranchel/IoTDevices.git --depth 1

mvn -q install:install-file -Dfile=IoTDevices/lib/dio.jar -DgroupId=jdk.dio -DartifactId=dio -Dversion=1.0 -Dpackaging=jar

mvn -q clean install -f IoTDevices/GrovePi-spec/pom.xml
mvn -q clean install -f IoTDevices/Pi-spec/pom.xml
mvn -q clean install -f IoTDevices/GrovePi-pi4j/pom.xml
mvn -q clean install -f IoTDevices/GrovePi-dio/pom.xml
mvn -q clean install -f IoTDevices/Pi-dio/pom.xml
mvn -q clean install -f IoTDevices/Pi-pi4j/pom.xml

rm -rf IoTDevices
