# app/controllers/concerns/search_pure.rb
module SearchSolr
  extend ActiveSupport::Concern

  included do

  end

  def get_number_of_results(q = '*:*', fq = '')
    response = solr_connect.get 'select', params: {
      q: q,
      fq: fq,
      rows: 0
    }
    response['response']['numFound']
  rescue => e
    handle_exception(e, "Unable to execute Solr query. Make sure Solr is running",
                     "Error connecting to Solr. Given params 'q' => '" +
                         q.to_s + "', 'fq' => '" +
                         fq.to_s + "'", true)
    # showstopper - can't continue after this
    raise
  end

  def solr_query_short(q = '*:*', fl = 'id', rows = 0)
    response = solr_connect.get 'select', params: {
      q: q,
      fl: fl,
      rows: rows,
      sort: 'id asc'
    }
    response['response']
  rescue => e
    handle_exception(e, "Unable to execute Solr query. Make sure Solr is running",
                     "Error connecting to Solr. Given params 'q' => '" +
                         q.to_s + "', 'fl' => '" +
                         fl.to_s + "', 'rows' => '" +
                         rows.to_s + "'", true)
    # showstopper - can't continue after this
    raise
  end

  # execute a solr query with the option of paginating results (using 'start' and 'rows')
  def solr_filter_query(q='*:*', fq='', fl='id', rows=0, sort="id asc", start=0)
    response = solr_connect.get 'select', :params => {
        :q => q,
        :fq => fq,
        :fl => fl,
        :rows => rows,
        :sort => sort,
        :start => start
    }
    response['response']
  rescue => e
    handle_exception(e, "Unable to execute Solr query. Make sure Solr is running",
                     "Error connecting to Solr. Given params 'q' => '" +
                         q.to_s + "', 'fq' => '" +
                         fq.to_s + "', 'fl' => '" +
                         fl.to_s + "', 'rows' => '" +
                         rows.to_s + "', 'sort' => '" +
                         sort.to_s + "', 'start' => '" +
                         start.to_s + "'", true)
    # showstopper - can't continue after this
    raise
  end

  # are we able to talk to solr?
  def solr_is_running
    # run a basic query to find out
    response = solr_connect.get 'select', :params => { :q => "has_model_ssim:Dlibhydra::Dataset", :rows => 1 }
    true
  rescue => e
    false
  end

  private

  def solr_connect
    RSolr.connect :url => ActiveFedora.solr_config[:url] # was ENV['SOLR_DEV'] but this should be correct for both dev and prod - solr url is defined in config/solr.yml
  rescue => e
    handle_exception(e, "Unable to connect to Solr. Make sure Solr is running", "", true)
  end
end
