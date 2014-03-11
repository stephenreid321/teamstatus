Teamstatus::App.controller do
  
  get '/tconnections/new' do
    @consumer = OAuth::Consumer.new(ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET'], {:site => "https://api.twitter.com"})
    @req_token = @consumer.get_request_token(:oauth_callback => ENV['TWITTER_CALLBACK_URL'])
    session[:request_token] = @req_token.token
    session[:request_token_secret] = @req_token.secret
    redirect @req_token.authorize_url + '&force_login=true'
  end
   
  get '/tconnections/auth' do
    @consumer = OAuth::Consumer.new(ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET'], {:site => "https://api.twitter.com"})
    @req_token = OAuth::RequestToken.new(@consumer,session[:request_token],session[:request_token_secret])
    @access_token = @req_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    current_account.tconnections.create(:access_token => @access_token.token, :access_token_secret => @access_token.secret)
    redirect '/'
  end  
  
  get '/tconnections/:user_id/destroy' do
    current_account.tconnections.find_by(user_id: params[:user_id]).try(:destroy)
    redirect '/'
  end 
  
  get '/tconnections/access' do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    partial :'tconnections/access'
  end
  
  post '/tconnections/grant', :provides => :js do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])    
    if @tconnection.permissions == 0
      if account = Account.find_by(email: params[:email])
        account.tconnections.create(:access_token => @tconnection.access_token, :access_token_secret => @tconnection.access_token_secret, :user => @tconnection.user, :user_id => @tconnection.user_id, :permissions => 2)
        "$('#modal').html('#{js_escape_html(partial :'tconnections/access')}');"      
      else
        flash.now[:error] = '<strong>Um,</strong> there\'s no such account with that email address.'
        "$('#modal').html('#{js_escape_html(partial :'tconnections/access')}');"      
      end     
    end
  end
  
  post '/tconnections/change_permissions', :provides => :js do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])    
    if @tconnection.permissions == 0
      Tconnection.find_by(user_id: @tconnection.user_id, account_id: params[:account_id]).update_attribute(:permissions, params[:permissions])
      flash.now[:notice] = "Permissions changed to '#{Tconnection.permissions[params[:permissions].to_i]}'."
      "$('#modal').html('#{js_escape_html(partial :'tconnections/access')}');"
    end
  end   
  
  post '/tconnections/revoke', :provides => :js do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])    
    if @tconnection.permissions == 0
      Tconnection.find_by(user_id: @tconnection.user_id, account_id: params[:account_id]).destroy
      "$('#modal').html('#{js_escape_html(partial :'tconnections/access')}');"
    end
  end  
  
end