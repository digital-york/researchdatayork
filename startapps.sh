#!/bin/bash
./fedstart.sh & disown
echo 'waiting 1 min'
sleep 60
disown;
./solrstart.sh & disown
#echo 'waiting 1 min'
#sleep 60
disown;
#rails s -b 0.0.0.0 & disown
#wait 20
#disown;
