require_relative './parser.rb'
require_relative './configuration_util.rb'
require_relative './node.rb'

@memo = []

def simulate(node, wall, draws)
  @memo[draws] ||= {}

  return @memo[draws][node] if @memo[draws].has_key?(node)
  return 0 if node.mentsu_configuration_list.shanten >= draws

  agari_chance = 0
  advance_tiles = wall
  
  if draws == 1
    node.mentsu_configuration_list.outs.each { |out|
      tiles_in_wall = 4 - node.mentsu_configuration_list.tiles.count(out)
      agari_chance += 1.0 * tiles_in_wall / wall
    }
    
    return agari_chance
  end
  
  advance_agari_rate = simulate(node, wall - 1, draws - 1)

  node.mentsu_configuration_list.outs.each { |out|
    tiles_in_wall = 4 - node.mentsu_configuration_list.tiles.count(out)
    advance_tiles -= tiles_in_wall

    best_discard_agari_rate = advance_agari_rate

    if node.mentsu_configuration_list.shanten == 0
      best_discard_agari_rate = 1
    else
      node.children[out].keys.each { |discard|
        agari_rate = simulate(node.children[out][discard], wall - 1, draws - 1)
        best_discard_agari_rate = [agari_rate, best_discard_agari_rate].max
      }
    end

    agari_chance += 1.0 * tiles_in_wall * best_discard_agari_rate / wall
  }

  @memo[draws][node] = agari_chance + advance_tiles * advance_agari_rate / wall
  return @memo[draws][node]
end

# hand = '56788m456p46888s'
# hand = '288m1356899p348s'
# hand = '1122338m3457p23s'
# hand = '12345699m2356s9s'
# hand = '345m3489p44579s1z'
# hand = '133m224679p779s1z'
hand = '12269m67p245s123z'
# hand = '12266m678p224s22z'
# hand = '123456789m19p19s'
# hand = '112234m7799s245p'
# hand = '112299m67p45s123z'

# "0,0,1,1,8,14,15,19,21,22,27,28,29"
# "0,0,1,1,8,8,14,15,19,21,22,28,29"

parsed_hand = Parser.parse_hand(hand)

t = Time.now

configuration_list = ConfigurationUtil.configuration_list_from_hand(parsed_hand)

p Time.now - t

node = Node_Configuration.new(configuration_list)
p Time.now - t
p node.memo_size

18.downto(1) { |draws| p simulate(node, 123 - (18 - draws), draws) }

p Time.now - t

__END__

draw = 15

@memo[draw].keys.each { |node|
  p node.hashcode
  p @memo[draw][node]
}

p Time.now - t
