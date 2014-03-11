class Tstatus
  include Mongoid::Document
  include Mongoid::Timestamps   
  
  field :retweeted_status_id, :type => String
  field :retweeted_status, :type => Twitter::Status
  field :text, :type => String
  field :in_reply_to_status_id, :type => String
  field :in_reply_to_status, :type => Twitter::Status
  field :zend_at, :type => Time
  field :access_token, :type => String
  field :access_token_secret, :type => String
  field :user, :type => Twitter::User
  field :user_id, :type => String
  field :attempted_at, :type => Time
  
  field :photo_uid
  dragonfly_accessor :photo  
   
  belongs_to :approver, :class_name => 'Account', :inverse_of => :approved_tstatuses
 
  belongs_to :account, :inverse_of => :tstatuses
  validates_presence_of :account
  
  belongs_to :tclaim
  
  validates_presence_of :access_token
  validates_presence_of :access_token_secret
  validates_presence_of :user
  validates_presence_of :user_id  
    
  validates_presence_of :zend_at, :unless => :send_now  
  validate :zend_at_must_be_in_the_future, :if => :zend_at
  def zend_at_must_be_in_the_future
    errors.add(:zend_at, "must be in the future") unless zend_at > Time.now + 10.seconds
  end  
  
  validates_presence_of :text, :unless => :retweeted_status_id
  validate :text_must_start_with_reply_name
  def text_must_start_with_reply_name
    if in_reply_to_status and text
      errors.add(:text, "must start with @#{in_reply_to_status.user.screen_name}") unless text.starts_with?("@#{in_reply_to_status.user.screen_name}")
    end
  end
    
  before_validation do
    if retweeted_status_id or in_reply_to_status_id
      api = Twitter::Client.new(
        :oauth_token => 	access_token,
        :oauth_token_secret => access_token_secret
      )      
      self.retweeted_status = (begin api.status(retweeted_status_id) rescue nil end) if retweeted_status_id
      self.in_reply_to_status = (begin api.status(in_reply_to_status_id) rescue nil end) if in_reply_to_status_id
    end
  end  
  validates_presence_of :retweeted_status, :if => :retweeted_status_id, :message => 'is invalid'  
  validates_presence_of :in_reply_to_status, :if => :in_reply_to_status_id, :message => 'is invalid'
      
  attr_accessor :send_now  
  after_save do    
    send_now ? deliver_now : deliver_later
  end
  
  def deliver_now
    if approver and !attempted_at? 
      update_attribute(:attempted_at, Time.now)      
      if retweeted_status_id   
        api.retweet(retweeted_status_id)
        # Unfortunately, api.retweet returns the retweeted status, not the new one,
        # so we have to do this dance
        x = nil
        until x == retweeted_status_id.to_i
          status = api.retweeted_by(:count => 1).first
          x = status.retweeted_status.id
        end
      elsif photo
        status = api.update_with_media(text, photo.file, :in_reply_to_status_id => in_reply_to_status_id)
      else
        status = api.update(text, :in_reply_to_status_id => in_reply_to_status_id) 
      end
      tclaim = Tclaim.create!(:status_id => status.id, :account_id => account_id)
      update_attribute(:tclaim_id, tclaim.id)
      Comment.where(:connection_type => 't', :user_id => user_id, :panel => 'scheduled', :commentable_id => id).update_all(panel: 'sent', commentable_id: status.id.to_s)
      # Dance until our tweet has worked it's way through the Twitter corridors
      latest_status_id = nil
      until latest_status_id == status.id
        latest_status_id = api.user_timeline(:include_rts => true, :count => 1).first.id
      end
    end
  end

  def deliver_later    
    deliver_now if Time.now >= zend_at and Time.now < zend_at + 15.minutes
  end
  handle_asynchronously :deliver_later, :run_at => Proc.new { |tstatus| tstatus.zend_at }     
  
  def api
    Twitter::Client.new(:oauth_token => access_token, :oauth_token_secret => access_token_secret)
  end
  
  HUMANIZED_ATTRIBUTES = {
    :zend_at => "Time to send"
  }  
  def self.human_attribute_name(attr, options={})  
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super  
  end   
  
  def in_reply_to_screen_name
    in_reply_to_status.user.screen_name
  end
  
  def user_screen_name
    user.screen_name
  end  
    
  def self.fields_for_index
    [:account_id, :user_screen_name, :text, :created_at, :zend_at, :attempted_at, :tclaim_id]
  end
  
  def self.fields_for_form
    {
      :photo => :image
    }
  end    
  
  def self.filter_options
    {o: 'created_at', d: 'desc'}
  end    
    
end  
