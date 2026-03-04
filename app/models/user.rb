class User < ApplicationRecord
  validates :did, presence: true, uniqueness: true

  # Check if the OAuth token has expired
  def token_expired?
    return true if token_expires_at.nil?

    token_expires_at < Time.current
  end

  # Return the avatar URL or a default placeholder
  def avatar_display_url
    avatar_url.presence || "https://ui-avatars.com/api/?name=#{URI.encode_www_form_component(display_name || handle || 'User')}&background=4a90d9&color=fff&size=128"
  end
end
