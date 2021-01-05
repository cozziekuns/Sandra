#==============================================================================
# ** Node_Configuration
#==============================================================================

class Node_Configuration

  attr_reader   :children
  attr_reader   :mentsu_configuration_list

  @@memo = {}

  def initialize(mentsu_configuration_list)
    @mentsu_configuration_list = mentsu_configuration_list
    create_children

    @@memo[hashcode] = self
  end

  def memo_size
    puts @@memo.keys
    return @@memo.keys.length
  end

  def hashcode
    return mentsu_configuration_list.configurations[0].blocks.flatten.join(',')
  end

  def create_children
    @children = {}

    return if @mentsu_configuration_list.shanten == 0

    @mentsu_configuration_list.outs_map.each { |out, configurations|
      floats = {}
      discard_to_configuration_map = {}

      configurations.each { |configuration|
        configuration.outs_to_block_index[out].each { |i|
          new_blocks = configuration.blocks.clone

          new_blocks[i] = new_blocks[i] + [out]
          new_blocks[i].sort!

          new_blocks.each.with_index { |block, i|
            next unless block.length == 1

            new_new_blocks = new_blocks.clone
            new_new_blocks.delete_at(i)

            hashcode = new_new_blocks.flatten.join(',')

            if @@memo[hashcode]
              discard_to_configuration_map[block[0]] = @@memo[hashcode]
            else
              floats[block[0]] ||= []
              floats[block[0]].push(MentsuConfiguration.new(new_new_blocks))
            end
          }
        }
      }

      floats.keys.each { |key|
        configuration_list = ConfigurationList.new(floats[key])
        child_node = Node_Configuration.new(configuration_list)

        discard_to_configuration_map[key] = child_node
      }

      @children[out] = discard_to_configuration_map
    }
  end

end
