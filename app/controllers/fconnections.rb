Teamstatus::App.controller do

  get '/fconnections/new' do
    @oauth = Koala::Facebook::OAuth.new(ENV['FB_APP_ID'], ENV['FB_APP_SECRET'], ENV['FB_CALLBACK_URL'])
    redirect @oauth.url_for_oauth_code(:permissions => ENV['FB_PERMISSIONS'])
  end
   
  get '/fconnections/auth' do
    @oauth = Koala::Facebook::OAuth.new(ENV['FB_APP_ID'], ENV['FB_APP_SECRET'], ENV['FB_CALLBACK_URL'])
    api = Koala::Facebook::API.new(@oauth.get_access_token(params[:code]))
    api.get_connections("me", "accounts").select { |page| page['category'] != 'Application' }.each { |page|
      page_token = api.get_page_access_token(page['id'])
      current_account.fconnections.create(:access_token => page_token)
    }      
    redirect '/'
  end
  
  get '/fconnections/:user_id/destroy' do
    current_account.fconnections.find_by(user_id: params[:user_id]).try(:destroy)
    redirect '/'
  end   
  
  get '/fconnections/access' do
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])
    partial :'fconnections/access'
  end
  
  post '/fconnections/grant', :provides => :js do
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])    
    if @fconnection.permissions == 0
      if account = Account.find_by(email: params[:email])
        account.fconnections.create(:access_token => @fconnection.access_token, :user => @fconnection.user, :user_id => @fconnection.user_id, :permissions => 2)
        "$('#modal').html('#{js_escape_html(partial :'fconnections/access')}');"   
      else
        flash.now[:error] = '<strong>Um,</strong> there\'s no such account with that email address.'
        "$('#modal').html('#{js_escape_html(partial :'fconnections/access')}');"      
      end     
    end
  end
  
  post '/fconnections/change_permissions', :provides => :js do
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])    
    if @fconnection.permissions == 0
      Fconnection.find_by(user_id: @fconnection.user_id, account_id: params[:account_id]).update_attribute(:permissions, params[:permissions])
      flash.now[:notice] = "Permissions changed to '#{Fconnection.permissions[params[:permissions].to_i]}'."
      "$('#modal').html('#{js_escape_html(partial :'fconnections/access')}');"
    end
  end   
  
  post '/fconnections/revoke', :provides => :js do
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])    
    if @fconnection.permissions == 0
      Fconnection.find_by(user_id: @fconnection.user_id, account_id: params[:account_id]).destroy
      "$('#modal').html('#{js_escape_html(partial :'fconnections/access')}');"
    end
  end    
  
end