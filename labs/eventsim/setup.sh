FUSION_API="http://localhost:8765/api/v1"
FUSION_SOLR="localhost:8983"
#SPARK_SOLR_HOME="YOUR_SPARK_HOME"
# SPARK_HOME="Your Spark Home"
#FUSION_PASSWORD="Your Fusion password"
COLL=eventsim
echo "Creating the $COLL collection in Fusion"
curl -X PUT -H "Content-type:application/json" -d '{"solrParams":{"numShards":1,"maxShardsPerNode":2}}' $FUSION_API/collections/$COLL
curl -X PUT -H 'Content-type: application/json' -d '{ "enabled":true, "timestampFieldName":"ts", "timePeriod":"1DAYS", "scheduleIntervalMinutes":1, "preemptiveCreateEnabled":false, "maxActivePartitions":100, "deleteExpired":false }' $FUSION_API/collections/$COLL/features/partitionByTime
unzip -a control.data.json.zip
dataLocation="$(pwd)"
echo "$dataLocation/control.data.json"
cd $SPARK_HOME
bin/spark-submit --master 'local[6]' --class com.lucidworks.spark.SparkApp $SPARK_SOLR_HOME/target/spark-solr-2.1.0-SNAPSHOT-shaded.jar eventsim --zkHost localhost:9983 --collection $COLL --eventsimJson "$dataLocation/control.data.json" --fusionPass $FUSION_PASSWORD --fusion "http://localhost:8764/api/apollo/index-pipelines/$COLL-default/collections/$COLL/index"



