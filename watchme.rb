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
    @username = username
    @password = password
    @client = Octokit::Client.new(login: username, password: password)
  end

  def repos
    get_all(repos_url).map { |repo| repo['full_name'] }
  end

  def subscriptions
    get_all(subscriptions_url).map { |repo| repo['full_name'] }
  end

  def subscribe(repos)
    Array(repos).each do |repo|
      client.update_subscription(repo, subscribed: true)
    end
  end

  private

  attr_reader :username, :password, :client

  def repos_url
    user_json['repos_url']
  end

  def subscriptions_url
    user_json['subscriptions_url']
  end

  def user_json
    @user_json ||= get(user_url.sub('{user}', username))
  end

  def user_url
    root_json['user_url']
  end

  def root_json
    @root_json ||= get('https://api.github.com')
  end

  def get_all(url, page = 1)
    objects = get("#{url}?per_page=100&page=#{page}")

    if objects.empty?
      objects
    else
      objects + get_all(url, page + 1)
    end
  end

  def get(url)
    JSON.parse(`curl --silent -u '#{username}:#{password}' '#{url}'`)
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

unsubscribed = github.repos - github.subscriptions

if unsubscribed.any?
  puts "You own but are not watching the following:"
  unsubscribed.each { |repo| puts "  #{repo}" }
  print "Watch all these repos? (y/N): "

  unless $stdin.gets.chomp.downcase == "y"
    exit
  end

  github.subscribe(unsubscribed)
  puts "You're now watching all your own repos"
else
  puts "You're already watching all your own repos. Nice."
end
