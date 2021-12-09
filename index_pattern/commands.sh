# few examples via curl command
# to get current settings of the index 
curl -X GET "http://localhost:9200/.kibana_1"

# to create a copy of the index
curl -X PUT -H "Content-Type: application/json" -d @./kibana_mapping.json "http://localhost:9200/kibana_copy"