class ApiAipsController < BaseApiController
  before_action :find_aip, only: [:update, :show]
  # avoid 'Can't verify CSRF token authenticity'
  # TODO look at whether using devise might be better?
  protect_from_forgery with: :null_session,
                       if: Proc.new { |c| c.request.format =~ %r{application/json} }
  include Dlibhydra
  include CreateAip

  # https://www.airpair.com/ruby-on-rails/posts/building-a-restful-api-in-a-rails-application

  before_filter only: :update do |c|
    meth = c.method(:validate_json)
    meth.call (@json.has_key?('aip'))
  end

  def update
    # update status
    unless @json['aip']['aip_uuid'].nil?
      set_aip_uuid(@json['aip']['aip_uuid'])
    end
    # update uuid
    unless @json['aip']['status'].nil?
      set_aip_status(@json['aip']['status'])
    end
    # update location
    unless @json['aip']['current_path'].nil?
      set_current_path(@json['aip']['current_path'])
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
      @aip = Dlibhydra::Aip.find(params[:id])
      render nothing: true, status: :not_found unless @aip.present? #&& @aip.user == @user
    end

end
