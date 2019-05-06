#!/bin/bash

###
### Workflow for generating and following up CSRs for
### web access to Idemias web server, using client
### certificates
###

WORKFLOW_TYPE=csr-for-web-access

SCRIPT_DIR=$(dirname $0)
. $SCRIPT_DIR/key-admin-lib.sh

. $SCRIPT_DIR/csr-generating-workflow.sh

