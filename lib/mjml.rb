require 'dry-configurable'
require 'mjml/logger'
require 'mjml/feature'
require 'mjml/parser'

# MJML library for ruby
module MJML
  # Constants
  MIME_TYPE = 'text/mjml'.freeze
  EXTENSION = '.mjml'.freeze
  VERSION_3_REGEX = /^(\d\.\d\.\d)/i
  VERSION_4_REGEX = /^mjml-cli: (\d\.\d\.\d)/i

  extend Dry::Configurable
  # Available settings
  setting :bin_path
  setting :debug
  setting :logger
  setting :minify_output
  setting :validation_level

  def self.setup!
    # Init config
    configure do |config|
      config.bin_path = find_executable
      config.debug = nil
      config.logger = Logger.setup!(STDOUT)
      config.minify_output = false
      config.validation_level = :skip
    end
  end

  def self.find_executable
    local_path = File.expand_path('node_modules/.bin/mjml', Dir.pwd)
    return local_path if File.file?(local_path)
    `/usr/bin/env bash -c "which mjml"`.strip
  end

  def self.executable_version
    @executable_version ||= extract_executable_version
  end

  def self.extract_executable_version
    ver, _status = Open3.capture2(config.bin_path, '-V')

    # mjml 3.x outputs version directly:
    #   3.3.5
    # --> just take this as the version

    # mjml 4.x outputs two rows:
    #   mjml-core: 4.0.0
    #   mjml-cli: 4.0.0
    # --> we take the second number as the version, since we call the cli

    case ver.count("\n")
    when 1
      # one line, mjml 3.x
      match = ver.match(VERSION_3_REGEX)
    when 2
      # two lines, might be 4.x
      match = ver.match(VERSION_4_REGEX)
    end

    match.nil? ? nil : match[1]
  end

  def self.logger
    config.logger
  end
end

MJML.setup!

require 'tilt/mjml' if defined?(Tilt)
require 'sprockets/mjml' if defined?(Sprockets)
require 'mjml/railtie' if defined?(Rails)
