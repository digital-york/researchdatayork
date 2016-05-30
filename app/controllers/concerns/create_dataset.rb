# app/controllers/concerns/search_pure.rb
module CreateDataset
  extend ActiveSupport::Concern
  include Puree

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

end