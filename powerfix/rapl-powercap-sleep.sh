#!/bin/bash
# MSR RAPL limits reset on suspend/resume; re-apply after wake.
if [ "$1" = "post" ]; then
    /usr/local/bin/rapl-powercap.sh
fi
