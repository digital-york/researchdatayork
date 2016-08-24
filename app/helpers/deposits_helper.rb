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

  # Check if this is a York DOI
  def check_doi(doi)
    if doi.include? ENV['DOI_ROOT']
      return 'York DOI'
    else
      ''
    end
  end

  def checked(term)
    if @deposit.nil?
      false
    elsif @deposit.status.nil?
      false
    elsif @deposit.status.include? term
      true
    else
      false
    end
  end
end
