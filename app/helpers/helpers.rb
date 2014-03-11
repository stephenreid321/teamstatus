Teamstatus::App.helpers do

  def current_account
    @current_account ||= Account.find(session[:account_id]) if session[:account_id]
  end
  
  def protected!  
    if !current_account      
      if request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
        halt "<div class='alert'>Your session has expired. You need to <a data-toggle='modal' data-target='#modal' href='javascript:;' onclick=\"$('#modal').load('/accounts/sign_in')\">sign in again</a>.</div>"
      else
        session[:return_to] = env['REQUEST_PATH'] unless env['REQUEST_PATH'] == '/accounts/sign_out'
        flash[:warning] = "Your session has expired. Please <a data-toggle='modal' data-target='#modal' href='javascript:;' onclick=\"$('#modal').load('/accounts/sign_in')\">sign in again</a>."
        redirect '/'
      end
    end
  end 
        
  def generate_password(len)
    chars = ("a".."z").to_a + ("0".."9").to_a
    return Array.new(len) { chars[rand(chars.size)] }.join
  end  
          
  def link_tweet(t)    
    t = Rinku.auto_link(t)
    t.gsub!(/(^|\s)#(\w+)/, '\1<a target="_blank" href="http://search.twitter.com/search?q=%23\2">#\2</a>')    
    t.gsub!(/(^|\s)@(\w+)/, '\1<a target="_blank" href="http://www.twitter.com/\2">@\2</a>')    
    t.html_safe
  end
  
  def expand_links(status)
    text = status.text
    status.attrs[:entities][:urls].each { |url|
      text.sub!(url[:url], url[:expanded_url]) if url[:expanded_url]
    } if status.respond_to?(:attrs) and status.attrs and status.attrs[:entities] and status.attrs[:entities][:urls]
    text.html_safe
  end   
  
end