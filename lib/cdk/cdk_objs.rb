require_relative './mixins/alignments'
require_relative './mixins/justifications'
require_relative './mixins/converters'
require_relative './mixins/movement'
require_relative './mixins/borders'
require_relative './mixins/focusable'
require_relative './mixins/bindings'
require_relative './mixins/exit_conditions'
require_relative './mixins/has_screen'
require_relative './mixins/has_title'
require_relative './mixins/window_input'
require_relative './mixins/window_hooks'
require_relative './mixins/common_controls'

module CDK
  class CDKOBJS
    include Alignments
    include Justifications
    include Converters
    include Movement
    include Borders
    include Focusable
    include Bindings
    include ExitConditions
    include HasScreen
    include HasTitle
    include WindowInput
    include WindowHooks

    @@g_paste_buffer = ''

    def initialize
      CDK::ALL_OBJECTS << self

      init_title
      init_borders
      init_focus
      init_bindings
      init_exit_conditions
      init_screen
    end

    ###

    def timeout(v)
      @input_window.timeout(v) if @input_window
    end

    ###

    def object_type
      # no type by default
      :NULL
    end

    def validObjType(type)
      # dummy version for now
      true
    end

    def validCDKObject
      result = false
      if CDK::ALL_OBJECTS.include?(self)
        result = self.validObjType(self.object_type)
      end
      return result
    end

    ###

    # This sets the background color of the widget.
    def setBackgroundColor(color)
      return if color.nil? || color == ''

      junk1 = []
      junk2 = []
      
      # Convert the value of the environment variable to a chtype
      holder = char2Chtype(color, junk1, junk2)

      # Set the widget's background color
      self.setBKattr(holder[0])
    end
  end
end
