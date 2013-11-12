lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'neo4j-cypher/version'

Gem::Specification.new do |s|
  s.name     = "neo4j-cypher"
  s.version  = Neo4j::Cypher::VERSION
  s.required_ruby_version = ">= 1.8.7"
  s.license  = 'MIT'
  s.authors  = "Andreas Ronge"
  s.email    = 'andreas.ronge@gmail.com'
  s.homepage = "http://github.com/andreasronge/neo4j-cypher/tree"
  s.rubyforge_project = 'neo4j-cypher'
  s.summary = "A Ruby DSL for Cypher - the Neo4j Graph Query Language"
  s.description = <<-EOF
This gem is used in the JRuby neo4j gem but should work on any Ruby implementation since it simply
translate a Ruby block (the dsl) to a cypher string.
  EOF

  s.require_path = 'lib'
  s.files = Dir.glob("{bin,lib,config}/**/*") + %w(README.rdoc Gemfile neo4j-cypher.gemspec)
  s.has_rdoc = true
  s.extra_rdoc_files = %w( README.rdoc )
  s.rdoc_options = ["--quiet", "--title", "Neo4j::Cypher", "--line-numbers", "--main", "README.rdoc", "--inline-source"]
end
