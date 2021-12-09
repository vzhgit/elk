In case if index pattern was deleted and you don't have a backup of it but you know its UNID.
All commands for a console on Dev Tools page
# 1. Create a new index pattern
In UI you simple create a new index pattern with the same name as old one.
# 2. Create a copy of system Kibana index 
Kibana stores all information in `.kibana` index (in OpenSearch it's alias and index has another name: `.kibana_1`)
To manipulate with UNIDs we need the same index. So we just create a copy of the original index.
## 2.1 Get current settings of the index 
execute following query 
```
  GET /.kibana_1
```
and remove all information about aliases and system information from settings part and
## 2.2 Create a temporary index:
```
PUT /kibana_copy
{
    "aliases" : {},
    "mappings" : {
     ... without changes ...
            },
    "settings" : {
      "index" : {
        "number_of_shards" : "1",
        "number_of_replicas" : "0"
      }
    }
}
```
# 3. Assign old UNID to existed pattern
_For example_ 
value of old UNID: `1be0ac00-5811-11ec-9b2c-e3ede4a29610` and 
value of new UNID: `9e5a4920-2283-11ec-96b4-c967034fbb6a`

Value of UNID you cat take in two ways:
* In UI 
OpenSearch: _/app/management/opensearch-dashboards/indexPatterns_
Kibana: _/app/kibana#/management/kibana/indices_
UNID is placed in the end of a link to a pattern:
  ../9e5a4920-2283-11ec-96b4-c967034fbb6a
* by searching in the index
```
POST /.kibana/_search
{
  "query": {
      "match": {
        "index-pattern.title": "<name of a pattern without asterisk>"
      }
  }
}
```
the value is stored in `_id` field.

## 3.1 Be sure that you have a correct value
```
GET /.kibana_1/_doc/index-pattern:9e5a4920-2283-11ec-96b4-c967034fbb6a
```
result will contains all information about requested index pattern
## 3.2 Copy the document to the temporary index
```
POST _reindex
{
  "source": {
    "index": ".kibana_1",
    "query": {
      "match": {
        "_id": "index-pattern:9e5a4920-2283-11ec-96b4-c967034fbb6a"
      }
    }
  },
  "dest": {
    "index": "kibana_copy"
  },
  "script": {
    "inline": "ctx._id=\"index-pattern:1be0ac00-5811-11ec-9b2c-e3ede4a29610\"",
    "lang": "painless"
  }
}
```
## 3.3 Delete existed pattern
```
DELETE /.kibana_1/_doc/index-pattern:9e5a4920-2283-11ec-96b4-c967034fbb6a
```

## 3.4 Copy the pattern back with old UNID:
```
POST _reindex
{
  "source": {
    "index": "kibana_copy",
    "query": {
      "match": {
        "_id": "index-pattern:1be0ac00-5811-11ec-9b2c-e3ede4a29610"
      }
    }
  },
  "dest": {
    "index": ".kibana_1"
  }
}
```

# 4 Delete the temporary index
```
DELETE /kibana_copy
```