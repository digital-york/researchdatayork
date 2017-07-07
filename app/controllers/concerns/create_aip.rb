# app/controllers/concerns/search_pure.rb
module CreateAip
  extend ActiveSupport::Concern
  include Puree

  # TODO apply permissions for 'Restricted' datasets
  # TODO - add permissions (same as dataset, except for Restricted)

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
    aip_title('AIP for ' + dataset.pure_uuid + " (deposited #{DateTime.now.strftime('%Y-%m-%d %R')}")
    dataset.readme = readme
    aip_status('Not Yet Processed')
    aip_uuid('tbc')
    add_aip_permissions
    aip_member_of(dataset)
  end

  def aip_member_of(dataset)
    dataset.packaged_by << @aip
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

  def aip_title(title)
    @aip.title = [title]
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
    @aip.delete
  end

  def add_aip_permissions
    # generate permissions for a new object
    if @aip.access_control.nil?
      @aip.permissions # generate permissions
      write_aip_permissions # add write permissions
    end
  end

  # Add the default depositor
  # This required the dlibhydra depositor generator to have been run
  def write_aip_permissions
    @aip.apply_depositor
  end

end
