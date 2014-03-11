class Tclaim
  include Mongoid::Document
  include Mongoid::Timestamps   
  
  field :status_id, :type => String
  
  belongs_to :account 
  validates_presence_of :account  
  
  has_many :tstatuses, :dependent => :nullify
 
  validates_presence_of :status_id 
  validates_uniqueness_of :status_id
  
  def self.fields_for_index 
    [:account_id, :status_url, :created_at]
  end
  
  def status_url
    "http://twitter.com/url/status/#{status_id}"
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


  
