
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll-kentico/version'

Gem::Specification.new do |spec|
  spec.name          = 'jekyll-kentico'
  spec.version       = Jekyll::Kentico::VERSION
  spec.authors       = ['RadoslavK']
  spec.email         = ['RadoslavK@kentico.com']

  spec.summary       = 'Kentico Kontent plugin for Jekyll'
  spec.description   = 'Jekyll Kentico is utilizing Kentico Kontent, headless CMS, as a content repository and integrates it with Jekyll static site generator. You can generate posts, pages, collections and data items.'
  spec.homepage      = 'https://github.com/RadoslavK/jekyll-kentico'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6.3'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rack-jekyll', '0.5'
  spec.add_development_dependency 'capybara', '3.29.0'
  spec.add_development_dependency 'jekyll', '3.8.6'

  spec.add_runtime_dependency 'delivery-sdk-ruby', '~> 2.0'
end
