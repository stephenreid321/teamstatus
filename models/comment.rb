class Comment
  include Mongoid::Document
  include Mongoid::Timestamps  
  
  field :connection_type, :type => String
  field :user_id, :type => String
  field :panel, :type => String
  field :commentable_id, :type => String
  field :body, :type => String
  
  belongs_to :account 
  validates_presence_of :account  
  
  validates_presence_of :connection_type, :user_id, :panel, :commentable_id, :body
  
  def self.fields_for_index
    [:connection_type, :user_id, :panel, :commentable_id, :body]
  end
  
end