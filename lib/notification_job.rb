class NotificationJob < Struct.new(:options)
  def perform
    Teamstatus::App.email(options.merge({:from => "TeamStatus <#{ENV['GMAIL_USERNAME']}>"}))  
  end
end