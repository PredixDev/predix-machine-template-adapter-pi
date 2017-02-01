git clone https://github.com/emoranchel/IoTDevices.git --depth 1
cd IoTDevices

mvn -q install:install-file -Dfile=lib/dio.jar -DgroupId=jdk.dio -DartifactId=dio -Dversion=1.0 -Dpackaging=jar

mvn -f GrovePi-spec/pom.xml build-helper:parse-version versions:set -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
mvn -f GrovePi-spec/pom.xml versions:update-properties -Dincludes="org.iot.raspberry" -DallowSnapshots=false
mvn -f GrovePi-spec/pom.xml versions:use-releases -Dincludes=org.iot.raspberry

mvn -f Pi-spec/pom.xml build-helper:parse-version versions:set -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
mvn -f Pi-spec/pom.xml versions:update-properties -Dincludes="org.iot.raspberry" -DallowSnapshots=false
mvn -f Pi-spec/pom.xml versions:use-releases -Dincludes=org.iot.raspberry


mvn -f GrovePi-pi4j/pom.xml build-helper:parse-version versions:set -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
mvn -f GrovePi-pi4j/pom.xml versions:update-properties -Dincludes="org.iot.raspberry" -DallowSnapshots=false
mvn -f GrovePi-pi4j/pom.xml versions:use-releases -Dincludes=org.iot.raspberry

mvn -f GrovePi-dio/pom.xml build-helper:parse-version versions:set -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
mvn -f GrovePi-dio/pom.xml versions:update-properties -Dincludes="org.iot.raspberry" -DallowSnapshots=false
mvn -f GrovePi-dio/pom.xml versions:use-releases -Dincludes=org.iot.raspberry


mvn -f Pi-dio/pom.xml build-helper:parse-version versions:set -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
mvn -f Pi-dio/pom.xml versions:update-properties -Dincludes="org.iot.raspberry" -DallowSnapshots=false
mvn -f Pi-dio/pom.xml versions:use-releases -Dincludes=org.iot.raspberry

mvn -f Pi-pi4j/pom.xml build-helper:parse-version versions:set -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
mvn -f Pi-pi4j/pom.xml versions:update-properties -Dincludes="org.iot.raspberry" -DallowSnapshots=false
mvn -f Pi-pi4j/pom.xml versions:use-releases -Dincludes=org.iot.raspberry

mvn -f ProjectStub/pom.xml build-helper:parse-version versions:set -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
mvn -f ProjectStub/pom.xml versions:update-properties -Dincludes="org.iot.raspberry" -DallowSnapshots=false
mvn -f ProjectStub/pom.xml versions:use-releases -Dincludes=org.iot.raspberry

mvn -f examples/pom.xml build-helper:parse-version versions:set -DnewVersion="\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}"
mvn -f examples/pom.xml versions:update-properties -Dincludes="org.iot.raspberry" -DallowSnapshots=false
mvn -f examples/pom.xml versions:use-releases -Dincludes=org.iot.raspberry

mvn -q clean install -f GrovePi-spec/pom.xml
mvn -q clean install -f Pi-spec/pom.xml
mvn -q clean install -f GrovePi-pi4j/pom.xml
mvn -q clean install -f GrovePi-dio/pom.xml
mvn -q clean install -f Pi-dio/pom.xml
mvn -q clean install -f Pi-pi4j/pom.xml

ls ~/.m2/repository/org/iot/raspberry
cd ..

rm -rf IoTDevices
