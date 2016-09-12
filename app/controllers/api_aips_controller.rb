class ApiAipsController < BaseApiController
  before_action :find_aip, only: [:update]
  # avoid 'Can't verify CSRF token authenticity'
  # TODO look at whether using devise might be better?
  protect_from_forgery with: :null_session,
                       if: proc { |c| c.request.format =~ %r{application/json} }
  include Dlibhydra
  include CreateAip

  # https://www.airpair.com/ruby-on-rails/posts/building-a-restful-api-in-a-rails-application

  before_filter only: [:update] do |c|
    meth = c.method(:validate_json)
    meth.call @json.key?('package')
  end

  def update
    puts 'CALLED'
    puts @json
    # update status
    aip_uuid(@json['package']['aip_uuid']) unless @json['package']['aip_uuid'].nil?
    # update uuid
    aip_status(@json['package']['status']) unless @json['package']['status'].nil?
    # update current path
    unless @json['package']['current_path'].nil?
      aip_current_path(@json['package']['current_path'])
    end
    unless @json['package']['resource_uri'].nil?
      aip_resource_uri(@json['package']['resource_uri'])
    end
    unless @json['package']['current_location'].nil?
      aip_current_location(@json['package']['current_location'])
    end
    unless @json['package']['origin_pipeline'].nil?
      aip_origin_pipeline(@json['package']['origin_pipeline'])
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
