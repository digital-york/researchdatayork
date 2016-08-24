# app/controllers/concerns/search_pure.rb
module CreateDataset
  extend ActiveSupport::Concern
  include Puree
  include SearchSolr

  included do
    # ???
    attr_reader :dataset
  end

  def new_dataset
    Dlibhydra::Dataset.new
  end

  def find_dataset(id)
    Dlibhydra::Dataset.find(id)
  end

  def set_metadata(d, puree_dataset)
    @d = d
    @d.for_indexing = puree_dataset.metadata.to_s
    self.set_uuid(puree_dataset.metadata['uuid'])
    self.set_title(puree_dataset.title)
    self.set_access(puree_dataset.access)
    self.set_available(puree_dataset.metadata['available'])
    self.set_pure_created(puree_dataset.metadata['created'])
    self.set_publisher(puree_dataset.publisher)
    self.set_doi(puree_dataset.doi)
    self.set_link(puree_dataset.link)
    self.set_pure_creator(puree_dataset.person)
    self.set_pure_managing_org(puree_dataset.owner)
    @d.save
  end

  def set_uuid(uuid)
    @d.pure_uuid = uuid
  end

  def set_title(title)
    @d.title = [title]
  end

  def set_access(access)
    if access == ''
      @d.access_rights = 'not set'
    else
      @d.access_rights = access
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

  def set_link(a)
    a.each do |link|
      @d.pure_link << link['url']
    end
  end

  def set_pure_creator(a)
    if a['internal'] != []
      a['internal'].each do |internal|
        if internal['role'] == 'Creator'
          create_pure_person(internal,'internal')
        end
      end
    end
    if a['external'] != []
      a['external'].each do |external|
        if external['role'] == 'Creator'
          create_pure_person(external,'external')
        end
      end
    end
  end

  def set_pure_managing_org(a)
    puts a['uuid']
    r = solr_query_short('pure_uuid_tesim:' + a['uuid'], 'id', 1)
    if r['numFound'] == 1
      o = Dlibhydra::CurrentOrganisation.find(r['docs'][0]['id'])
    else
      o = Dlibhydra::CurrentOrganisation.new
    end
    create_pure_org(o,a)
  end

  def create_pure_org(o,a)
    o.pure_type = a['type']
    o.pure_uuid = a['uuid']
    o.name = a['name']
    o.preflabel = a['name']
    o.save
    @d.managing_organisation << o
  end

  def create_pure_person(p,type)
    r = solr_query_short('pure_uuid_tesim:' + p['uuid'].to_s, 'id', 1)
    if r['numFound'] == 1
      person = Dlibhydra::CurrentPerson.find(r['docs'][0]['id'])
    else
      person = Dlibhydra::CurrentPerson.new
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