#==============================================================================
# ** Parser
#==============================================================================

module Parser

  def self.parse_hand(hand)
    suits = ['m', 'p', 's', 'z']

    result = []
    temp = []

    hand.each_char { |char|
      if suits.include?(char)
        result += temp.map { |tile| tile + suits.index(char) * 9 }
        temp.clear
      elsif char[/\d/]
        temp.push(char.to_i - 1)
      end
    }

    return result.sort
  end

end
