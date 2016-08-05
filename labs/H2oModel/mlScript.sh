FUSION_API="http://localhost:8765/api/v1"
FUSION_SOLR="localhost:8983"

# Set admin password
#curl -X POST -H 'Content-type: application/json' -d '{"password":"password123"}' http://localhost:8764/api

COLL=h2oModel
echo "Creating the $COLL collection in Fusion"
curl -X PUT -H "Content-type:application/json" -d '{"solrParams":{"replicationFactor":1,"numShards":2,"maxShardsPerNode":2},"type":"DATA"}' $FUSION_API/collections/$COLL


# Stage to extract the newsgroup label
curl -X PUT -H "Content-type:application/json" -d @fusion-ml-20news-pipeline.json $FUSION_API/index-pipelines/$COLL-default
curl -X PUT  $FUSION_API/index-pipelines/$COLL-default/refresh

curl  -X POST -H "Content-type:application/json" --data-binary '{
  "add-field": { "name":"content_txt", "type":"text_en", "stored":true, "indexed":true, "multiValued":false }
}' "http://$FUSION_SOLR/solr/$COLL/schema?updateTimeoutSecs=20"


curl -X PUT -H "Content-type:application/zip" --data-binary @ml-pipeline-model.zip "$FUSION_API/blobs/h2oModel?modelType=H2oGBMmodel"
curl -X PUT  $FUSION_API/index-pipelines/$COLL-default/refresh

curl -X POST -H "Content-type:application/json" -d '[
  {
    "id":"1",
    "fields": [
      { "name": "ts", "value": "2016-02-24T00:10:01Z" },
      { "name": "content_txt", "value": "this is a doc about atheism and atheists" }
    ]
  }
]' $FUSION_API/index-pipelines/$COLL-default/collections/$COLL/index
