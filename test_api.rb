ENV['RACK_ENV'] = 'test'

require_relative 'app.rb'
require 'minitest/autorun'
require 'rack/test'

class MiniTest::Spec
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end

describe 'My App' do
  it 'should get posts' do
    get '/posts'
    assert last_response, :ok?
    response = JSON.parse(last_response.body)
    refute_predicate response.count, :zero?
  end

  it 'should get post' do
    get '/post/first-post'
    assert last_response, :ok?
    response = JSON.parse(last_response.body)
    assert_equal response['id'], 'first-post'
  end

  it 'should post a new post' do
    FileUtils.rm('content/a-new-post.md') if File.exist?('content/a-new-post.md')
    post '/posts', {
      id: 'a-new-post',
      body: 'Look at all this lovely content'
    }.to_json, { 'CONTENT_TYPE' => 'application/json' }
    follow_redirect!
    assert last_response, :ok?

    response = JSON.parse(last_response.body)
    assert(response.any? { |post| post['id'] == 'a-new-post' })
  end

  it 'should delete a post' do
    unless File.exist?('content/some-test-post.md')
      File.open('content/some-test-post.md', 'w') { |f| f.write('Words words.') }
    end

    delete '/post/some-test-post'
    follow_redirect!
    assert last_response, :ok?

    response = JSON.parse(last_response.body)
    refute(response.any? { |post| post['id'] == 'some-test-post' })
  end

  require 'webmock/minitest'
  it 'should require password for status' do
    get '/status/notreal'
    assert last_response.status, 404
  end

  it 'should make a call out to pingdom ' do
    stub_request(:get, "https://api.pingdom.com/api/3.1/results/$check_id")
                 .with(
                   headers: {
                   'Authorization'=>'Bearer $PINGDOM_API_TOKEN',
                   })
                 .to_return(status: 200, body: '{
                   "activeprobes":[257],
                   "results":[
                      {"probeid":261,
                        "time":1617657276,
                        "status":"up",
                        "responsetime":1186,
                        "statusdesc":"OK",
                        "statusdesclong":"OK"
                      }]
                  }')

    get '/status/supersecret'
    assert last_response.status, 200
  end
end
