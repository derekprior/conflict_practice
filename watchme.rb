#!/usr/bin/env ruby
#
# $ curl -o watchme.rb 'https://gist.github.com/pbrisbin/8030960/raw/watchme.rb'
# $ ruby ./watchme.rb
#
###
require 'json'

class GitHub
  def initialize(username, password)
    @username = username
    @password = password
  end

  def repos
    get_all(repos_url).map { |repo| repo['full_name'] }
  end

  def subscriptions
    get_all(subscriptions_url).map { |repo| repo['full_name'] }
  end

  private

  attr_reader :username, :password

  def repos_url
    user_json['repos_url']
  end

  def subscriptions_url
    user_json['subscriptions_url']
  end

  def user_json
    @user_json ||= get(user_url.sub('{user}', @username))
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

watchme = github.repos - github.subscriptions

if watchme.any?
  puts "You own but are not watching the following:"

  watchme.each do |repo|
    puts "https://github.com/#{repo}"
  end
else
  puts "You're watching all your own repos. Nice."
end
