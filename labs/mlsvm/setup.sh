#!/bin/bash

FUSION_API="http://localhost:8765/api/v1"
FUSION_SOLR="localhost:8983"

COLL=socialdata
echo "Creating the $COLL collection in Fusion"
curl -X PUT -H "Content-type:application/json" -d '{"solrParams":{"replicationFactor":1,"numShards":2,"maxShardsPerNode":2},"type":"DATA"}' $FUSION_API/collections/$COLL

curl -X PUT -H "Content-type:application/json" -d @$COLL-default.json $FUSION_API/index-pipelines/$COLL-default
curl -X PUT -H "Content-type:application/zip" --data-binary @mllib-svm-sentiment.zip "$FUSION_API/blobs/tweets_sentiment_svm?modelType=spark-mllib"
curl -X PUT  $FUSION_API/index-pipelines/$COLL-default/refresh

curl -X POST -H "Content-type:application/json" -d '[
  {
    "id":"tweets-1",
    "fields": [
      { "name": "ts", "value": "2016-02-24T00:10:01Z" },
      { "name": "tweet_txt", "value": "I am really pissed off, angry, and unhappy about this election season! :-(" }
    ]
  }
]' $FUSION_API/index-pipelines/$COLL-default/collections/$COLL/index

curl -X POST -H "Content-type:application/json" -d '[
  {
    "id":"tweets-2",
    "fields": [
      { "name": "ts", "value": "2016-02-24T00:10:01Z" },
      { "name": "tweet_txt", "value": "I am super excited that spring is finally here, yay! #happy" }
    ]
  }
]' $FUSION_API/index-pipelines/$COLL-default/collections/$COLL/index

curl -X PUT  $FUSION_API/index-pipelines/socialdata-default/refresh
curl -X POST -H "Content-type:application/json" -d '[
  {
    "id":"tweets-1",
    "fields": [
      { "name": "ts", "value": "2016-02-24T00:10:01Z" },
      { "name": "tweet_txt", "value": "I am really pissed off, angry, and unhappy about this election season! :-(" }
    ]
  }
]' $FUSION_API/index-pipelines/socialdata-default/collections/socialdata/index

