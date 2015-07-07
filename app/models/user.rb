class User < ActiveRecord::Base
  validates :auth_token, :username, uniqueness: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,

         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook]

  before_create :generate_authentication_token!

  has_many :tasks, dependent: :destroy

  acts_as_messageable :table_name => "messages",                         # default 'messages'
                      :required   => [:topic, :body],                     # default [:topic, :body]
                      :class_name => "ActsAsMessageable::Message",       # default "ActsAsMessageable::Message",
                      :dependent  => :destroy                            # default :nullify

  def generate_authentication_token!
    begin
      self.auth_token = Devise.friendly_token
    end while self.class.exists?(auth_token: auth_token)
  end

  def self.from_omniauth(auth)
  where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
    user.email = auth.info.email
    user.password = Devise.friendly_token[0,20]
    user.username = auth.info.username   # assuming the user model has a name
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end
end
