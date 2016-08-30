#!/bin/bash
fcrepo_wrapper -p 8984 & disown
echo 'waiting 120'
sleep 120
disown;
solr_wrapper -d solr/config/ --collection_name hydra_works --version 6.1.0 & disown
echo 'waiting 120'
sleep 120
disown;
rails s -b 0.0.0.0 & disown
wait 20
disown;
