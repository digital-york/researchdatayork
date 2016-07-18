# app/controllers/concerns/search_pure.rb
module CreateAip
  extend ActiveSupport::Concern
  include Puree

  included do
    # ???
    attr_reader :aip
  end

  def new_aip
    Dlibhydra::Aip.new
  end

  def find_aip(id)
    Dlibhydra::Aip.find(id)
  end

  def set_user_deposit(dataset,readme)
    self.set_aip_preflabel('AIP for ' + dataset.pure_uuid + " (deposited #{DateTime.now.strftime("%Y-%m-%d %R")}")
    self.set_readme(readme)
    self.set_aip_status('Not Yet Processed')
    self.set_aip_member_of(dataset)
    @aip.save
  end

  def set_aip_member_of(dataset)
    dataset.aip << @aip
    dataset.save
  end

  def set_aip_uuid(uuid)
    @aip.aip_uuid = uuid
  end
  def set_current_path(value)
    @aip.aip_current_path = value
  end
  def set_current_full_path(value)
    @aip.aip_current_full_path = value
  end
  def set_aip_size(value)
    @aip.aip_size = value
  end
  def set_current_location(value)
    @aip.aip_current_location = value
  end
=begin
  def set_resource_uri(value)
    @aip.resource_uri = value
  end
=end
  def set_aip_preflabel(title)
    @aip.preflabel = title
  end
  def set_readme(readme)
    @aip.readme = readme
  end
  def set_aip_status(status)
    # TODO check vocab?
    @aip.aip_status = status
  end

end