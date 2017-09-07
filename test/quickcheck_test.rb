# frozen_string_literal: true
require 'test_helper'

class MessageEncryptorTest < Minitest::Test
  N = 10000 # Test permutations
  def test_lots_of_round_tripping
    N.times do
      length = SecureRandom.random_number(24)
      data = { first: SecureRandom.random_number(1000),
               second: SecureRandom.base64(length) }
      secret = SecureRandom.random_bytes(32)
      encryptor = ActiveSupport::MessageEncryptor.new(secret)
      message = encryptor.encrypt_and_sign(data)
      assert_equal data, encryptor.decrypt_and_verify(message)
    end
  end
end
