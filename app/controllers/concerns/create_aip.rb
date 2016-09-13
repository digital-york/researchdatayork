# app/controllers/concerns/search_pure.rb
module CreateAip
  extend ActiveSupport::Concern
  include Puree

  included do
    #
  end

  def create_aip
    Dlibhydra::Package.new
  end

  def find_aip(id)
    Dlibhydra::Package.find(id)
  end

  def user_deposit(dataset, readme)
    aip_preflabel('AIP for ' + dataset.pure_uuid + " (deposited #{DateTime.now.strftime('%Y-%m-%d %R')}")
    readme(readme)
    aip_status('Not Yet Processed')
    aip_uuid('tbc')
    aip_member_of(dataset)
  end

  def aip_member_of(dataset)
    dataset.aips << @aip
    dataset.save
  end

  def aip_uuid(uuid)
    @aip.aip_uuid = uuid
  end

  def aip_current_path(value)
    @aip.aip_current_path = value
  end

  def aip_size(value)
    @aip.aip_size = value
  end

  def aip_current_location(value)
    @aip.aip_current_location = value
  end

  def aip_resource_uri(value)
    @aip.aip_resource_uri = value
  end

  def aip_preflabel(title)
    @aip.preflabel = title
  end

  def readme(readme)
    @aip.readme = readme
  end

  def aip_status(status)
    @aip.aip_status = status
  end

  def aip_origin_pipeline(pipeline)
    @aip.aip_origin_pipeline = pipeline
  end

  def save_aip
    @aip.save
  end

  def delete_aip
    @aip.destroy_eradicate
  end

end
