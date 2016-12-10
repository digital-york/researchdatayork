class OmniauthcallbacksController < Devise::OmniauthCallbacksController

  # handle omniauth logins from shibboleth
  def shibboleth
    @user = User.from_omniauth(request.env["omniauth.auth"])
    # capture data about the user from shib
    session['shib_user_data'] = request.env["omniauth.auth"]
    # if the shib data indicates that this person is a member of staff in information systems, make them an admin
    if request.env["omniauth.auth"].info[:affiliation].include?("Staff")
      @user.update_attribute :admin, true
    else
      @user.update_attribute :admin, false
    end
    sign_in_and_redirect @user

    # for debugging - comment out "sign_in_and_redirect" line above and uncomment the following two lines
    #sign_in @user
    #render :plain => "data: " + request.env["omniauth.auth"].to_s
  end

  # when shib login fails
  def failure
    # redirect them to the devise local login page
    redirect_to new_local_user_session_path, :notice => "Shibboleth isn't available - local login only"
  end

end
