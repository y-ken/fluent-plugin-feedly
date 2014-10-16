# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-feedly"
  #spec.version       = Fluent::Plugin::Feedly::VERSION
  spec.version       = "0.0.1"
  spec.authors       = ["Kentaro Yoshida"]
  spec.email         = ["y.ken.studio@gmail.com"]
  spec.summary       = %q{Fluentd input plugin to fetch RSS/ATOM feed via Feedly Could.}
  #spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = "https://github.com/y-ken/fluent-plugin-feedly"
  spec.license       = "Apache 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "fluentd"#, "~> 0.10.54"
  spec.add_runtime_dependency "feedlr"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
