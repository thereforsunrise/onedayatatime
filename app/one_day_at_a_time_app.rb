require 'date'
require 'logger'
require 'rack/csrf'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/custom_logger'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'slim'

require_relative 'models/entry'
require_relative 'models/feature'
require_relative 'models/user'

class OneDayAtATimeApp < Sinatra::Base
  helpers Sinatra::CustomLogger

  helpers do
    def csrf_token
      Rack::Csrf.csrf_token(env)
    end

    def csrf_tag
      Rack::Csrf.csrf_tag(env)
    end
  end

  configure :development do
    register Sinatra::Reloader
  end

  configure do
    enable :sessions

    register Sinatra::ActiveRecordExtension
    register Sinatra::Flash

    use Rack::Csrf, :raise => true
    use Rack::MethodOverride

    set :database,  { url: "mysql2://#{ENV['DB_USER']}:#{ENV['DB_PASS']}@#{ENV['DB_HOST']}/#{ENV['DB_DB']}" }
    set :public_folder , Proc.new { File.join(root,"../public") }

    set :logger, Logger.new(STDOUT)
  end

  def current_user
    User.find_by_id(session[:user_id]) if session[:user_id]
  end

  get "/" do
    @user = current_user

    redirect '/write' if @user

    slim :introduction
  end

  get "/disabled" do
    slim :disabled
  end

  get "/signup" do
    @user = current_user

    if @user
      flash[:notice] = "Hey, you already have an account."
      redirect '/write'
    end

    slim :signup
  end

  post "/signup" do
    @user = current_user

    if @user
      flash[:notice] = "Hey, you already have an account."
      redirect '/write'
    end

    @user = User.new(
      username: params[:username],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    if @user.save
      flash[:notice] = "Thanks for signing up! Time to write your first entry."
      session[:user_id] = @user.id
      redirect '/write'
    end

    # TODO fix activerecoerd validation messages
    flash[:alert] = @user.errors.full_messages.join(" ")
    redirect '/signup'
  end

  get "/signin" do
    redirect '/write' if current_user

    slim :signin
  end

  get "/profile" do
    @user = current_user

    unless @user
      flash[:notice] = "Hey, you need to be signed-in to access this!"
      redirect '/signin'
    end

    slim :disabled
  end

  post "/signin" do
    @user = current_user || User.login(params[:username], params[:password])

    if @user
      session[:user_id] = @user.id
      redirect '/write'
    end

    flash[:alert] = "You failed to login. Check your username and password."
    redirect '/signin'
  end

  get "/signout" do
    session.clear
    flash[:notice] = "See you. We hope you come back soon!"
    redirect '/'
  end

  get '/read' do
    @user = current_user

    unless @user
      flash['alert'] = "You need to sign-in before you can see your entries."
      redirect '/signin'
    end

    @entries = Entry.entries_by_date_descending(@user.id)
    slim :entries
  end

  get '/write' do
    date = Time.now.to_date.strftime("%Y-%m-%d")
    redirect "/write/#{date}"
  end

  get '/dump' do
    slim :dump
  end

  get "/write/:date" do
    @user = current_user

    unless @user
      flash['alert'] = "You need to sign-in before you can write something."
      redirect '/signin'
    end

    begin
      Date.parse(params[:date])
    rescue
      flash['alert'] = "This is an invalid date. Redirecting you to write current date."
      redirect '/write'
    end

    @entry = Entry.entry_for_user_and_date(@user.id, params[:date])
    @is_current_date = Time.parse(params[:date]).strftime("%Y-%m-%d") == Time.now.strftime("%Y-%m-%d")

    if @entry.nil?
      flash['alert'] = "Sorry, you can only write entries for the current date"
      redirect '/write'
    end

    slim :write
  end

  put '/write/:date' do
    @user = current_user

    unless @user
      flash['alert'] = "You need to sign-in before you can see your entries."
      redirect '/signin'
    end

    @entry = Entry.entry_for_user_and_date(@user.id, params[:date])
    @entry.content = params[:content]

    if @entry.save
      flash[:notice] = "Saved @ #{Time.now}"
    else
      flash[:alert] = "Failed to save."
      flash[:alert] = @entry.errors.full_messages.join(" ")
    end

    redirect "/write/#{params[:date]}"
  end

  not_found do
    status 404
    slim :notfound
  end
end
