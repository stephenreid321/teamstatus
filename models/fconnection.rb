class Fconnection
  include Mongoid::Document
  include Mongoid::Timestamps  

  field :access_token, :type => String
  field :user, :type => Hash
  field :user_id, :type => String
  field :order, :type => Integer
  field :permissions, :type => Integer, :default => 0
  
  
  belongs_to :account 
  validates_presence_of :account

  validates_presence_of :access_token, :user, :user_id
 
  validates_uniqueness_of :user_id, :scope => :account_id
  
  before_validation do
    unless self.user
      self.user = api.get_object('me')
      self.user_id = api.get_object('me')['id']  
    end
  end   
  
  def api
    Koala::Facebook::API.new(access_token)      
  end    
  
  def verify
    api.get_object("me")
  end
  
  def user_name
    user['name']
  end
  
  def self.fields_for_index
    [:account_id, :user_name, :order, :created_at]
  end
  
  def self.filter_options
    {o: 'created_at', d: 'desc'}
  end  
  
  def self.fields_for_form
    {
      :user_id => :text
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
    :user_name
  end  
  
end