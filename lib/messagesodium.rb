require "base64"
require "rbnacl/libsodium"
require "json" # Using built-in JSON to avoid abysmal performance

# Based on existing class from: https://github.com/rails/rails/blob/0a6f69a5debf89748da3a43747c61d201095997e/activesupport/lib/active_support/message_encryptor.rb
# Implements all methods documented per http://api.rubyonrails.org/classes/ActiveSupport/MessageEncryptor.html

module ActiveSupport
  # MessageEncryptor is a simple way to encrypt values which get stored
  # somewhere you don't trust.
  #
  # The cipher text and initialization vector are base64 encoded and returned
  # to you.
  class MessageEncryptor
    class InvalidMessage < StandardError; end

    # Uses "secret" as a libsodium Simplebox initialiser
    # Secret must be 32 bytes (256-bit) long
    # The options and signature fields are unused as lidsodium does not require
    # a second key for an HMAC.
    # However we need to retain them as they exist in the original function
    def initialize(secret, *_signature_key_or_options)
      @box = RbNaCl::SimpleBox.from_secret_key(secret)
    end

    # Encrypt and authenticate using libsodium XSalsa20/Poly1305
    # Serialise with JSON.dump
    # Returns base64(random nonce + cipher + auth tag)
    def encrypt_and_sign(value)
      Base64.strict_encode64(@box.encrypt(::JSON.dump(value)))
    end

    # Decrypt the message, and check the auth tag in the process.
    def decrypt_and_verify(value)
      ::JSON.parse(@box.decrypt(Base64.decode64(value)), symbolize_names: true)
    rescue RbNaCl::CryptoError
      raise InvalidMessage
    end

    # Given a cipher, returns the key length of the cipher to help generate
    # the key of desired size
    def self.key_len(_cipher = nil)
      # Ignore the cipher - libsodium knows what it's doing.
      RbNaCl::SecretBox.key_bytes
    end
  end
end
