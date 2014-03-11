module Teamstatus
  class App < Padrino::Application  
    register Padrino::Rendering
    register Padrino::Helpers
    # register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers
    # helpers Activate::NavigationHelpers
    use Dragonfly::Middleware, :dragonfly
    
    set :sessions, :expire_after => 1.year
    # set :show_exceptions, true
    set :public_folder,  Padrino.root('app', 'assets')    
                   
    before do
      redirect "http://#{ENV['DOMAIN']}" if ENV['DOMAIN'] and request.env['HTTP_HOST'] != ENV['DOMAIN']
      protected! unless request.path == '/' or request.path.starts_with?('/accounts')
      Time.zone = current_account.time_zone if current_account and current_account.time_zone    
      fix_params!
    end   
    
    register Padrino::Mailer
    set :delivery_method, :smtp => { 
      :address              => "smtp.gmail.com",
      :port                 => 587,
      :user_name            => ENV['GMAIL_USERNAME'],
      :password             => ENV['GMAIL_PASSWORD'],
      :authentication       => :plain,
      :enable_starttls_auto => true  
    }      
  
    not_found do
      erb :not_found, :layout => :application
    end
  
    use Airbrake::Rack  
    Airbrake.configure do |config| config.api_key = ENV['AIRBRAKE_API_KEY'] end
    error do
      Airbrake.notify(env['sinatra.error'], :session => session)
      erb :error, :layout => :application
    end      
    get '/airbrake' do
      raise StandardError
    end  
          
    ###

    get '/' do
      if current_account
        current_account.verify_connections!
        erb(:home)
      else
        erb(:splash)
      end
    end
    
    get '/donate' do
      erb :donate
    end
  
    get '/p/:connection_type/:user_id/:panel' do
      redirect  "/?connection_type=#{params[:connection_type]}&user_id=#{params[:user_id]}&panel=#{params[:panel]}"
    end  
    
    post '/order' do
      params[:connections].each_with_index { |x, i|
        if x[-1..-1] == 't'
          current_account.tconnections.find(x[0..-2]).update_attribute(:order, i)
        elsif x[-1..-1] == 'f'
          current_account.fconnections.find(x[0..-2]).update_attribute(:order, i)
        end
      }
    end
  
  end
end