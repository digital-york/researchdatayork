class OmniauthcallbacksController < Devise::OmniauthCallbacksController

  # handle omniauth logins from shibboleth
  def shibboleth
    @user = User.from_omniauth(request.env["omniauth.auth"])
    # capture data about the user from shib
    session['shib_user_data'] = request.env["omniauth.auth"]
    sign_in_and_redirect @user

    # for debugging - comment out "sign_in_and_redirect" line above and uncomment the following two lines
    # sign_in @user
    #render :plain => request.env["omniauth.auth"]
  end

  # when shib login fails
  def failure
    # redirect them to the devise local login page
    redirect_to new_user_session_path, :notice => "Shibboleth isn't available - local login only"
  end

end
