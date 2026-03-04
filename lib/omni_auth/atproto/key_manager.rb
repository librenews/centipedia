require "openssl"
require "json"
require "fileutils"

module OmniAuth
  module Atproto
    class KeyManager
      class << self
        def current_private_key
          ensure_keys_exist!
          OpenSSL::PKey::EC.new(File.read(private_key_path))
        end

        def current_jwk
          ensure_keys_exist!
          JSON.parse(File.read(jwk_path))
        end

        def generate_keys
          key = OpenSSL::PKey::EC.generate("prime256v1")

          FileUtils.mkdir_p(File.dirname(private_key_path))
          File.write(private_key_path, key.to_pem)

          # Extract EC point coordinates for JWK
          public_key = key.public_key
          point_bn = public_key.to_bn
          point_hex = point_bn.to_s(16)

          if point_hex.length == 130 && point_hex.start_with?("04")
            x_hex = point_hex[2, 64]
            y_hex = point_hex[66, 64]
          else
            x_hex = point_hex.rjust(64, "0")
            y_hex = point_hex.rjust(64, "0")
          end

          jwk = {
            kty: "EC",
            crv: "P-256",
            x: Base64.urlsafe_encode64([ x_hex ].pack("H*"), padding: false),
            y: Base64.urlsafe_encode64([ y_hex ].pack("H*"), padding: false),
            use: "sig",
            alg: "ES256",
            kid: SecureRandom.uuid
          }

          FileUtils.mkdir_p(File.dirname(jwk_path))
          File.write(jwk_path, JSON.pretty_generate(jwk))

          Rails.logger.info "Generated new AT Protocol OAuth keys" if defined?(Rails)
        end

        def keys_exist?
          File.exist?(private_key_path) && File.exist?(jwk_path)
        end

        def private_key_path
          if defined?(Rails)
            Rails.root.join("config", "atproto_private_key.pem").to_s
          else
            File.join("config", "atproto_private_key.pem")
          end
        end

        def jwk_path
          if defined?(Rails)
            Rails.root.join("config", "atproto_jwk.json").to_s
          else
            File.join("config", "atproto_jwk.json")
          end
        end

        private

        def ensure_keys_exist!
          generate_keys unless keys_exist?
        end
      end
    end
  end
end
