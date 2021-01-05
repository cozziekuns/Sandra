require_relative './parser.rb'
require_relative './configuration_util.rb'
require_relative './node.rb'

@memo = {}

def simulate(node, wall_tiles, wall, draws)
  @memo[draws] ||= {}

  return @memo[draws][node] if @memo[draws].has_key?(node)

  agari_chance = 0

  return agari_chance if draws == 0

  advance_chance = 1

  node.mentsu_configuration_list.outs.each { |out|
    tsumo_chance = 1.0 * wall_tiles[out] / wall
    advance_chance -= tsumo_chance

    new_wall_tiles = wall_tiles.clone
    new_wall_tiles[out] -= 1

    best_discard_agari_rate = -1

    if node.mentsu_configuration_list.shanten == 1
      best_discard_agari_rate = tsumo_chance
    else
      node.children[out].keys.each { |discard|
        agari_rate = tsumo_chance * simulate(node.children[out][discard], new_wall_tiles, wall - 1, draws - 1)
        best_discard_agari_rate = [agari_rate, best_discard_agari_rate].max
      }
    end

    agari_chance += best_discard_agari_rate
  }

  advance_agari_rate = simulate(node, wall_tiles, wall - 1, draws - 1)

  @memo[draws][node] = agari_chance + advance_chance * advance_agari_rate
  return @memo[draws][node]
end

# hand = '56788m456p46888s'
# hand = '288m1356899p348s'
# hand = '1122338m3457p23s'
# hand = '12345699m2356s9s'
# hand = '34m3489p44579s12z'
# hand = '133m224679p779s1z'
parsed_hand = Parser.parse_hand(hand)

wall_tiles = Array.new(34, 4)
parsed_hand.each { |tile| wall_tiles[tile] -= 1 }

t = Time.now

configuration_list = ConfigurationUtil.configuration_list_from_hand(parsed_hand)
node = Node_Configuration.new(configuration_list)

18.downto(1) { |draws| p simulate(node, wall_tiles, 123 - (18 - draws), draws) }

p Time.now - t
