Teamstatus::App.controller do
    
  post "/tassigns/:status_id", :provides => :js do    
    @tconnection = current_account.tconnections.find_by(user_id: params[:user_id])      
    Tassign.find_by(user_id: @tconnection.user_id, status_id: params[:status_id]).try(:destroy)
    if params[:account_id]
      tassign = Tassign.create! :status_id => params[:status_id], :assigner_id => current_account.id, :user_id => @tconnection.user_id, :user => @tconnection.user, :account_id => params[:account_id]
      options = {
        :to => tassign.account.email,
        :cc => current_account.email,
        :subject => "[TeamStatus] You were assigned a tweet",
        :body => "Yo #{tassign.account.name.split(' ').first},\n\n#{current_account.name} assigned you a tweet in the @#{@tconnection.user.screen_name} account.\n\nYou can check it out at http://#{ENV['DOMAIN']}/p/t/#{@tconnection.user_id}/assigned.\n\nBest wishes,\nThe TeamStatus email fairy"
      }
      Delayed::Job.enqueue NotificationJob.new(options)           
    end
    "$('##{params[:status_id]} .tassign').html('#{js_escape_html(partial :'tassigns/tassign', :locals => {:status_id => params[:status_id]})}')"
  end
  
end  