# app/controllers/concerns/search_pure.rb
module CreateDataset
  extend ActiveSupport::Concern
  include Puree
  include SearchSolr
  include Exceptions

  # TODO check if this is used
  included do
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
    @d.for_indexing = [puree_dataset.to_s]
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
    add_permissions
    @d.save
  end

  def set_uuid(uuid)
    @d.pure_uuid = uuid
  end

  def set_title(title)
    @d.title = [title]
  end

  def set_access(access)
    @d.dc_access_rights = if access == ''
                         ['not set']
                       else
                         [access]
                       end
  end

  def set_available(a)
    @d.date_available = Puree::Date.iso a
  end

  def set_pure_created(a)
    @d.pure_creation = a
  end

  def set_publisher(a)
    @d.publisher << a
  end

  def set_doi(a)
    @d.doi << a
  end

  def set_link(a)
    arr = []
    a.each do |link|
      arr << link['url']
    end
    @d.pure_link = arr
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
    o.pure_type = [a['type']]
    o.pure_uuid = a['uuid']
    o.name = a['name']
    # TODO remove this once current_person generates in callback
    o.preflabel = a['name']
    o.save
    @d.managing_organisation_resource << o
  end

  def create_pure_person(p, type)
    r = solr_query_short('pure_uuid_tesim:' + p['uuid'].to_s, 'id', 1)
    person = if r['numFound'] == 1
               Dlibhydra::CurrentPerson.find(r['docs'][0]['id'])
             else
               Dlibhydra::CurrentPerson.new
             end
    person.pure_type = [type]
    person.family_name = p['name']['last']
    person.given_name = p['name']['first']
    person.pure_uuid = p['uuid'].to_s
    # TODO remove this once current_person generates in callback
    person.preflabel = p['name']['first'] + ' ' + p['name']['last']
    person.save
    @d.creator_resource << person
  end

  def add_permissions
    # generate permissions for a new object
    if @d.access_control.nil?
      @d.permissions # generate permissions
      write_permissions # add write permissions
      read_permissions # add read permissions
    end
    # for existing objects, replace the read permissions
    unless @d.access_control.contains.nil?
      @d.permissions.each do |p|
        p.mode.each do |m|
          p = read_permissions(p) if m.id == 'http://www.w3.org/ns/auth/acl#Read'
        end
      end
    end
  end

  # Add the default depositor
  # This required the dlibhydra depositor generator to have been run
  def write_permissions
    @d.apply_depositor
  end

  def read_permissions(permission_object=nil)
    # TODO public metadata for restricted, with closed files
    unless @d.dc_access_rights == 'Closed' ||
          @d.dc_access_rights == 'Restricted' ||
          @d.dc_access_rights == 'not set' ||
        @d.dc_access_rights == 'Embargoed' # TODO figure out how to deal with these

      if @d.dc_access_rights == 'Open'
        p = Hydra::AccessControls::Permission.new(type: 'group', name: 'public', access: 'read' )
        # when updating an existing object return the permission object to replace the existing one
        if permission_object.nil?
          @d.access_control.contains << p
        else
          p
        end
      end
    end
  end
end
