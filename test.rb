# Men Tsumo, Pinfu, Tanyao, Dora, Riichi, Yakuhai, Iipeikou, Sanshoku, Chanta
# In terms of pure score EV, in terms of pure placement EV
# How do we handle uradora???

#==============================================================================
# ** Util
#==============================================================================

module Util

  def self.tile_value(tile)
    return 0 if self.jihai?(tile)
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

#==============================================================================
# ** Parser
#==============================================================================

module Parser

  def self.parse_tile(tile)
    tmp = parse_hand(tile)

    # TODO: Better exception handling here.
    raise Exception if tmp.length != 1

    return tmp.first
  end

  def self.parse_hand(hand)
    suits = ['m', 'p', 's', 'z']

    result = []
    tmp = []

    hand.each_char { |char|
      if suits.include?(char)
        result += tmp.map { |tile| tile + suits.index(char) * 9 }
      elsif char[/\d/]
        tmp.push(char.to_i - 1)
      else
        # TODO: Figure out what kind of exception we actually want to 
        # throw here.
        raise Exception
      end
    }

    return result
  end

end

#==============================================================================
# ** Game_Hand
#==============================================================================

class Game_Hand

  attr_reader   :tiles
  attr_reader   :open_mentsu

  def initialize(tiles, open_mentsu)
    @tiles = tiles
    @open_mentsu = []
  end

  def all_tiles
    @tiles + @open_mentsu.flatten
  end

  def jihai_tiles
    all_tiles.select { |tile| Util.jihai?(tile) }
  end

end

#==============================================================================
# ** Game_Board
#==============================================================================

class Game_Board
  
  attr_reader   :dora
  attr_reader   :round
  attr_reader   :homba
  attr_reader   :riichi

  def initialize(round, dora, homba=0, riichi=0)
    @round = round
    @dora = []
    @homba = homba
    @riichi = riichi
  end

  def table_wind
    @round % 4
  end

end

#==============================================================================
# ** Game_Player
#==============================================================================

class Game_Player

  attr_reader   :index
  attr_reader   :hand
  attr_reader   :riichi
  attr_reader   :seat_wind
  attr_accessor :tsumo_tile

  def initialize(index, hand, seat_wind)
    @index = index
    @hand = Game_Hand.new(hand, [])
    @seat_wind = seat_wind
    @tsumo_tile = nil
    @riichi = false
  end

  def oya?
    return @seat_wind == 0
  end

end

#==============================================================================
# ** Scorer
#==============================================================================

module Scorer

  def self.score_hand(board, player, target)
    score = self.score_base_hand(board, player, target) 

    score[player.index] += board.riichi * 1000 
    score[player.index] += board.homba * 300

    if target == player.index
      other_players = (0.upto(3).to_a - [player.index])
      other_players.each { |i| score[i] -= board.homba * 100 }
    else
      score[target.index] -= board.homba * 300
    end

    return score
  end

  def self.score_base_hand(board, player, target)
    han = self.calculate_han(board, player)
    fu = self.calculate_fu(board, player)

    return self.calculate_score(han, fu, player, target)
  end

  def self.calculate_score(han, fu, player, target)
    results = [0, 0, 0, 0]
    base_points = fu * 2 ** (2 + han)

    if target == player.index
      if player.oya?
        payment = (2 * base_points).round(-2)

        results = [-1 * payment] * 4 
        results[player.index] = 3 * (2 * base_points).round(-2)
        return results
      else
        oya = ((4 - player.seat_wind) + player.index) % 4
        
        results = [-1 * base_points.round(-2)] * 4
        results[oya] = -1 * (2 * base_points).round(-2)
        results[player.index] = (2 * base_points).round(-2) + 2 * base_points.round(-2)
      end
    else
      if player.oya?
        results[player.index] = (6 * base_points).round(-2)
        results[target] = -(6 * base_points).round(-2)
      else
        results[player.index] = (4 * base_points).round(-2)
        results[target] = -(4 * base_points).round(-2)
      end
    end

    return results
  end

  def self.calculate_han(board, player)
    is_closed = player.hand.open_mentsu.empty?

    han = 0

    han += 1 if player.riichi
    han += 1 if self.menzen_tsumo?(player, is_closed)
    han += self.dora(board, player)
    han += self.yakuhai(board, player)
    han += 1 if self.is_pinfu?(player.hand, is_closed)
    han += 1 if self.is_tanyao?(player.hand)
    han += 2 if self.is_chiitoi?(player.hand, is_closed)

    if self.is_chiniitsu?(player.hand)
      han += (is_closed ? 6 : 5)
    elsif self.is_honiitsu?(player.hand)
      han += (is_closed ? 3 : 2)
    end

    return han
  end

  def self.calculate_fu(board, player)
    return 30
  end

  def self.dora(board, player)
    total = 0

    board.dora.each { |dora_tile|
      total += player.hand.tiles.select { |tile| dora_tile.include?(tile) }.length
    }

    return total
  end

  def self.menzen_tsumo?(player, is_closed)
    return false if player.tsumo_tile.nil?
    return is_closed
  end

  def self.yakuhai(board, player)
    total = 0

    table_wind = 27 + board.table_wind
    seat_wind = 27 + player.seat_wind
    yakuhai_tiles = ([31, 32, 33] + [seat_wind] + [table_wind])

    yakuhai_tiles.each { |yakuhai|
      total += 1 if player.hand.jihai_tiles.select { |tile| 
        tile == yakuhai 
      }.length >= 3
    }

    return total
  end

  # TODO: Figure out how to do pinfu
  def self.is_pinfu?(hand, is_closed)
    return false if not is_closed
    return false
  end

  def self.is_chiitoi?(hand, is_closed)
    return false if not is_closed

    0.upto(6) { |i| 
      return false if hand.tiles[2 * i] != hand.tiles[2 * i + 1]
    }

    return hand.tiles.uniq.length == 7
  end

  def self.is_tanyao?(hand)
    return hand.all_tiles.all? { |tile|
      Util.tile_value(tile).between?(2, 8)
    }
  end

  def self.is_honiitsu?(hand)
    return false if Util.jihai?(hand.all_tiles[0])

    suit = Util.tile_suit(hand.all_tiles[0])

    return hand.all_tiles.all? { |tile| 
      Util.jihai?(tile) or Util.tile_suit(tile) == suit
    }
  end

  def self.is_chiniitsu?(hand)
    return false if Util.jihai?(hand.all_tiles[0])

    suit = Util.tile_suit(hand.all_tiles[0])

    return hand.all_tiles.all? { |tile| Util.tile_suit(tile) == suit }
  end

end

#==============================================================================
# ** Main
#==============================================================================

@tiles = '56788m456p46888s'
@tsumo_tile = '5s'

board = Game_Board.new(0, Parser.parse_tile('2s'), 1, 1)

player = Game_Player.new(2, Parser.parse_hand(@tiles), 2)
player.tsumo_tile = Parser.parse_tile(@tsumo_tile)

p Scorer.score_hand(board, player, target=player.index)