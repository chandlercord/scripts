#!/bin/bash


YESTERDAY=$(date -d @`echo "$(date '+%s') - 86400" | bc` '+%F')

for log in appsError.log.${YESTERDAY} apps.log.${YESTERDAY} memcache.log.${YESTERDAY} qps.log${YESTERDAY} qps.log${YESTERDAY} qpsPoller.log${YESTERDAY} qpsPoller.log${YESTERDAY} request.log.${YESTERDAY}; do gzip -9 ${log}; done
