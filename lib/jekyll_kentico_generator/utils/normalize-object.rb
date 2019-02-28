module Utils
  class << self
    def normalize_object(object)
      stringify_all_keys(to_hash(object))
    end

  private
    def open_struct_values_to_hash(struct)
      hash = {}
      struct.each_pair do |key, value|
        hash[key] = to_hash value
      end
      hash
    end

    def hash_values_to_hash(hash)
      hash.reduce({}) do |reduced, pair|
        key = pair[0]
        value = pair[1]
        new_pair = { key => to_hash(value) }
        reduced.merge new_pair
      end
    end

    def to_hash(object)
      case object
      when OpenStruct then open_struct_values_to_hash object
      when Array then array_values_to_hash object
      when Hash then hash_values_to_hash object
      else object
      end
    end

    def stringify_all_keys_in_array(array)
      array.map do |item|
        case item
        when Hash then stringify_all_keys_in_hash item
        when Array then stringify_all_keys_in_array item
        else item
        end
      end
    end

    def stringify_all_keys_in_hash(hash)
      stringified_hash = {}
      hash.each do |k, v|
        stringified_hash[k.to_s] = case v
                                   when Array then stringify_all_keys_in_array v
                                   when Hash then stringify_all_keys_in_hash v
                                   else v
                                   end
      end
      stringified_hash
    end

    def stringify_all_keys(object)
      case object
      when Hash then stringify_all_keys_in_hash object
      when Array then stringify_all_keys_in_array object
      else object
      end
    end

    def array_values_to_hash(array)
      array.map do |item|
        case item
        when Array then array_values_to_hash item
        when Hash then hash_values_to_hash item
        when OpenStruct then open_struct_values_to_hash item
        else item
        end
      end
    end
  end
end