# frozen_string_literal: true
# Based on: https://raw.githubusercontent.com/rails/rails/1f7f872ac6c8b57af6e0117bde5f6c38d0bae923/activesupport/test/message_encryptor_test.rb

require 'test_helper'

class MessageEncryptorTest < Minitest::Test
  # Tests removed:
  # Backward compat tests. We don't support any older encrypted data
  # AEAD tests. Everything is an AEAD
  # Alternate serializers. Everything is JSON>
  def setup
    @secret    = SecureRandom.random_bytes(32)
    @encryptor = ActiveSupport::MessageEncryptor.new(@secret)
    @data = { some: "data", now: Time.local(2010).to_s }
  end

  def test_signed_round_tripping
    message = @encryptor.encrypt_and_sign(@data)
    assert_equal @data, @encryptor.decrypt_and_verify(message)
  end

  def test_encrypting_twice_yields_differing_cipher_text
    first_message = @encryptor.encrypt_and_sign(@data)
    second_message = @encryptor.encrypt_and_sign(@data)
    refute_equal first_message, second_message
  end

  def test_mutating_fields
    cipher = Base64.decode64(@encryptor.encrypt_and_sign(@data))
    brokenonce = brokeauth = brokemessage = cipher
    brokenonce[2] = (brokenonce[2].ord ^ 'a'.ord).chr
    brokeauth[-2] = (brokeauth[-2].ord ^ 'a'.ord).chr

    # A location in the cipher text after the end of the nonce
    msgbyte = RbNaCl::SecretBoxes::XSalsa20Poly1305.nonce_bytes + 4
    brokemessage[msgbyte] = (brokemessage[msgbyte].ord ^ 'a'.ord).chr

    assert_not_verified(Base64.urlsafe_encode64(brokenonce))
    assert_not_verified(Base64.urlsafe_encode64(brokeauth))
    assert_not_verified(Base64.urlsafe_encode64(brokemessage))
  end

  def test_backwards_compat_for_64_bytes_key
    # Actually, we won't support tiny keys
    # Test for an exception here
    # 128 bit key
    key = SecureRandom.random_bytes(16)
    # Encryptor with 32 bit key, 64 bit secret for verifier
    assert_raises RbNaCl::LengthError do
      ActiveSupport::MessageEncryptor.new(key)
    end
  end

  def test_message_obeys_strict_encoding
    # These bas encoding characters should refuse to be decoded
    bad_encoding_characters = "\n!@#"
    message = @encryptor.encrypt_and_sign(@data) + bad_encoding_characters
    assert_raises ArgumentError do
      @encryptor.decrypt_and_verify(message)
    end
  end

  private

  def assert_not_verified(value)
    assert_raises ActiveSupport::MessageEncryptor::InvalidMessage do
      @encryptor.decrypt_and_verify(value)
    end
  end
end
