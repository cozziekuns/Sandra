require_relative './tile_util.rb'

#==============================================================================
# ** MentsuConfiguration
#==============================================================================

class MentsuConfiguration

  attr_reader   :blocks
  attr_reader   :shanten

  def initialize(blocks)
    @blocks = blocks
    @shanten = calc_shanten
    @outs_to_block_index = nil
  end

  def calc_shanten(max_mentsu=4)
    usable_blocks = @blocks.select { |block| block.length > 1 }

    return max_mentsu * 2 - usable_blocks.inject(0) { |sum, block| sum + block.length - 1 }
  end

  def outs
    return outs_to_block_index.keys
  end

  def outs_to_block_index
    return @outs_to_block_index unless @outs_to_block_index.nil?

    @outs_to_block_index = {}

    usable_atama = @blocks.select { |block| block.length == 2 and block[0] == block[1] }.length
    usable_blocks = @blocks.select { |block| block.length > 1 }.length

    @blocks.each.with_index { |block, i|
      next if block.length == 3
      next if usable_atama == 1 and usable_blocks == 5 and block.length == 2 and block[0] == block[1]

      if block.length == 2 or (usable_blocks < 5 and usable_atama > 0) or usable_blocks < 4
        get_outs_for_block(block).each { |out|
          @outs_to_block_index[out] ||= []
          @outs_to_block_index[out].push(i)
        }
      elsif block.length == 1 and usable_blocks == 4 and usable_atama == 0
        # When we have four blocks but no atama, only float becoming atama decreases shanten
        @outs_to_block_index[block[0]] ||= []
        @outs_to_block_index[block[0]].push(i)
      end
    }

    return @outs_to_block_index
  end

  def get_outs_for_block(block)
    outs = []

    return [block[0]] if TileUtil.tile_value(block[0]) == 10

    if block.length == 1
      -2.upto(2) { |i|
        tile_value = TileUtil.tile_value(block[0]) + i
        next unless tile_value.between?(1, 9)

        outs.push(block[0] + i)
      }
    else
      return [block[0]] if block[0] == block[1]
      return [block[0] + 1] if block[0] + 2 == block[1]

      outs.push(block[0] - 1) if TileUtil.tile_value(block[0]) > 1
      outs.push(block[1] + 1) if TileUtil.tile_value(block[1]) < 9
    end

    return outs
  end

end
