#!/usr/bin/env ruby
require 'erb'
require 'git'
require 'json'
require 'kubeclient'
require 'test-unit'

require_relative '../lib/git_helper'
require_relative '../lib/haproxy'
require_relative '../lib/watcher'

$base_dir = File.absolute_path File.join(File.dirname(__FILE__), '..')

# Execute tests
require_relative 'lib/git_helper_test'
