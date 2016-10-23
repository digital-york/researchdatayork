# app/controllers/concerns/search_pure.rb
module CreateDataset
  extend ActiveSupport::Concern
  include Puree
  include SearchSolr
  include Exceptions

  included do
    # ???
    attr_reader :dataset
  end

  def new_dataset
    Dlibhydra::Dataset.new
  end

  def find_dataset(id)
    Dlibhydra::Dataset.find(id)
  rescue => e
    if solr_is_running
      handle_exception(e, "Unable to find dataset " + id, "Given dataset doesn't exist. Given dataset: " + id)
    else
      handle_exception(e, "Unable to connect to Solr. Please try again later.", "Unable to connect to Solr", true)
    end
    # this is a showstopper - raise an exception and let the app-wide error handler deal with it
    raise
  end

  def set_metadata(d, puree_dataset)
    @d = d
    @d.for_indexing = puree_dataset.to_s
    set_uuid(puree_dataset['uuid'])
    set_title(puree_dataset['title'])
    set_access(puree_dataset['access'])
    set_available(puree_dataset['available'])
    set_pure_created(puree_dataset['created'])
    set_publisher(puree_dataset['publisher'])
    set_doi(puree_dataset['doi'])
    set_link(puree_dataset['link'])
    set_pure_creator(puree_dataset['person'])
    set_pure_managing_org(puree_dataset['owner'])
    @d.save
  end

  def set_uuid(uuid)
    @d.pure_uuid = uuid
  end

  def set_title(title)
    @d.title = [title]
  end

  def set_access(access)
    @d.access_rights = if access == ''
                         'not set'
                       else
                         access
                       end
  end

  def set_available(a)
    @d.date_available = Puree::Date.iso a
  end

  def set_pure_created(a)
    @d.pure_creation = a
  end

  def set_publisher(a)
    @d.publisher = a
  end

  def set_doi(a)
    @d.doi << a
  end

  # REVIEW: arrays don't behave in Hydra objects, check this works
  def set_link(a)
    a.each do |link|
      @d.pure_link << link['url']
    end
  end

  def set_pure_creator(a)
    if a['internal'] != []
      a['internal'].each do |internal|
        create_pure_person(internal, 'internal') if internal['role'] == 'Creator'
      end
    end
    if a['external'] != []
      a['external'].each do |external|
        create_pure_person(external, 'external') if external['role'] == 'Creator'
      end
    end
  end

  def set_pure_managing_org(a)
    r = solr_query_short('pure_uuid_tesim:' + a['uuid'], 'id', 1)
    o = if r['numFound'] == 1
          Dlibhydra::CurrentOrganisation.find(r['docs'][0]['id'])
        else
          Dlibhydra::CurrentOrganisation.new
        end
    create_pure_org(o, a)
  end

  def create_pure_org(o, a)
    o.pure_type = a['type']
    o.pure_uuid = a['uuid']
    o.name = a['name']
    o.preflabel = a['name']
    o.save
    @d.managing_organisation << o
  end

  def create_pure_person(p, type)
    r = solr_query_short('pure_uuid_tesim:' + p['uuid'].to_s, 'id', 1)
    person = if r['numFound'] == 1
               Dlibhydra::CurrentPerson.find(r['docs'][0]['id'])
             else
               Dlibhydra::CurrentPerson.new
             end
    person.pure_type = type
    person.family_name = p['name']['last']
    person.given_name = p['name']['first']
    person.pure_uuid = p['uuid'].to_s
    person.preflabel = p['name']['first'] + ' ' + p['name']['last']
    person.save
    @d.creator << person
  end
end
