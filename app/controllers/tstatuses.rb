Teamstatus::App.controller do
  
  get '/tstatuses/new' do
    @tstatus = Tstatus.new
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    @tstatus.access_token = @tconnection.access_token
    @tstatus.access_token_secret = @tconnection.access_token_secret
    @tstatus.user = @tconnection.user
    @tstatus.user_id = @tconnection.user_id    
    @tstatus.in_reply_to_status_id = params[:in_reply_to_status_id] if params[:in_reply_to_status_id]
    @tstatus.retweeted_status_id = params[:retweeted_status_id] if params[:retweeted_status_id]
    partial :'tstatuses/tschedule', :locals => {:retweet => params[:retweet]}    
  end
  
  post '/tstatuses/new' do
    @tstatus = Tstatus.new
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    @tstatus.access_token = @tconnection.access_token
    @tstatus.access_token_secret = @tconnection.access_token_secret
    @tstatus.user = @tconnection.user
    @tstatus.user_id = @tconnection.user_id  
    if params[:retweet]
      @tstatus.retweeted_status_id = params[:retweeted_status_id] 
    else
      @tstatus.text = params[:text]
      @tstatus.in_reply_to_status_id = params[:in_reply_to_status_id]  
    end
    @tstatus.photo = params[:photo]
    if [0,1].include? @tconnection.permissions
      @tstatus.approver = current_account
      if params[:send_when] == 'now'
        @tstatus.send_now = true 
      elsif params[:send_when] == 'later'
        @tstatus.zend_at = params[:zend_at]
      end       
    elsif @tconnection.permissions == 2
      @tstatus.zend_at = params[:zend_at]
    end
    @tstatus.account = current_account
    if @tstatus.save
      if @tstatus.send_now
        redirect  "/?connection_type=t&user_id=#{@tstatus.user_id}&panel=sent"
      else
        if !@tstatus.approver          
          options = {
            :to => Tconnection.where(:user_id => @tconnection.user_id, :permissions.in => [0,1]).map(&:account).map(&:email),
            :cc => current_account.email,
            :subject => "[TeamStatus] Tweet requires approval",
            :body => "Yo,\n\n#{current_account.name}'s tweet in the @#{@tconnection.user.screen_name} account requires approval.\n\nYou can check it out at http://#{ENV['DOMAIN']}/p/t/#{@tconnection.user_id}/scheduled.\n\nBest wishes,\nThe TeamStatus email fairy"
          }
          Delayed::Job.enqueue NotificationJob.new(options)     
        end
        redirect  "/?connection_type=t&user_id=#{@tstatus.user_id}&panel=scheduled"
      end
    else
      @modal = if params[:retweet]
        partial :'tstatuses/tschedule', :locals => {:retweet => true}
      else
        partial :'tstatuses/tschedule'
      end
      erb(:home)
    end         
  end  
  
  get "/tstatuses/:id/edit" do
    @tstatus = Tstatus.find(params[:id])
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    partial :'tstatuses/tschedule', :locals => {:retweet => @tstatus.retweeted_status_id?}    
  end
  
  post '/tstatuses/:id/edit' do
    @tstatus = Tstatus.find(params[:id])
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    if params[:retweet]
      @tstatus.retweeted_status_id = params[:retweeted_status_id] 
    else
      @tstatus.text = params[:text]
      @tstatus.in_reply_to_status_id = params[:in_reply_to_status_id]  
    end
    if params[:remove_photo]
      @tstatus.photo = nil
    else
      @tstatus.photo = params[:photo] if params[:photo]
    end
    if [0,1].include? @tconnection.permissions
      if params[:send_when] == 'now'
        @tstatus.send_now = true 
      elsif params[:send_when] == 'later'
        @tstatus.zend_at = params[:zend_at]
      end       
    elsif @tconnection.permissions == 2
      @tstatus.zend_at = params[:zend_at]
    end        
    if @tstatus.save
      if @tstatus.send_now
        redirect  "/?connection_type=t&user_id=#{@tstatus.user_id}&panel=sent"
      else
        redirect  "/?connection_type=t&user_id=#{@tstatus.user_id}&panel=scheduled"
      end
    else
      @modal = if params[:retweet]
        partial :'tstatuses/tschedule', :locals => {:retweet => true}
      else
        partial :'tstatuses/tschedule'
      end
      erb(:home)
    end         
  end    
  
  get "/tstatuses/:id/destroy", :provides => :js do
    @tstatus = Tstatus.find(params[:id])
    @tstatus.destroy    
    "$('#modal').modal('hide');$('a[data-connection-type=t][data-user-id=#{@tstatus.user_id}][data-panel=scheduled]').click();"
  end
  
  get "/tstatuses/:id/approve", :provides => :js do
    @tstatus = Tstatus.find(params[:id])
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    if [0,1].include? @tconnection.permissions
      @tstatus.approver = current_account 
      @tstatus.save
    end
    "$('#modal').modal('hide');$('a[data-connection-type=t][data-user-id=#{@tstatus.user_id}][data-panel=scheduled]').click();"
  end  
  
  get "/tstatuses/:id/unapprove", :provides => :js do
    @tstatus = Tstatus.find(params[:id])
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    if [0,1].include? @tconnection.permissions
      @tstatus.approver = nil
      @tstatus.save
    end
    "$('#modal').modal('hide');$('a[data-connection-type=t][data-user-id=#{@tstatus.user_id}][data-panel=scheduled]').click();"
  end   
  
end  