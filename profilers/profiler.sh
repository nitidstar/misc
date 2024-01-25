# Original version: http://blog.tsunanet.net/2010/08/jpmp-javas-poor-mans-profiler.html

# Usage: ./profiler.sh <pid> <num-samples> <sleep-time-between-samples>

#!/bin/bash
pid=$1
nsamples=$2
sleeptime=$3

for x in $(seq 1 $nsamples)
  do
    echo sampling $x... >/dev/stderr
    gdb -ex "set pagination 0" -ex "thread apply all bt" -batch -p $pid
    echo "sample $x"
    sleep $sleeptime
  done | \
awk '
  BEGIN { s = ""; } 
  /^Thread/ { print s; s = ""; } 
  /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } 
  END { print s }' | \
sort | uniq -c | sort -r -n -k 1,1
