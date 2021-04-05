# frozen_string_literal: true

require 'sinatra'
require 'json'
require 'net/http'

get '/' do
  'Hello, world!'
end

get '/posts' do
  posts = Dir.entries('content').each_with_object([]) do |filename, arr|
    next if filename == '.' || filename == '..'

    arr << { id: File.basename(filename, '.md'), body: File.read("content/#{filename}") }
  end
  posts.to_json
end

get '/post/:id' do
  filename = params[:id]
  { id: filename, body: File.read("content/#{filename}.md") }.to_json
end

post '/posts' do
  request.body.rewind
  data = JSON.parse(request.body.read)
  File.open("content/#{data['id']}.md", 'w') { |f| f.write(data['body']) }
  redirect '/posts'
end

delete '/post/:id' do
  id = params[:id]
  FileUtils.rm("content/#{id}.md")
  redirect '/posts'
end

require 'httparty'

get '/status/:password' do
  return 404 if params[:password].nil? || params[:password] != 'supersecret'

  url = 'https://api.pingdom.com/api/3.1/results/$check_id'
  headers = {
    Authorization: 'Bearer $PINGDOM_API_TOKEN'
  }

  response = HTTParty.get(url, headers: headers)
  JSON.parse(response.body)
end
