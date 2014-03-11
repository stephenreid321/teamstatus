class Fstatus
  include Mongoid::Document
  include Mongoid::Timestamps   
  
  field :message, :type => String
  field :link, :type => String
  field :picture, :type => String
  field :name, :type => String
  field :caption, :type => String
  field :description, :type => String
  field :zend_at, :type => Time
  field :access_token, :type => String
  field :user, :type => Hash
  field :user_id, :type => String
  field :attempted_at, :type => Time
  
  field :photo_uid
  dragonfly_accessor :photo    
  
  belongs_to :approver, :class_name => 'Account', :inverse_of => :approved_fstatuses
 
  belongs_to :account, :inverse_of => :fstatuses  
  validates_presence_of :account
  
  belongs_to :fclaim
  
  validates_presence_of :access_token
  validates_presence_of :user
  validates_presence_of :user_id  
     
  validates_presence_of :zend_at, :unless => :send_now  
  validate :zend_at_must_be_in_the_future, :if => :zend_at
  def zend_at_must_be_in_the_future
    errors.add(:zend_at, "must be in the future") unless zend_at > Time.now + 10.seconds
  end  

  validates_presence_of :message 
    
  attr_accessor :send_now  
  after_save do    
    send_now ? deliver_now : deliver_later
  end
  
  before_validation :link_over_photo
  def link_over_photo
    self.photo = nil if self.link
  end
  
  before_validation :set_link_properties
  def set_link_properties
    if self.link
      og = Fstatus.opengraph(self.link)
      self.picture, self.name, self.caption, self.description = og[:picture], og[:name], og[:caption], og[:description]  
    end 
  end
    
  def self.opengraph(url)
    agent = Mechanize.new
    og = {}
    url = url.gsub('feature=player_embedded&','')
    begin
      page = agent.get("http://iframely.com/iframely?uri=#{URI.escape(url)}").body
    rescue
      return og
    end
    j = JSON.parse(page)
    og[:caption] = url
    if j['meta']
      og[:name] = j['meta']['title'] 
      if j['meta']['description']
        og[:description] = j['meta']['description'].split(' ')[0..49].join(' ')
      end
    end    
    if j['links']
      if (pic = j['links'].find { |x| x['rel'].include?('og') or x['rel'].include?('thumbnail') })
        og[:picture] = pic['href']
      end
      if (player = j['links'].find { |x| x['rel'].include?('player') })
        og[:player] = player['href']
      end      
    end
    og
  end    
   
  def deliver_now
    if approver and !attempted_at? 
      update_attribute(:attempted_at, Time.now)
      if link
        post = api.put_object('me', 'links',
          :message => message,
          :link => link,
          :picture => picture,
          :name => name,
          :caption => caption,
          :description => description
        ) 
      elsif photo
        post = api.put_object('me', 'photos',
          :message => message,
          :url => "http://#{ENV['DOMAIN']}#{photo.url}"
        )         
      else
        post = api.put_object('me', 'feed',
          :message => message
        )           
      end
      fclaim = Fclaim.create!(:graph_id => post['id'], :account_id => account_id)
      update_attribute(:fclaim_id, fclaim.id)
      Comment.where(:connection_type => 'f', :user_id => user_id, :panel => 'scheduled', :commentable_id => id).update_all(panel: 'sent', commentable_id: post['id'])
    end
  end

  def deliver_later    
    deliver_now if Time.now >= zend_at and Time.now < zend_at + 15.minutes
  end
  handle_asynchronously :deliver_later, :run_at => Proc.new { |fstatus| fstatus.zend_at }     
  
  def api
    Koala::Facebook::API.new(access_token)
  end
  
  HUMANIZED_ATTRIBUTES = {
    :zend_at => "Time to send"
  }  
  def self.human_attribute_name(attr, options={})  
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super  
  end   
  
  def user_name
    user['name']
  end
  
  def self.fields_for_index
    [:account_id, :user_name, :message, :created_at, :zend_at, :attempted_at, :fclaim_id]
  end

  def self.filter_options
    {o: 'created_at', d: 'desc'}
  end    
  
end  
