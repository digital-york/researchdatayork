#!/bin/bash
# bin/solr delete -c 
#bundle exec solr_wrapper --persist -d ../solr/config --collection_name hydra_works --version 6.3.0 --instance_directory ~/tmp/solr
#bundle exec solr_wrapper --persist -d ../solr/config --collection_name hydra_works --version 6.3.0 --instance_directory /var/tmp/solr
bundle exec solr_wrapper --persist -d ../solr/config --version 6.3.0 --instance_directory /var/tmp/solr
#solr_wrapper --persist -d ../solr/config --version 6.2.0 --instance_directory ~/tmp/solr
