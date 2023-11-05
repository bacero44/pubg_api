# frozen_string_literal: true

require 'httparty'

CONFIG = YAML.load_file('secrets.ylm')
ITEMS = YAML.load_file('items.ylm')

# pubg class to get info from API
class Pubg
  class << self
    def get_player(platform, player_name)
      response = request("https://api.pubg.com/shards/#{platform}/players?filter[playerNames]=#{player_name}")
      if response
        player(response[0])
      else
        false
      end
    end

    def get_player_by_id(platform, id)
      response = request("https://api.pubg.com/shards/#{platform}/players/#{id}")
      player(response)
    end

    def get_lifetime(platform, id)
      response = request("https://api.pubg.com/shards/#{platform}/players/#{id}/seasons/lifetime")
      get_stats(response)
    end

    def get_weapon_mastery(platform, id)
      response = request("https://api.pubg.com/shards/#{platform}/players/#{id}/weapon_mastery")
      get_weapon_summaries(response)
    end

    private

    def request(url)
      puts "------------------------------------------- peticion"
      response = HTTParty.get(url, headers: {
        'Content-Type' => 'application/json',
        'accept' => 'application/vnd.api+json',
        'Authorization' => "Bearer #{CONFIG['pubg_api_key']}"
      })
      response.code == 200 ? response['data'] : false
    end

    def player(payload)
      {
        id: get_id(payload),
        clan_id: get_clan_id(payload),
        ban_type: get_ban_type(payload),
        matches: get_matches(payload)
      }
    end

    def get_id(payload)
      payload['id']
    end

    def get_clan_id(payload)
      payload['attributes']['clanId']
    end

    def get_ban_type(payload)
      payload['attributes']['banType']
    end

    def get_matches(payload)
      payload['relationships']['matches']['data'].map { |hash| hash['id'] }
    end

    def get_stats(payload)
      payload['attributes']['gameModeStats']
    end

    def get_weapon_summaries(payload)
      payload['attributes']['weaponSummaries'].each { |item, data| data['name'] = ITEMS[item] }
    end

  end
end
