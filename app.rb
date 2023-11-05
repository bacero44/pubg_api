# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require_relative('helpers')

Dir[settings.root + '/classes/*.rb'].sort.each { |file| require file }

$valid_parameters = YAML.load_file('api_parameters.ylm')

also_reload settings.root + '/classes/player.rb'
also_reload settings.root + '/classes/db.rb'
also_reload settings.root + '/classes/pubg.rb'

before do
  content_type :json
  # headers 'Access-Control-Allow-Origin' => '*'
end

get '/' do
  "Hi super bacero44"
end

get '/platforms' do
  json_response($valid_parameters['platforms'], 200)
end

get '/:platform/:playerName' do
  
  if valid_platform?
    platform = params[:platform]
    player_name = params[:playerName]
    player = Player.new(platform, player_name)

    if !player.id
      json_response({ "message": " We can't fund the player", "data": 'no data' }, 404)
    else
      json_response(player.data, 200)
    end

  else
    json_response({ "message": 'Invalid Platform', "data": 'no data' }, 400)
  end

end

def valid_platform?
  $valid_parameters['platforms'].include?(params[:platform])
end
