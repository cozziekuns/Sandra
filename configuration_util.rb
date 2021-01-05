require 'set'
require_relative './tile_util.rb'
require_relative './mentsu.rb'

#==============================================================================
# ** ConfigurationUtil
#==============================================================================

module ConfigurationUtil

  def self.configuration_list_from_hand(hand)
    all_configurations = calc_configurations(hand)
    min_shanten = all_configurations.map { |configuration| configuration.shanten }.min

    chiitoi_configuration = calc_chiitoi_configuration(hand)

    min_shanten_configurations = all_configurations.select { |configuration|
      configuration.shanten == min_shanten
    }

    if chiitoi_configuration.shanten < min_shanten
      return ConfigurationList.new([chiitoi_configuration]) 
    elsif chiitoi_configuration.shanten == min_shanten
      min_shanten_configurations.push(chiitoi_configuration)
    end

    return ConfigurationList.new(min_shanten_configurations)
  end
  
  def self.calc_chiitoi_configuration(hand)
    blocks = []
    seen = Set.new
    
    i = 0
    while i < hand.length    
      if i < hand.length - 1 and hand[i] == hand[i + 1] and not seen.include?(hand[i])
        blocks.push([hand[i], hand[i]])
        i += 2
      else
        blocks.push([hand[i]])
        i += 1
      end
    end
    
    return ChiitoiConfiguration.new(blocks)
  end

  def self.calc_configurations(hand)
    max_mentsu = 4
    queue = [[hand, [], 0, false]]

    while queue.length > 0
      current_hand, old_hand, mentsu_count, has_atama = queue.shift

      # Return all the configurations in the queue that have been fully parsed.
      if current_hand.empty?
        new_configuration = MentsuConfiguration.new(old_hand)

        completed_configurations = queue.select { |element| element[0].empty? }
        completed_configurations.map! { |element| MentsuConfiguration.new(element[1]) }

        return [new_configuration] + completed_configurations
      end

      if current_hand.length > 2 and mentsu_count < max_mentsu
        add_ankou_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
        add_shuntsu_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
      end

      if current_hand.length > 1
        if not has_atama or mentsu_count < max_mentsu
          add_toitsu_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
        end

        if mentsu_count < max_mentsu
          add_ryanmen_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
          add_kanchan_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
        end
      end

      add_tanki_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
    end
  end

  def self.add_ankou_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
    return if current_hand[0] != current_hand[1] or current_hand[0] != current_hand[2]

    queue.push([
      current_hand[3..-1],
      old_hand + [current_hand[0...3]],
      mentsu_count + 1,
      has_atama,
    ])
  end

  def self.add_shuntsu_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
    return if TileUtil.tile_value(current_hand[0]) >= 8

    mid_tile_index = current_hand.index(current_hand[0] + 1)
    upper_tile_index = current_hand.index(current_hand[0] + 2)

    return if mid_tile_index.nil? or upper_tile_index.nil?

    new_hand = current_hand.clone
    new_hand.delete_at(upper_tile_index)
    new_hand.delete_at(mid_tile_index)
    new_hand.shift

    queue.push([
      new_hand,
      old_hand + [[current_hand[0], current_hand[0] + 1, current_hand[0] + 2]],
      mentsu_count + 1,
      has_atama,
    ])
  end

  def self.add_toitsu_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
    return if current_hand[0] != current_hand[1]

    queue.push([
      current_hand[2..-1],
      old_hand + [current_hand[0...2]],
      (has_atama ? mentsu_count + 1 : mentsu_count),
      true,
    ])
  end

  def self.add_taatsu_configuration(queue, current_hand, old_hand, mentsu_count, has_atama, offset=1)
    return if TileUtil.tile_value(current_hand[0]) >= 10 - offset

    upper_tile_index = current_hand.index(current_hand[0] + offset)

    return if upper_tile_index.nil?

    new_hand = current_hand.clone
    new_hand.delete_at(upper_tile_index)
    new_hand.shift

    queue.push([
      new_hand,
      old_hand + [[current_hand[0], current_hand[0] + offset]],
      mentsu_count + 1,
      has_atama,
    ])
  end

  def self.add_ryanmen_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
    add_taatsu_configuration(queue, current_hand, old_hand, mentsu_count, has_atama, 1)
  end

  def self.add_kanchan_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
    add_taatsu_configuration(queue, current_hand, old_hand, mentsu_count, has_atama, 2)
  end

  def self.add_tanki_configuration(queue, current_hand, old_hand, mentsu_count, has_atama)
    queue.push([
      current_hand[1..-1],
      old_hand + [[current_hand[0]]],
      mentsu_count,
      has_atama,
    ])
  end

end

#==============================================================================
# ** ConfigurationList
#==============================================================================

class ConfigurationList

  attr_reader   :tiles
  attr_reader   :outs_map
  attr_reader   :configurations

  def initialize(configurations)
    @configurations = configurations
    @tiles = @configurations[0].blocks.flatten.sort
    create_outs_map
  end

  def create_outs_map
    @outs_map = {}

    @configurations.each { |configuration|
      configuration.outs.each { |out|
        @outs_map[out] ||= []
        @outs_map[out].push(configuration)
      }
    }
  end

  def outs
    return @outs_map.keys
  end

  def shanten
    return @configurations[0].shanten
  end

end
