# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'messagesodium/version'

Gem::Specification.new do |spec|
  spec.name          = "messagesodium"
  spec.version       = Messagesodium::VERSION
  spec.authors       = ["Technion"]
  spec.email         = ["technion@lolware.net"]

  spec.summary       = %q{Patches MessageEncryptor/Cookiestore to use Libsodium .}
  spec.description   = %q{Introduces modern crypto, higher performance, smaller cookies to your sessions.}
  spec.homepage      = "https://github.com/technion/messagesodium"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rbnacl-libsodium", "~> 1.0.13"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
