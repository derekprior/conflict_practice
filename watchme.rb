#!/usr/bin/env ruby
#
# $ curl -o watchme.rb 'https://gist.github.com/pbrisbin/8030960/raw/watchme.rb'
# $ ruby ./watchme.rb
#
###
require 'json'
require 'octokit'

class GitHub
  def initialize(username, password)
    Octokit.configure do |config|
      config.login = username
      config.password = password
    end
  end

  def repositories
    @repos ||= Octokit.repositories
  end

  def subscriptions
    @subscriptions ||= Octokit.subscriptions
  end

  def unwatched
    @unwatched ||= repositories - subscriptions
  end
end

begin
  print "username: "
  username = $stdin.gets.chomp

  print "password: "
  system("stty -echo") # hides pw as it's typed
  password = $stdin.gets.chomp
ensure
  system("stty echo")
  puts
end

github = GitHub.new(username, password)

if github.unwatched.any?
  puts "You own but are not watching the following:"

  github.unwatched.each do |repo|
    puts "https://github.com/#{repo.full_name}"
  end
else
  Octokit.say "You're watching all your own repos. Nice."
end
