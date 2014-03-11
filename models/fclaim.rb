class Fclaim
  include Mongoid::Document
  include Mongoid::Timestamps  

  field :graph_id, :type => String
  
  belongs_to :account 
  validates_presence_of :account  
  
  has_many :fstatuses, :dependent => :nullify
 
  validates_presence_of :graph_id 
  validates_uniqueness_of :graph_id  
  
  def self.fields_for_index 
    [:account_id, :graph_url, :created_at]
  end
  
  def graph_url
    "http://www.facebook.com/#{graph_id}"
  end
  
  def self.fields_for_form
    {
      :graph_id => :text,
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
