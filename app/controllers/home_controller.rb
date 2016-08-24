class HomeController < ApplicationController
  before_action :user_logged_in

  def user_logged_in
    if current_user
      redirect_to deposits_path
    end
  end

  # GET /home
  # GET /home.json
  def index

  end

end
