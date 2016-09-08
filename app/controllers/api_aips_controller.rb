class ApiAipsController < BaseApiController
  before_action :find_aip, only: [:update, :show]
  # avoid 'Can't verify CSRF token authenticity'
  # TODO look at whether using devise might be better?
  protect_from_forgery with: :null_session,
                       if: proc { |c| c.request.format =~ %r{application/json} }
  include Dlibhydra
  include CreateAip

  # https://www.airpair.com/ruby-on-rails/posts/building-a-restful-api-in-a-rails-application

  before_filter only: :update do |c|
    meth = c.method(:validate_json)
    meth.call @json.key?('aip')
  end

  def update
    # update status
    set_aip_uuid(@json['aip']['aip_uuid']) unless @json['aip']['aip_uuid'].nil?
    # update uuid
    set_aip_status(@json['aip']['status']) unless @json['aip']['status'].nil?
    # update current path
    unless @json['aip']['current_path'].nil?
      set_aip_current_path(@json['aip']['current_path'])
    end
    unless @json['aip']['resource_uri'].nil?
      set_aip_resource_uri(@json['aip']['resource_uri'])
    end
    unless @json['aip']['current_location'].nil?
      set_aip_current_location(@json['aip']['current_location'])
    end
    unless @json['aip']['origin_pipeline'].nil?
      set_aip_origin_pipeline(@json['aip']['origin_pipeline'])
    end
    if @aip.save
      render json:  @aip.to_json, status: :ok
    else
      render nothing: true, status: :bad_request
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def find_aip
    @aip = Dlibhydra::Package.find(params[:id])
    render nothing: true, status: :not_found unless @aip.present? # && @aip.user == @user
  end
end
