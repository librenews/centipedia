require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
  add_filter "/config/"

  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Lib", "lib"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# Disable all external HTTP requests in tests
WebMock.disable_net_connect!(allow_localhost: true)

# Enable OmniAuth test mode — skips CSRF and external OAuth flow
OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

module ActionDispatch
  class IntegrationTest
    # Simulate a logged-in user by posting a mock OmniAuth callback.
    def log_in_as(user)
      OmniAuth.config.mock_auth[:atproto] = OmniAuth::AuthHash.new({
        "info" => {
          "did" => user.did,
          "handle" => user.handle,
          "name" => user.display_name,
          "image" => user.avatar_url
        },
        "credentials" => {
          "token" => user.access_token || "test_token",
          "refresh_token" => user.refresh_token || "test_refresh",
          "expires_at" => 1.hour.from_now.to_i
        }
      })

      stub_request(:get, /com.atproto.repo.getRecord/)
        .to_return(status: 200, body: '{"value":{}}')

      get "/auth/atproto/callback"
    end
  end
end
