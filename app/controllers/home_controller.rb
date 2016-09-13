class HomeController < ApplicationController
  before_action :user_logged_in

  def user_logged_in
    redirect_to deposits_path if current_user
  end

  # GET /home
  # GET /home.json
  def index
  end
end
