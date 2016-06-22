var allEvents=sqlContext.read.format("solr").options(Map("zkHost" -> "localhost:9983", "collection" -> "eventsim","partition_by" -> "time" ,"time_period" -> "1DAYS","time_stamp_field_name" -> "ts","solr.params" -> "fq=ts:[* TO *]")).load
var someEvents=sqlContext.read.format("solr").options(Map("zkHost" -> "localhost:9983", "collection" -> "eventsim","partition_by" -> "time" ,"time_period" -> "1DAYS","time_stamp_field_name" -> "ts","solr.params" -> "fq=ts:[2016-06-21T00:00:00Z TO 2016-06-23T00:00:00Z]")).load
var tillEnd=sqlContext.read.format("solr").options(Map("zkHost" -> "localhost:9983", "collection" -> "eventsim","partition_by" -> "time" ,"time_period" -> "1DAYS","time_stamp_field_name" -> "ts","solr.params" -> "fq=ts:[2016-06-21T00:00:00Z TO *]")).load
var eventsWithShardSplit=sqlContext.read.format("solr").options(Map("zkHost" -> "localhost:9983", "collection" -> "eventsim","partition_by" -> "time" ,"time_period" -> "1DAYS","time_stamp_field_name" -> "ts","solr.params" -> "fq=ts:[* TO *]","split_field" -> "_version_","splits_per_shard" -> "4")).load
someEvents.count
allEvents.count
tillEnd.count
eventsWithShardSplit.count