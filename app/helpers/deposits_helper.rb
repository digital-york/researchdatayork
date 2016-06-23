module DepositsHelper
  include SearchSolr

  def get_preflabel(id)
    r = solr_query_short('id:' + id,'preflabel_tesim',1)
    if r['numFound'] == 1
      r['docs'][0]['preflabel_tesim'][0]
    else
      ''
    end
  end
end
