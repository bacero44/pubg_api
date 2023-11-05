# frozen_string_literal: true

# Class for matches
class Match
  attr_reader :id, :platform, :data
  def initialize(platform, id)
    @id = id
    @platform = platform
    @data = nil
    @local_info = true

    find_match
    if !@data.nil? && !@local_info
      puts "entra a guardar en match"
      Db.keep_match(@platform, @id, @data)
    end
  end

  private

  def find_match
    db = Db.get_match(@platform, @id)
    @local_info = false unless db
    db ||= Pubg.get_match(@platform, @id) unless db
    @data = db if db
  end
end
