# frozen_string_literal: true

# Main class of player
class Player
  attr_reader :player_name, :id, :platform, :lifetime, :weapon_mastery, :clan_id, :ban_type, :matches
  
  def initialize(platform, name)
    @player_name = name
    @platform = platform
   
    find_player

    if fund?
      Db.keep_player(@platform, @player_name, @id, @clan_id, @ban_type) unless Db.player_exist?(@platform, @player_name)
      update_stats if update_stats?(Db.lifetime?(id))

      fill(Db.player(@id))
    end
  end

  def fund?
    @id ? true : false
  end

  def data
    {
      "data":
        {
          "player_name": @player_name,
          "platform": @platform,
          "clan_id": @clan_id,
          "ban_type": @ban_type,
          "lifetime": @lifetime,
          "weapon_mastery": @weapon_mastery,
          "matches": @matches
        }
    }
  end

  private

  def find_player
    c = Db.player_exist?(@platform, @player_name) ? Db : Pubg
    t = c.get_player(@platform, @player_name)
    if t
      fill(t)
    else
      @id = false
    end
  end

  def fill(payload)
    @id = payload[:id]
    @clan_id = payload[:clan_id]
    @ban_type = payload[:ban_type]
    @matches = payload[:matches]
    @weapon_mastery = payload[:weapon_mastery]
    @lifetime = payload[:lifetime]
  end

  def update_stats
    Db.keep_weapon_mastery(Pubg.get_weapon_mastery(@platform, @id), @id)
    Db.keep_lifetime(Pubg.get_lifetime(@platform, @id), @id)
    Db.keep_update_player(Pubg.get_player_by_id(@platform, @id), @id)
  end

  def update_stats?(date)
    date && date > Time.now - 2 * 60 ? false : true
  end
end
