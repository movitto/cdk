module CDK
  module Bindings
    attr_reader :binding_list

    def init_bindings
      # Bound functions
      @binding_list = {}
    end

    def bindableObject(cdktype)
      if cdktype != self.object_type
        return nil
      elsif [:FSELECT, :ALPHALIST].include?(self.object_type)
        return @entry_field
      else
        return self
      end
    end

    def bind(type, key, function, data)
      obj = self.bindableObject(type)
      if key.ord < Ncurses::KEY_MAX && !(obj.nil?)
        if key.ord != 0
          obj.binding_list[key.ord] = [function, data]
        end
      end
    end

    def unbind(type, key)
      obj = self.bindableObject(type)
      unless obj.nil?
        obj.binding_list.delete(key)
      end
    end

    def cleanBindings(type)
      obj = self.bindableObject(type)
      if !(obj.nil?) && !(obj.binding_list.nil?)
        obj.binding_list.clear
      end
    end

    # This checks to see if the binding for the key exists:
    # If it does then it runs the command and returns its value, normally true
    # If it doesn't it returns a false.  This way we can 'overwrite' coded
    # bindings.
    def checkBind(type, key)
      obj = self.bindableObject(type)
      if !(obj.nil?) && obj.binding_list.include?(key)
        function = obj.binding_list[key][0]
        data = obj.binding_list[key][1]

        if function == :getc
          return data
        else
          return function.call(type, obj, data, key)
        end
      end
      return false
    end

    # This checks to see if the binding for the key exists.
    def isBind(type, key)
      result = false
      obj = self.bindableObject(type)
      unless obj.nil?
        result = obj.binding_list.include?(key)
      end

      return result
    end
  end # module Bindings
end # module CDK
