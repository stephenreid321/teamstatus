Teamstatus::App.controller do
  
  get '/fstatuses/new' do
    @fstatus = Fstatus.new
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])
    @fstatus.access_token = @fconnection.access_token
    @fstatus.user = @fconnection.user
    @fstatus.user_id = @fconnection.user_id    
    partial :'fstatuses/fschedule'
  end
  
  post '/fstatuses/new' do
    @fstatus = Fstatus.new
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])
    @fstatus.access_token = @fconnection.access_token
    @fstatus.user = @fconnection.user
    @fstatus.user_id = @fconnection.user_id  
    @fstatus.message = params[:message]
    @fstatus.link = params[:link]
    @fstatus.photo = params[:photo]
    if [0,1].include? @fconnection.permissions
      @fstatus.approver = current_account
      if params[:send_when] == 'now'
        @fstatus.send_now = true 
      elsif params[:send_when] == 'later'
        @fstatus.zend_at = params[:zend_at]
      end       
    elsif @fconnection.permissions == 2
      @fstatus.zend_at = params[:zend_at]
    end
    @fstatus.account = current_account
    if @fstatus.save
      if @fstatus.send_now
        redirect  "/?connection_type=f&user_id=#{@fstatus.user_id}&panel=sent"
      else
        if !@fstatus.approver          
          options = {
            :to => Fconnection.where(:user_id => @fconnection.user_id, :permissions.in => [0,1]).map(&:account).map(&:email),
            :cc => current_account.email,
            :subject => "[TeamStatus] Facebook status requires approval",
            :body => "Yo,\n\n#{current_account.name}'s status in the #{@fconnection.user['name']} account requires approval.\n\nYou can check it out at http://#{ENV['DOMAIN']}/p/f/#{@fconnection.user_id}/scheduled.\n\nBest wishes,\nThe TeamStatus email fairy"
          }
          Delayed::Job.enqueue NotificationJob.new(options)                     
        end        
        redirect  "/?connection_type=f&user_id=#{@fstatus.user_id}&panel=scheduled"
      end
    else
      @modal = partial :'fstatuses/fschedule'
      erb(:home)      
    end         
  end  
  
  get "/fstatuses/:id/edit" do
    @fstatus = Fstatus.find(params[:id])
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])        
    partial :'fstatuses/fschedule'
  end
  
  post '/fstatuses/:id/edit' do
    @fstatus = Fstatus.find(params[:id])
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])      
    @fstatus.message = params[:message]
    @fstatus.link = params[:link]      
    if params[:remove_photo]
      @fstatus.photo = nil
    else
      @fstatus.photo = params[:photo] if params[:photo]
    end   
    if [0,1].include? @fconnection.permissions
      if params[:send_when] == 'now'
        @fstatus.send_now = true 
      elsif params[:send_when] == 'later'
        @fstatus.zend_at = params[:zend_at]
      end       
    elsif @fconnection.permissions == 2
      @fstatus.zend_at = params[:zend_at]
    end
    @fstatus.account = current_account
    if @fstatus.save
      if @fstatus.send_now
        redirect  "/?connection_type=f&user_id=#{@fstatus.user_id}&panel=sent"
      else
        redirect  "/?connection_type=f&user_id=#{@fstatus.user_id}&panel=scheduled"
      end
    else
      @modal = partial :'fstatuses/fschedule'
      erb(:home)  
    end         
  end    
  
  get "/fstatuses/:id/destroy", :provides => :js do
    @fstatus = Fstatus.find(params[:id])
    @fstatus.destroy    
    "$('#modal').modal('hide');$('a[data-connection-type=f][data-user-id=#{@fstatus.user_id}][data-panel=scheduled]').click();"
  end
  
  get "/fstatuses/:id/approve", :provides => :js do
    @fstatus = Fstatus.find(params[:id])
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])
    if [0,1].include? @fconnection.permissions
      @fstatus.approver = current_account 
      @fstatus.save
    end
    "$('#modal').modal('hide');$('a[data-connection-type=f][data-user-id=#{@fstatus.user_id}][data-panel=scheduled]').click();"
  end  
  
  get "/fstatuses/:id/unapprove", :provides => :js do
    @fstatus = Fstatus.find(params[:id])
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])
    if [0,1].include? @fconnection.permissions
      @fstatus.approver = nil
      @fstatus.save
    end
    "$('#modal').modal('hide');$('a[data-connection-type=f][data-user-id=#{@fstatus.user_id}][data-panel=scheduled]').click();"
  end     
      
end  