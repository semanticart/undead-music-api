require 'rubygems'
require 'sinatra'

FileUtils.mkdir_p 'log' unless File.exists?('log')
log = File.new("log/sinatra.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)

Sinatra::Application.set :run => false, :environment => :production

require 'api'
run Sinatra::Application
