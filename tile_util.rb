#==============================================================================
# ** TileUtil
#==============================================================================

module TileUtil

  def self.tile_value(tile)
    return 10 if self.jihai?(tile)
    return tile % 9 + 1
  end

  def self.tile_suit(tile)
    return -1 if self.jihai?(tile)
    return tile / 9
  end

  def self.jihai?(tile)
    return tile >= 27
  end

end
