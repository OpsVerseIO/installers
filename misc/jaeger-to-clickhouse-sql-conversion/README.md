# Migrate Existing/Old Traces to ClickHouse DB

There's a usecase that traces exist in old storage and we want to move those to new storage (in our case, ClickHouse, as well)

## The Idea 

There are two parts:
-  Download/export all the traces (per service) locally
-  Run migrator tool to convert jaeger-query JSON to ClickHouse compatible model SQL INSERTS (and run the `.sql` on ClickHouse instance) 

## The Steps

### Before the switch to ClickHouse

Export the traces via `jaeger-query` API to get traces locally as JSON (API is per-service)

1. Port-forward the jaeger-query service:

        $ NAMESPACE=<namespace-of-jaeger>
        $ kubectl -n $NAMESPACE port-forward svc/$(kubectl -n $NAMESPACE get services --selector=app.kubernetes.io/name=jaeger,app.kubernetes.io/component=query | tail -n 1 | awk '{print $1}') 16686:16686

2. Run the `export-traces.sh` script:

        $ curl -o export-traces.sh https://raw.githubusercontent.com/OpsVerseIO/installers/main/misc/jaeger-to-clickhouse-sql-conversion/export-traces.sh 
        $ chmod +x export-traces.sh
        $ ./export-traces.sh

This will create `./traces-<service>.json` files in your current directory

### After the switch to ClickHouse

1. Download the tool (optionally, build `main.go` from source) and run:

        $ curl -o trace-migration-tool https://opsverse-public.s3.amazonaws.com/utils/jaeger-to-chsql-insert-amd64-linux
        $ chmod +x trace-migration-tool 
        $ ./trace-migration-tool -service console-ui --file trace-console-ui.json >> import.sql

2. Optional: if you have several services, you can run this line to iterate thru each JSON file:

        $ for tracefile in traces-*.json; do \
            service=$(basename $tracefile .json | cut -c 8-); \
            ./trace-migration-tool --service ${service} --file ${tracefile} >> import.sql; \
          done

4. Copy the generated `import.sql` to the clickhouse pod and run it:

        $ kubectl cp -n $NAMESPACE import.sql chi-clckhs-default-0-0-0:/import.sql
        $ kubectl exec -n $NAMESPACE -it chi-clckhs-default-0-0-0 -- /bin/bash
        root@chi-clckhs-default-0-0-0:/# clickhouse-client --multiquery < /import.sql

## TODO

-  Add CI to auto build `GOOS=linux GOARCH=amd65 go build -o jaeger-to-chsql-insert-amd64-linux` for the artifact
-  Comment / cleanup / refactor if necessary
