class Account
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :tconnections, :dependent => :destroy
  has_many :fconnections, :dependent => :destroy
  def connections
    tconnections + fconnections
  end
  
  has_many :tclaims, :dependent => :destroy
  has_many :fclaims, :dependent => :destroy
  
  has_many :tassigns, :inverse_of => :account, :dependent => :destroy
  has_many :tassigns_as_assigner, :class_name => 'Tassign', :inverse_of => :assigner, :dependent => :nullify
  
  has_many :tstatuses, :inverse_of => :account, :dependent => :destroy
  has_many :approved_tstatuses, :class_name => 'Tstatus', :inverse_of => :approver, :dependent => :nullify
  
  has_many :fstatuses, :inverse_of => :account, :dependent => :destroy
  has_many :approved_fstatuses, :class_name => 'Fstatus', :inverse_of => :approver, :dependent => :nullify  
  
  has_many :comments, :dependent => :destroy
  
  def verify_connections!
    connections.each { |konnection|
      begin
        konnection.destroy unless konnection.verify
      rescue
        konnection.destroy
      end
    }
  end  
              
  ###
  
  # Fields
  field :name, :type => String
  field :email, :type => String
  field :role, :type => String, :default => 'user'
  field :time_zone, :type => String
  field :crypted_password, :type => String
          
  attr_accessor :password, :password_confirmation 

  validates_presence_of :name, :role, :time_zone    
  validates_presence_of     :email
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :email,    :case_sensitive => false
  validates_format_of       :email,    :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i  
  validates_presence_of     :password,                   :if => :password_required
  validates_presence_of     :password_confirmation,      :if => :password_required
  validates_length_of       :password, :within => 4..40, :if => :password_required
  validates_confirmation_of :password,                   :if => :password_required  
      
  def self.fields_for_index
    [:name, :email, :role, :time_zone, :created_at]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :email => :text,
      :role => :select,
      :time_zone => :select,
      :password => :password,
      :password_confirmation => :password,
      :tconnections => :collection,
      :fconnections => :collection
    }
  end
  
  def self.filter_options
    {o: 'created_at', d: 'desc'}
  end
    
  def self.edit_hints
    {
      :password => 'Leave blank to keep existing password'      
    }
  end   
           
  def self.time_zones
    ['']+ActiveSupport::TimeZone::MAPPING.keys.sort
  end  
  
  def self.roles
    ['user','admin']
  end    
  
  def self.lookup
    :name
  end
    
  def uid
    id
  end
  
  def info
    {:email => email, :name => name}
  end
  
  def self.authenticate(email, password)
    account = find_by(email: email) if email.present?
    account && account.has_password?(password) ? account : nil
  end
  
  before_save :encrypt_password, :if => :password_required

  def has_password?(password)
    ::BCrypt::Password.new(crypted_password) == password
  end

  private
  def encrypt_password
    self.crypted_password = ::BCrypt::Password.create(self.password)
  end

  def password_required
    crypted_password.blank? || self.password.present?
  end 
end
