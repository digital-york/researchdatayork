# app/controllers/concerns/search_pure.rb
module SearchSolr
  extend ActiveSupport::Concern

  included do
    #attr_reader :month, :contests
  end

  def get_number_of_results(q='*:*')
    response = solr_connect.get 'select', :params => {
        :q => q,
        :rows => 0
    }
    response['response']['numFound']
  end

  def solr_query_short(q='*:*',fl='id',rows=0)
    response = solr_connect.get 'select', :params => {
        :q => q,
        :fl => fl,
        :rows => rows
    }
    response['response']
  end

  private

  def solr_connect
    RSolr.connect :url => ENV['SOLR_DEV']
  end
  
end