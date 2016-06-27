The Steps to run this lab:-

1) Start Fusion

2) Open the setup file and fill in the variables SPARK_HOME, SPARK_SOLR_HOME and FUSION_PASSWORD

3) Run the setup file in order to create a collection named "eventsim" in fusion,indexed with data in control.data.json. This should create multiple collections(1 collection for each day)

4) Now go to $SPARK_HOME and spin up your spark shell with the spark-solr jar added and run the TestScript 

Eg. bin/spark-shell --jars $SPARK_SOLR_HOME/target/spark-solr-2.1.0-SNAPSHOT-shaded.jar -i $PATH_TO_THIS_LAB/TestScript.scala

In TestScript.scala we give examples to query multiple collections from spark.
