Teamstatus::App.controller do 
  
  get '/accounts/new' do
    @account = Account.new
    partial :'accounts/account'
  end
    
  post '/accounts/new', :provides => :js do
    @account = Account.new
    @account.email = params[:email]
    @account.password = params[:password]
    @account.password_confirmation = params[:password_confirmation]
    @account.name = params[:name]
    @account.time_zone = params[:time_zone]
    @account.role = 'user'
    if @account.save        
      options = {
        :to => ENV['GMAIL_USERNAME'],
        :subject => "TeamStatus registration",
        :body => "#{@account.name} (#{@account.email})"
      }
      Delayed::Job.enqueue NotificationJob.new(options)
      session[:account_id] = @account.id
      "window.location = '/?signed_up=true'"
    else      
      "$('#modal').html('#{js_escape_html(partial :'accounts/account')}');"
    end
  end  
  
  get '/accounts/sign_in' do
    partial :'accounts/sign_in'
  end
  
  post '/accounts/sign_in', :provides => :js do
    if account = Account.authenticate(params[:email], params[:password])
      session[:account_id] = account.id
      "window.location = '#{session[:return_to] || '/'}'"
    else      
      params[:email], params[:password] = h(params[:email]), h(params[:password])
      if Account.find_by(email: params[:email])
        flash.now[:error] = "Um, that's the wrong password. You can <a href=\"javascript:;\" onclick=\"$('#modal').load('/accounts/reset_password')\" data-target=\"#modal\">reset it</a> if you need to."      
      else
        flash.now[:error] = "Um, there's no account with that email address. Perhaps you need to <a href=\"javascript:;\" onclick=\"$('#modal').load('/accounts/new')\" data-target=\"#modal\">sign up</a>?"      
      end
      "$('#modal').html('#{js_escape_html(partial :'accounts/sign_in')}');"
    end
  end
  
  get '/accounts/reset_password' do
    partial :'accounts/reset_password'
  end
  
  post '/accounts/reset_password', :provides => :js do
    if account = Account.find_by(email: params[:email])
      generated_password = generate_password(8)
      account.password = generated_password
      account.password_confirmation = generated_password
      account.save
      options = {
        :to => account.email,
        :subject => "[TeamStatus] Password reset",
        :body => "Here ya go: your new password is\n\n#{generated_password}\n\nGet in touch if you need any further help!\nThe TeamStatus email fairy"
      }
      Delayed::Job.enqueue NotificationJob.new(options)
      flash.now[:success] = "<strong>Boom!</strong> Your password was reset. Check your email account."
      "$('#modal').html('#{js_escape_html(partial :'accounts/sign_in')}');"
    else
      params[:email] = h(params[:email])
      flash.now[:error] = "Um, there's no account with that email address. Perhaps you need to <a href=\"javascript:;\" onclick=\"$('#modal').load('/accounts/new')\" data-target=\"#modal\">sign up</a>?"      
      "$('#modal').html('#{js_escape_html(partial :'accounts/reset_password')}');"      
    end
  end    

  get '/accounts/sign_out' do
    session.clear
    redirect '/'
  end  
  
  get '/accounts/edit' do
    @account = current_account
    partial :'accounts/account'
  end
  
  post '/accounts/edit', :provides => :js do
    @account = current_account
    @account.email = params[:email]
    @account.password = params[:password]
    @account.password_confirmation = params[:password_confirmation]
    @account.name = params[:name]
    @account.time_zone = params[:time_zone]        
    if @account.save   
      "window.location = '/'"
    else      
      "$('#modal').html('#{js_escape_html(partial :'accounts/account')}');"
    end    
  end
  
  get '/accounts/destroy' do
    current_account.destroy
    redirect '/'
  end
  
end