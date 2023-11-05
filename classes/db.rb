# frozen_string_literal: true

require 'mongo'

MONGO = Mongo::Client.new(['127.0.0.1:27017'], database: 'pubg')
PLAYERS = MONGO[:players]
MATCHES = MONGO[:matches]

# Class for data base
class Db
  class << self
    def keep_player(platform, player_name, id, clan_id, ban_type)
      save_player(platform, player_name, id, clan_id, ban_type) unless player_exist?(platform, player_name)
    end

    def player_exist?(platform, player_name)
      PLAYERS.find({ "platform": platform, "player_name": player_name }).count.positive? ? true : false
    end

    def get_player(platform, player_name)
      get_collection(platform, player_name)
    end

    def keep_lifetime(payload, id)
      save_timelife(payload, id)
    end

    def lifetime?(id)
      c = get_collection_by_id(id)
      c.key?('updated') ? c['updated'] : false
    end

    def get_lifetime(id)
      get_collection_by_id(id)['lifetime']
    end

    def keep_weapon_mastery(payload, id)
      save_weapon_mastery(payload, id)
    end

    def get_weapon_mastery(id)
      get_collection_by_id(id)['weapon_mastery']
    end

    def keep_matches(payload, id)
      save_player_matches(payload, id)
    end

    def keep_update_player(payload, id)
      update_player(payload, id)
    end

    def get_player_matches(id)
      get_collection_by_id(id)['matches']
    end

    def get_match(platform, id)
      match(platform, id)
    end

    def keep_match(platform, id, data)
      save_match(platform, id, data)
    end

    private

    def get_collection(platform, player_name)
      PLAYERS.find({ "platform": platform, "player_name": player_name }).first
    end

    def get_collection_by_id(id)
      PLAYERS.find({ "id": id }).first
    end

    def save_player(platform, player_name, id, clan_id, ban_type)
      PLAYERS.insert_one(
        {
          "id": id,
          "platform": platform,
          "player_name": player_name,
          "clan_id": clan_id,
          "ban_type": ban_type
        }
      )
    end

    def update_player(payload, id)
      PLAYERS.update_one(
        { "id": id },
        {
          "$set":
          {
            "clan_id": payload[:clan_id], "ban_type": payload[:ban_type]
          }
        }
      )
      save_player_matches(payload[:matches], id)
    end

    def save_timelife(payload, id)
      PLAYERS.update_one({ "id": id }, { "$set": { 'lifetime' => payload, 'updated' => Time.now } })
    end

    def save_weapon_mastery(payload, id)
      PLAYERS.update_one({ "id": id }, { "$set": { 'weapon_mastery' => payload } })
    end

    def save_player_matches(payload, id)
      PLAYERS.update_one({ "id": id }, { "$set": { 'matches' => payload } })
    end

    def match(platform, id)
      m = MATCHES.find({ "platform": platform, "id": id })
      m.count.positive? ? m.first : false
    end

    def save_match(platform, id, data)
      MATCHES.insert_one(
        {
          "id": id,
          "platform": platform,
          "data": data
        }
      )
    end
  end
end
