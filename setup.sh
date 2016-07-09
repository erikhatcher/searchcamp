#!/usr/bin/env bash
export FUSION_HOME=$HOME/fusion-2.4.1
export FUSION_API_BASE=http://localhost:8764/api/apollo
export ZK_HOST=localhost:9983
export FUSION_API_CREDENTIALS=admin:abcd1234

# rules: create configset (assuming this is already set up, for now)
# $FUSION_HOME/apps/solr-dist/server/scripts/cloud-scripts/zkcli.sh -zkhost "$ZK_HOST" -cmd upconfig -confname rules -confdir rules_conf/
# rules: pull Solr configuration from ZK; use when editing rules config through Fusion UI and need to pull it back down to save
# $FUSION_HOME/apps/solr-dist/server/scripts/cloud-scripts/zkcli.sh -zkhost "$ZK_HOST" -cmd downconfig -confname rules -confdir rules_conf/

# searchcamp_rules: create collection (specific to the example products)
curl -u $FUSION_API_CREDENTIALS -X PUT -H 'Content-type: application/json' \
     -d '{"solrParams":{"replicationFactor":1,"numShards":1, "collection.configName": "rules"}}' \
     ${FUSION_API_BASE}/collections/searchcamp_rules



# searchcamp: create collection
curl -u $FUSION_API_CREDENTIALS -X PUT -H 'Content-type: application/json' \
     -d '{"solrParams":{"replicationFactor":1,"numShards":1}}' \
     ${FUSION_API_BASE}/collections/searchcamp

# searchcamp: enable signals and search logs
curl -u $FUSION_API_CREDENTIALS -X PUT -H Content-type:application/json -d '{"enabled":true}' ${FUSION_API_BASE}/collections/searchcamp/features/searchLogs
curl -u $FUSION_API_CREDENTIALS -X PUT -H Content-type:application/json -d '{"enabled":true}' ${FUSION_API_BASE}/collections/searchcamp/features/signals

# searchcamp: set up demo pipeline, incorporating signals and rules
curl -u $FUSION_API_CREDENTIALS -X DELETE ${FUSION_API_BASE}/query-pipelines/searchcamp-demo
curl -u $FUSION_API_CREDENTIALS -X POST -H 'Content-type: application/json' -d @fusion/searchcamp-demo-query-pipeline.json ${FUSION_API_BASE}/query-pipelines

# searchcamp: pull down the rules query pipeline; use when making edits through Fusion UI and need to save
# curl -u $FUSION_API_CREDENTIALS -X GET ${FUSION_API_BASE}/query-pipelines/searchcamp-demo > searchcamp-demo-query-pipeline.json

# aggregation: enable click aggregation
curl -u $FUSION_API_CREDENTIALS -X DELETE ${FUSION_API_BASE}/aggegator/aggregations/click
curl -u $FUSION_API_CREDENTIALS -X POST -H 'Content-Type: application/json' -d @fusion/aggregation_definition.json ${FUSION_API_BASE}/aggregator/aggregations

# searchcamp: set up "demo" query profile
curl -u $FUSION_API_CREDENTIALS -X PUT -H 'Content-type: application/json' -d '"searchcamp-demo"' ${FUSION_API_BASE}/collections/searchcamp/query-profiles/demo

# rules - index some???
# $FUSION_HOME/apps/solr-dist/bin/post -c searchcamp_rules data/rules.json

$FUSION_HOME/apps/solr-dist/bin/post -c searchcamp -params "rowid=id&f.speakers.split=true" searchcamp.csv


# Add some fake click data
#  curl -u $FUSION_API_CREDENTIALS "${FUSION_API_BASE}/signals/searchcamp?commit=true" -X POST -H 'Content-type:application/json' --data-binary @data/fake_clicks.json

# Run the aggregation (it's id=99 in data/aggregation_definition.json)
# curl -u $FUSION_API_CREDENTIALS -X POST "${FUSION_API_BASE}/aggregator/jobs/searchcamp_signals/99"

# Check aggregator job status
# curl -u $FUSION_API_CREDENTIALS ${FUSION_API_BASE}/aggregator/jobs/searchcamp_signals/99
