#!/bin/bash
# bin/solr delete -c 
solr_wrapper --persist -d solr/config --collection_name hydra_works --version 6.1.0 --instance_directory tmp/solr
