#!/usr/bin/env ruby
require 'erb'
require 'git'
require 'json'
require 'kubeclient'

require_relative 'lib/git_helper'
require_relative 'lib/haproxy'
require_relative 'lib/watcher'

base_dir = File.absolute_path File.dirname(__FILE__)
git_helper = GitHelper.new File.join(base_dir, 'proxy-config')
git_helper.clone_or_update

config = YAML.load_file File.join(base_dir, 'proxy-config', 'config.yml')

watcher = Watcher.new base_dir, config, git_helper
watcher.update
watcher.watch
