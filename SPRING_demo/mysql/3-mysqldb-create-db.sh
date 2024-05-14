#!/bin/bash
source ../spring-demo.config
./_mysqldb-load-sql-file.sh db_create.sql
./_mysqldb-load-sql-file.sh db_load.sql
