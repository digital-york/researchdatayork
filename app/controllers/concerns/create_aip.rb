# app/controllers/concerns/search_pure.rb
module CreateAip
  extend ActiveSupport::Concern
  include Puree

  included do
    # ???
    attr_reader :aip
  end

  def new_aip
    Dlibhydra::Package.new
  end

  def find_aip(id)
    Dlibhydra::Package.find(id)
  end

  def set_user_deposit(dataset,readme)
    self.set_aip_preflabel('AIP for ' + dataset.pure_uuid + " (deposited #{DateTime.now.strftime("%Y-%m-%d %R")}")
    self.set_readme(readme)
    self.set_aip_status('Not Yet Processed')
    self.set_aip_uuid('tbc')
    self.set_aip_member_of(dataset)
    @aip.save
  end

  def set_aip_member_of(dataset)
    dataset.aips << @aip
    dataset.save
  end
  def set_aip_uuid(uuid)
    @aip.aip_uuid = uuid
  end
  def set_current_path(value)
    @aip.aip_current_path = value
  end
  def set_aip_size(value)
    @aip.aip_size = value
  end
  def set_current_location(value)
    @aip.aip_current_location = value
  end

  def set_aip_resource_uri(value)
    @aip.aip_resource_uri = value
  end
  def set_aip_preflabel(title)
    @aip.preflabel = title
  end
  def set_readme(readme)
    @aip.readme = readme
  end
  def set_aip_status(status)
    @aip.aip_status = status
  end

  def set_aip_origin_pipeline(pipeline)
    @aip.aip_origin_pipeline = pipeline
  end

end