class Tconnection
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :access_token, :type => String
  field :access_token_secret, :type => String
  field :user, :type => Twitter::User
  field :user_id, :type => String
  field :order, :type => Integer
  field :permissions, :type => Integer, :default => 0
  
  belongs_to :account 
  validates_presence_of :account

  validates_presence_of :access_token, :access_token_secret, :user, :user_id
 
  validates_uniqueness_of :user_id, :scope => :account_id
  
  before_validation do
    unless self.user
      self.user = api.current_user
      self.user_id = api.current_user.id    
    end
  end  
  
  def api
    Twitter::Client.new(:oauth_token => access_token, :oauth_token_secret => access_token_secret)
  end
  
  def verify
    api.verify_credentials
  end  
  
  def user_screen_name
    user.screen_name
  end
  
  def self.fields_for_index
    [:account_id, :user_screen_name, :order, :created_at]
  end
  
  def self.filter_options
    {o: 'created_at', d: 'desc'}
  end  
  
  def self.fields_for_form
    {
      :user_id => :text,
      :permissions => :text
    }
  end
  
  def self.permissions
    {
      0 => 'Post and approve and grant access to others',
      1 => 'Post and approve',
      2 => 'Suggest only'
    }
  end
  
  def self.lookup
    :user_screen_name
  end
  
end