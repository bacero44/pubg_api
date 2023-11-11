# frozen_string_literal: true

require 'httparty'

CONFIG = YAML.load_file('secrets.ylm')
ITEMS = YAML.load_file('items.ylm')
MAPS = YAML.load_file('maps.ylm')

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

    def get_match(platform, id)
      response = match_request("https://api.pubg.com/shards/#{platform}/matches/#{id}")
      response ? get_match_summary(response) : false
    end

    private

    def request(url)
      # puts '------------------------------------------- peticion'
      response = HTTParty.get(url, headers:
        {
          'Content-Type' => 'application/json',
          'accept' => 'application/vnd.api+json',
          'Authorization' => "Bearer #{CONFIG['pubg_api_key']}"
        })
      response.code == 200 ? response['data'] : false
    end

    def match_request(url)
      # puts '------------------------------------------- peticion MATCH'
      response = HTTParty.get(url, headers:
        {
          'Content-Type' => 'application/json',
          'accept' => 'application/vnd.api+json'
        })
      response.code == 200 ? response : false
    end

    def telemetry_request(url)
      # puts '------------------------------------------- peticion TELEMETRY'
      response = HTTParty.get(url)
    end

    def player(payload)
      {
        id: get_id(payload),
        clan_id: get_clan_id(payload),
        ban_type: get_ban_type(payload),
        matches: get_player_matches(payload)
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

    def get_player_matches(payload)
      payload['relationships']['matches']['data'].map { |hash| hash['id'] }
    end

    def get_stats(payload)
      payload['attributes']['gameModeStats']
    end

    def get_weapon_summaries(payload)
      payload['attributes']['weaponSummaries'].each { |item, data| data['name'] = ITEMS[item] }
    end

    def get_match_summary(payload)
      t = get_match_telemetry(payload)
      {
        date: get_match_date(payload),
        mode: get_match_mode(payload),
        map: get_match_map(payload),
        teams: get_match_teams(payload),
        participants: get_match_participants(payload),
        telemetry: t,
        deaths: get_match_deaths(t)
      }
    end

    def get_match_date(payload)
      payload['data']['attributes']['createdAt']
    end

    def get_match_mode(payload)
      payload['data']['attributes']['gameMode']
    end

    def get_match_map(payload)
      MAPS[payload['data']['attributes']['mapName']]
    end

    def get_match_participants(payload)
      participants = payload['included'].select { |item| item['type'] == 'participant' }
      participants = participants.map do |item|
        {
          'matchPlayerId' => item['id'],
          'name' => item['attributes']['stats']['name'],
          'playerId' => item['attributes']['stats']['playerId'],
          'platform' => item['attributes']['shardId'],
          'actor' => item['attributes']['actor'],
          'stats' => item['attributes']['stats']
        }
      end
      participants.each { |item| item['stats'].delete('playerId'); item['stats'].delete('name') }
    end

    def get_match_teams(payload)
      teams = payload['included'].select { |item| item['type'] == 'roster' }
      teams.map do |item|
        {
          'id' => item['id'],
          'won' => item['attributes']['won'],
          'rank' => item['attributes']['stats']['rank'],
          'participants' => item['relationships']['participants']['data'].map { |pa| pa["id"] }
        }
      end
    end

    def get_match_telemetry(payload)
      telemetry = payload['included'].select { |item| item['type'] == 'asset' }
      telemetry[0]['attributes']['URL']
    end

    def get_match_deaths(telemetry_url)
      telemetry = telemetry_request(telemetry_url)
      telemetry.select { |t| t['_T'] == 'LogPlayerKillV2' }.map do |t|
        {
          reason: t.dig('finishDamageInfo', 'damageReason'),
          type: t.dig('finishDamageInfo', 'damageTypeCategory'),
          causer: t.dig('finishDamageInfo', 'damageCauserName'),
          victim: {
            name: t.dig('victim', 'name'),
            id: t.dig('victim', 'accountId'),
            rank: t.dig('victimGameResult', 'rank'),
            kills: t.dig('victimGameResult', 'stats', 'killCount'),
            weapon: t.dig('victim', 'victimWeapon'),
            weaponAttachments: t.dig('victim', 'victimWeaponAdditionalInfo')
          },
          killer: {
            name: t.dig('finisher', 'name'),
            id: t.dig('finisher', 'accountId'),
            weapon: t.dig('killerDamageInfo', 'damageCauserName'),
            weaponAttachments: t.dig('killerDamageInfo', 'additionalInfo')
          }
        }
      end
    end
  end
end
