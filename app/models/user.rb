class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User

  if Blacklight::Utils.needs_attr_accessible?

    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  devise :database_authenticatable,
         # :registerable,
         # :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :omniauthable

  # allow omniauth (including shibboleth) logins - this will create a local user based on an omniauth/shib login 
  # if they haven't logged in before
  def self.from_omniauth(auth)  
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.uid 
      user.password = Devise.friendly_token[0,20]
    end
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end
end
