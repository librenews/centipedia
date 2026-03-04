class HomeController < ApplicationController
  before_action :require_authentication, only: [ :test_post ]

  def index
  end

  # POST /test_post
  # Creates a test Bluesky post to verify PDS write access.
  def test_post
    text = params[:post_text].to_s.strip

    if text.blank?
      redirect_to root_path, alert: "Post text cannot be blank."
      return
    end

    access_token = session[:oauth_access_token] || current_user.access_token
    client = PdsClient.new(user: current_user, access_token: access_token)
    result = client.create_post(text)

    if result[:success]
      redirect_to root_path, notice: "Post created successfully! URI: #{result[:uri]}"
    else
      redirect_to root_path, alert: "Failed to create post: #{result[:error]}"
    end
  end
end
