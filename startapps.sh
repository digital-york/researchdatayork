#!/bin/bash
fcrepo_wrapper -p 8984 & disown
echo 'waiting 120'
sleep 120
disown;
solr_wrapper -d solr/config/ --collection_name hydra_works --version 5.5.1 & disown
echo 'waiting 120'
sleep 120
disown;
rails s & disown
wait 20
disown;
