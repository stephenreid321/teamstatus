Teamstatus::App.controller do
  
  get "/tpanels/:user_id/sent" do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    @panel = 'sent'
    @dn = 10
    @n = params[:n] ? params[:n].to_i : @dn    
    @tstatuses = @tconnection.api.user_timeline(:include_rts => true, :count => @n)
    partial :'tpanels/sent'
  end
  
  get "/tpanels/:user_id/scheduled" do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    @panel = 'scheduled'
    @tstatuses = Tstatus.where(:user_id => @tconnection.user_id).where(attempted_at: nil).order_by(:zend_at.asc)
    partial :'tpanels/scheduled'
  end
  
  get "/tpanels/:user_id/received" do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    @panel = 'received'
    @dn = 10
    @n = params[:n] ? params[:n].to_i : @dn
    @tstatuses = @tconnection.api.mentions(:count => @n)
    partial :'tpanels/received'
  end  
  
  get "/tpanels/:user_id/search" do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    @panel = 'search'    
    @tstatuses = params[:q] ? @tconnection.api.search(params[:q]).results : false
    partial :'tpanels/search'
  end 
  
  get "/tpanels/:user_id/assigned" do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    @panel = 'assigned'        
    @tstatuses = if tassigns = current_account.tassigns.where(user_id: params[:user_id]).order_by(:created_at.desc)    
      begin
        @tconnection.api.statuses(tassigns.map(&:status_id))
      rescue Twitter::Error::NotFound
        tassigns.map { |tassign|
          begin
            @tconnection.api.status(tassign.status_id)
          rescue Twitter::Error::NotFound
            tassign.destroy; nil
          end
        }.compact
      end        
    else
      []
    end
    partial :'tpanels/assigned'
  end    
  
  get "/tpanels/:user_id/destroy/:status_id", :provides => :js do
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])
    @tconnection.api.status_destroy(params[:status_id])
    "$('#modal').modal('hide');$('a[data-connection-type=t][data-user-id=#{params[:user_id]}][data-panel=sent]').click();"
  end
    
end