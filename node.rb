#==============================================================================
# ** Node_Configuration
#==============================================================================

class Node_Configuration

  attr_reader   :children
  attr_reader   :mentsu_configuration_list

  @@memo = {}
  @@memo_children = {}

  def initialize(mentsu_configuration_list)
    @mentsu_configuration_list = mentsu_configuration_list
    create_children

    @@memo[hashcode] = self
  end

  def memo_size
    return @@memo.keys.length
  end

  def hashcode
    return mentsu_configuration_list.tiles.join(',')
  end

  def create_children
    @children = {}

    return if @mentsu_configuration_list.shanten == 0
    
    curr_tiles = @mentsu_configuration_list.tiles

    @mentsu_configuration_list.outs_map.each { |out, configurations|
      floats = {}
      discard_to_configuration_map = {}
      
      curr_tiles.push(out)
      hashcode_child = curr_tiles.sort.join(',')
      
      if @@memo_children[hashcode_child]
        @children[out] = @@memo_children[hashcode_child]
        curr_tiles.pop
        next
      end

      configurations.each { |configuration|
        configuration.outs_to_block_index[out].each { |j|  
          configuration.blocks.each.with_index { |block_to_replace, i|
            next if j == i
            next unless block_to_replace.length == 1
            
            # Cloning is slow, so we avoid it at all costs
            temp = curr_tiles.index(block_to_replace[0])
            curr_tiles.delete_at(temp)
            hashcode = curr_tiles.sort.join(',')
            curr_tiles.insert(temp, block_to_replace[0])
            
            if @@memo[hashcode]
              discard_to_configuration_map[block_to_replace[0]] = @@memo[hashcode]
              next
            end

            new_blocks = configuration.blocks.clone
            new_blocks[j] = new_blocks[j] + [out]
            new_blocks[j].sort!
            new_blocks.delete_at(i)
            
            floats[block_to_replace[0]] ||= []
            floats[block_to_replace[0]].push(configuration.class.new(new_blocks))
          }
        }
      }

      floats.keys.each { |key|
        configuration_list = ConfigurationList.new(floats[key])
        child_node = Node_Configuration.new(configuration_list)

        discard_to_configuration_map[key] = child_node
      }

      @children[out] = @@memo_children[hashcode_child] = discard_to_configuration_map
      curr_tiles.pop
    }
  end

end
