Teamstatus::App.controller do
  
  get "/tclaims/:status_id", :provides => :js do
    Tclaim.create! :status_id => params[:status_id], :account_id => current_account.id
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])      
    "$('##{params[:status_id]} .tclaim').html('#{js_escape_html(partial :'tclaims/tclaim', :locals => {:status => @tconnection.api.status(params[:status_id])})}')"
  end
  
  get "/tclaims/:status_id/destroy", :provides => :js do
    Tclaim.find_by(status_id: params[:status_id], account_id: current_account.id).destroy
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])    
    "$('##{params[:status_id]} .tclaim').html('#{js_escape_html(partial :'tclaims/tclaim', :locals => {:status => @tconnection.api.status(params[:status_id])})}')"
  end

end  