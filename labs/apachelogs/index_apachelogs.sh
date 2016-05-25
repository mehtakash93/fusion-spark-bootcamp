#!/bin/bash

FUSION="localhost:8764"
FUSION_USER=admin
FUSION_PASS=
COLLECTION=apachelogs
FUSION_SOLR="localhost:8983"

function print_usage() {
  ERROR_MSG="$1"
    
  if [ "$ERROR_MSG" != "" ]; then
    echo -e "\nERROR: $ERROR_MSG\n"
  fi

  echo ""
  echo "Setup Fusion to index apache log data"
  echo ""
  echo "Usage: $0 [-f host:port] [-u user] [-p password]"
  echo ""
  echo "     -f host:port   Host and port of Fusion instance; defaults to $FUSION"
  echo ""
  echo "     -u user        Fusion user; defaults to admin"
  echo ""
  echo "     -p password    Fusion password; no default"
  echo ""
  echo "     -c collection  Fusion collection; defaults to $COLLECTION"
  echo ""
  echo "     -s solr        Solr host and port; defaults to $FUSION_SOLR"
  echo ""
}

if [ $# -eq 0 ]; then
  print_usage ""
  exit 0
fi

if [ $# -gt 0 ]; then
    while true; do
      case "$1" in
          -f|-fusion)
              if [[ -z "$2" || "${2:0:1}" == "-" ]]; then
                print_usage "host:port is required when using the $1 option!"
                exit 1
              fi
              FUSION="$2"
              shift 2
          ;;
          -s|-solr)
              if [[ -z "$2" || "${2:0:1}" == "-" ]]; then
                print_usage "host:port is required when using the $1 option!"
                exit 1
              fi
              FUSION_SOLR="$2"
              shift 2
          ;;
          -u|-user)
              if [[ -z "$2" || "${2:0:1}" == "-" ]]; then
                print_usage "user is required when using the $1 option!"
                exit 1
              fi
              FUSION_USER="$2"
              shift 2
          ;;
          -p|-pass)
              if [[ -z "$2" || "${2:0:1}" == "-" ]]; then
                print_usage "password is required when using the $1 option!"
                exit 1
              fi
              FUSION_PASS="$2"
              shift 2
          ;;
          -c|-coll)
              if [[ -z "$2" || "${2:0:1}" == "-" ]]; then
                print_usage "collection name is required when using the $1 option!"
                exit 1
              fi
              COLLECTION="$2"
              shift 2
          ;;
          -help|-usage|-h|--help)
              print_usage ""
              exit 0
          ;;
          --)
              shift
              break
          ;;
          *)
              if [ "$1" != "" ]; then
                print_usage "Unrecognized or misplaced argument: $1!"
                exit 1
              else
                break # out-of-args, stop looping
              fi
          ;;
      esac
    done
fi

if [ "$FUSION_PASS" == "" ]; then
  print_usage "Must provide a valid password for Fusion user: $FUSION_USER"
  exit 1
fi

echo -e "\nCreating new Fusion collection: $COLLECTION"
curl -u $FUSION_USER:$FUSION_PASS -X PUT -H "Content-type:application/json" -d '{"solrParams":{"replicationFactor":1,"numShards":4,"maxShardsPerNode":4},"type":"DATA"}' \
  http://$FUSION/api/apollo/collections/$COLLECTION

echo -e "\n\nEnabling signals feature for collection $COLLECTION"
curl -u $FUSION_USER:$FUSION_PASS -X PUT -H "Content-type:application/json" -d '{"enabled":true}' \
  http://$FUSION/api/apollo/collections/$COLLECTION/features/signals

echo -e "\n\nUpdating the Solr schema"
#curl -u $FUSION_USER:$FUSION_PASS -X POST -H "Content-type:application/json" --data-binary '{
#  "add-field": { "name":"clientip", "type":"string", "stored":true, "indexed":true, "multiValued":false },
#  "add-field": { "name":"ts", "type":"tdate", "stored":true, "indexed":true, "multiValued":false },
#  "add-field": { "name":"verb", "type":"string", "stored":true, "indexed":true, "multiValued":false },
#  "add-field": { "name":"response", "type":"string", "stored":true, "indexed":true, "multiValued":false },
#  "add-field": { "name":"timestamp", "type":"string", "stored":true, "indexed":true, "multiValued":false },
#  "add-field": { "name":"bytes", "type":"tint", "stored":true, "indexed":true, "multiValued":false }
#}' "http://$FUSION/api/apollo/solr/$COLLECTION/schema?updateTimeoutSecs=20"

# ugh! going thru the proxy doesn't seem to work!!!
curl -X POST -H "Content-type:application/json" --data-binary '{
  "add-field": { "name":"clientip", "type":"string", "stored":true, "indexed":true, "multiValued":false },
  "add-field": { "name":"ts", "type":"tdate", "stored":true, "indexed":true, "multiValued":false },
  "add-field": { "name":"verb", "type":"string", "stored":true, "indexed":true, "multiValued":false },
  "add-field": { "name":"response", "type":"string", "stored":true, "indexed":true, "multiValued":false },
  "add-field": { "name":"timestamp", "type":"string", "stored":true, "indexed":true, "multiValued":false },
  "add-field": { "name":"bytes", "type":"tint", "stored":true, "indexed":true, "multiValued":false }
}' "http://$FUSION_SOLR/solr/$COLLECTION/schema?updateTimeoutSecs=20"

echo -e "\n\nUpdating the apachelogs pipeline"
curl -u $FUSION_USER:$FUSION_PASS -X PUT -H "Content-type: application/json" --data-binary @pipeline.json \
  http://$FUSION/api/apollo/index-pipelines/apachelogs

echo -e "\n\nIndexing sample apache logs into $COLLECTION"
FUSION_PIPELINE=http://$FUSION/api/apollo/index-pipelines/apachelogs/collections/$COLLECTION/index
java -jar fusion-log-indexer-1.0-exe.jar -dir logs_sample \
  -fusion $FUSION_PIPELINE -fusionUser $FUSION_USER -fusionPass $FUSION_PASS -senderThreads 4 -fusionBatchSize 500 \
  -lineParserConfig apachelogs-grok-parser.properties

curl -u $FUSION_USER:$FUSION_PASS -X PUT -H "Content-Type: application/json" --data-binary @job.json "http://$FUSION/api/apollo/spark/configurations/sessionize"
curl -u $FUSION_USER:$FUSION_PASS -X POST -H "Content-Type: application/json" "http://$FUSION/api/apollo/spark/jobs/sessionize"
curl -u $FUSION_USER:$FUSION_PASS "http://$FUSION/api/apollo/spark/jobs"

echo -e "\n\nJob complete. Check the Fusion logs for more info."


