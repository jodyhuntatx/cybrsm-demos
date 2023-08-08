#!/bin/bash

STORE_ID=$(./shub-cli.sh store_id_get "jodyhuntatx-se-tenant - Canada (Central)")
STORE_POLICIES=$(./shub-cli.sh polcies_target_get $STORE_ID)
FILTER_ID=filter-b285f280-2cbd-4532-a662-1408f5653b94

./shub-cli.sh filter_get $STORE_ID $FILTER_ID
