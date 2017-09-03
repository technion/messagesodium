require "base64"
require "rbnacl/libsodium"

# Based on existing class from: https://github.com/rails/rails/blob/0a6f69a5debf89748da3a43747c61d201095997e/activesupport/lib/active_support/message_encryptor.rb
# Implements all methods documented per http://api.rubyonrails.org/classes/ActiveSupport/MessageEncryptor.html

module ActiveSupport
  # MessageEncryptor is a simple way to encrypt values which get stored
  # somewhere you don't trust.
  #
  # The cipher text and initialization vector are base64 encoded and returned
  # to you.
  #
  class MessageEncryptor
    class InvalidMessage < StandardError; end

    def initialize(secret, *signature_key_or_options)
      # The options and signature fields are unused.
      # However we need to retain them as they exist in the original function
      @box = RbNaCl::SimpleBox.from_secret_key(secret)
    end

    # Encrypt and sign a message. We need to sign the message in order to avoid
    # padding attacks. Reference: http://www.limited-entropy.com/padding-oracle-attacks.
    def encrypt_and_sign(value)
      Base64.strict_encode64(@box.encrypt(value.to_json))
    end

    # Decrypt and verify a message. We need to verify the message in order to
    # avoid padding attacks. Reference: http://www.limited-entropy.com/padding-oracle-attacks.
    def decrypt_and_verify(value)
      begin
        JSON.parse(@box.decrypt(Base64.decode64(value)), symbolize_names: true)
      rescue RbNaCl::CryptoError
        raise InvalidMessage
      end
    end

    # Given a cipher, returns the key length of the cipher to help generate the key of desired size
    def self.key_len(cipher)
      # Ignore the cipher - libsodium knows what it's doing.
      RbNaCl::SecretBox.key_bytes
    end
  end

end
