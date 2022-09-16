#!/bin/bash

# port-forward the old/source jaeger-query service
# kubectl port-forward svc/pearjet-observe-backend-jaeger-query 16686:16686

curl -XGET http://localhost:16686/api/services | jq -c '.data[]' | tr -d '"' | while read i; do
  if [ "$i" = "jaeger-query" ]; then
    continue
  fi

  echo Fetching traces for service $i; 
  curl -XGET http://localhost:16686/api/traces\?service=$i\&lookback=4320m | jq . > traces-${i}.json
done
