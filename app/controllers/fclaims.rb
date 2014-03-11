Teamstatus::App.controller do
  
  get "/fclaims/:graph_id", :provides => :js do
    Fclaim.create! :graph_id => params[:graph_id], :account_id => current_account.id
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])
    "$('##{params[:graph_id]} .fclaim').html('#{js_escape_html(partial :'fclaims/fclaim', :locals => {:post => @fconnection.api.get_object(params[:graph_id])})}')"    
  end
  
  get "/fclaims/:graph_id/destroy", :provides => :js do
    Fclaim.find_by(graph_id: params[:graph_id], account_id: current_account.id).destroy
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])   
    "$('##{params[:graph_id]} .fclaim').html('#{js_escape_html(partial :'fclaims/fclaim', :locals => {:post => @fconnection.api.get_object(params[:graph_id])})}')"
  end  
  
end