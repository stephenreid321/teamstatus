Teamstatus::App.controller do 
      
  post '/comments/new' do   
    comment = Comment.create!(
      :account => current_account,
      :body => params[:body],
      :connection_type => params[:connection_type],
      :user_id => params[:user_id],
      :panel => params[:panel],
      :commentable_id => params[:commentable_id]
    )             
    
    people_to_notify = []
    people_to_notify += Comment.where(
      :connection_type => comment.connection_type,
      :user_id => comment.user_id,
      :panel => comment.panel,
      :commentable_id => comment.commentable_id
    ).collect { |comment| comment.account } # anyone that's commented on this thread
    
    if comment.connection_type == 't' and comment.panel == 'sent'     
      status = current_account.tconnections.find_by(user_id: comment.user_id).api.status(params[:commentable_id])
      people_to_notify << Tclaim.find_by(status_id: params[:commentable_id]).try(:account) # the person that claimed the tweet
      what = "a tweet in the @#{status.user.screen_name} account (Twitter url: http://twitter.com/#{status.user.screen_name}/status/#{status.id})"
    elsif comment.connection_type == 't' and comment.panel == 'scheduled'     
      tstatus = Tstatus.find(params[:commentable_id])      
      people_to_notify << tstatus.account # the person that scheduled the tweet
      what = "a scheduled tweet in the @#{tstatus.user.screen_name} account"
    elsif comment.connection_type == 't' and comment.panel == 'received'     
      status = current_account.tconnections.find_by(user_id: comment.user_id).api.status(params[:commentable_id])
      what = "a tweet by @#{status.user.screen_name} (Twitter url: http://twitter.com/#{status.user.screen_name}/status/#{status.id})"      
    elsif comment.connection_type == 'f' and comment.panel == 'sent'      
      post = current_account.fconnections.find_by(user_id: comment.user_id).api.get_object(params[:commentable_id])
      people_to_notify << Fclaim.find_by(graph_id: params[:commentable_id]).try(:account) # the person that claimed the post
      what = "a Facebook status in the #{post['from']['name']} account (Facebook url: #{post['actions'].first['link']})"
    elsif comment.connection_type == 'f' and comment.panel == 'scheduled'     
      fstatus = Fstatus.find(params[:commentable_id])      
      people_to_notify << fstatus.account # the person that scheduled the post
      what = "a scheduled Facebook status in the #{fstatus.user['name']} account"     
    end
    
    (people_to_notify - [current_account]).compact.uniq.each { |account|
      options = {
        :to => account.email,
        :subject => "[TeamStatus] Comment notification",
        :body => "Yo #{account.name.split(' ').first},\n\n#{current_account.name} made a comment on #{what}:\n\n#{comment.body}\n\nYou can reply at http://#{ENV['DOMAIN']}/p/#{comment.connection_type}/#{comment.user_id}/#{comment.panel}.\n\nBest wishes,\nThe TeamStatus email fairy"
      }
      Delayed::Job.enqueue NotificationJob.new(options)     
    }
    
    "var comments = $('[data-commentable-id=#{comment.commentable_id}]');
     comments.html('#{js_escape_html(partial :'comments/comments', :locals => {:connection_type => comment.connection_type, :user_id => comment.user_id, :panel => comment.panel, :commentable_id => comment.commentable_id})}');
     comments.find('input').focus();"
  end
      
  get '/comments/:id/destroy', :provides => :js do
    comment = Comment.find(params[:id])
    comment.destroy    
    "var comments = $('[data-commentable-id=#{comment.commentable_id}]');
     comments.html('#{js_escape_html(partial :'comments/comments', :locals => {:connection_type => comment.connection_type, :user_id => comment.user_id, :panel => comment.panel, :commentable_id => comment.commentable_id})}');"
  end
  
end