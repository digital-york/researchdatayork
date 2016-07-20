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
    @d.index_dump = puree_dataset.metadata.to_s
    self.set_uuid(puree_dataset.uuid)
    self.set_preflabel(puree_dataset.title)
    self.set_access(puree_dataset.access)
    self.set_available(puree_dataset.available)
    self.set_pure_created(puree_dataset.created)
    self.set_doi(puree_dataset.doi)
    self.set_link(puree_dataset.link)
    self.set_pure_creator(puree_dataset.person)
    self.set_pure_managing_org(puree_dataset.organisation)
    @d.save
  end

  def set_uuid(uuid)
    @d.pure_uuid = uuid
  end
  def set_preflabel(title)
    @d.preflabel = title
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
  def set_doi(a)
    @d.doi << a
  end
  def set_link(a)
    a.each do | link |
      @d.pure_link << link['url']
    end
  end
  def set_pure_creator(a)
    if a['internal'] != []
          a['internal'].each do | internal |
            if internal['role'] == 'Creator'
              # TODO check if we have it
              create_pure_person(internal)
            end
        end
      end
  end
  def set_pure_managing_org(a)
    r = solr_query_short('pure_uuid_tesim:' + a['uuid'],'id',1)
    if r['numFound'] == 1
      o = Dlibhydra::CurrentOrganisation.find(r['docs'][0]['id'])
    else
      o = Dlibhydra::CurrentOrganisation.new
    end
    o.pure_type = a['type']
    o.pure_uuid = a['uuid']
    o.name = a['name']
    o.preflabel = a['name']
    o.save
    @d.managing_organisation << o
  end

  def create_pure_person(internal)
    r = solr_query_short('pure_uuid_tesim:' + internal['uuid'],'id',1)
    if r['numFound'] == 1
      p = Dlibhydra::CurrentPerson.find(r['docs'][0]['id'])
    else
      p = Dlibhydra::CurrentPerson.new
    end
    p.pure_type = 'internal'
    p.family = internal['name']['last']
    p.given_name = internal['name']['first']
    p.pure_uuid = internal['uuid']
    p.preflabel = internal['name']['first'] + ' ' + internal['name']['last']
    p.save
    @d.creator << p
  end


end