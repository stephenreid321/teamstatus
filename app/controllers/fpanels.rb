Teamstatus::App.controller do
  
  get "/fpanels/:user_id/sent" do
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])    
    @panel = "sent"
    @dn = 10
    @n = params[:n] ? params[:n].to_i : @dn       
    @fstatuses = @fconnection.api.get_connections("me", "posts", :limit => @n)
    partial :'fpanels/sent'
  end   
  
  get "/fpanels/:user_id/scheduled" do
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])
    @panel = 'scheduled'
    @fstatuses = Fstatus.where(:user_id => @fconnection.user_id).where(attempted_at: nil).order_by(:zend_at.asc)
    partial :'fpanels/scheduled'
  end  
  
  get "/fpanels/:user_id/destroy/:graph_id", :provides => :js do
    @fconnection = current_account.fconnections.find_by(user_id: params[:user_id])
    @fconnection.api.delete_object(params[:graph_id])
    "$('#modal').modal('hide');$('a[data-connection-type=f][data-user-id=#{params[:user_id]}][data-panel=sent]').click();"
  end  
  
  get '/fpanels/flink' do
    og = Fstatus.opengraph(params[:link])
    partial :'fpanels/flink', :locals => {
      :link => params[:link],
      :picture => og[:picture],
      :name => og[:name], 
      :caption => og[:caption], 
      :description => og[:description] 
    }
  end  
    
end