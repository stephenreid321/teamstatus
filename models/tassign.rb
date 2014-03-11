class Tassign
  include Mongoid::Document
  include Mongoid::Timestamps   
  
  field :status_id, :type => String
  field :user, :type => Twitter::User
  field :user_id, :type => String
  
  validates_presence_of :status_id   
  validates_presence_of :user
  validates_presence_of :user_id    
  
  validates_uniqueness_of :status_id, :scope => :user_id
  
  belongs_to :account, :inverse_of => :tassigns
  validates_presence_of :account  
  
  belongs_to :assigner, :class_name => 'Account', :inverse_of => :tassigns_as_assigner 
  validates_presence_of :assigner
  
  def self.fields_for_index 
    [:account_id, :user_screen_name, :status_url, :created_at]
  end
  
  def status_url
    "http://twitter.com/url/status/#{status_id}"
  end
  
  def user_screen_name
    user.screen_name
  end    
  
  def self.fields_for_form
    {
      :status_id => :text,
      :account_id => :lookup
    }
  end
  
  def self.filter_options
    {o: 'created_at', d: 'desc'}
  end  
  
  def self.lookup
    :id
  end  
 
end


  
