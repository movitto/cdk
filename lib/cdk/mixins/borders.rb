module CDK
  module Borders
    attr_accessor :box
    attr_accessor :ULChar, :URChar, :LLChar, :LRChar, :HZChar, :VTChar, :BXAttr
    attr_reader :border_size

    def init_borders
      # set default line-drawing characters
      @ULChar = Ncurses::ACS_ULCORNER
      @URChar = Ncurses::ACS_URCORNER
      @LLChar = Ncurses::ACS_LLCORNER
      @LRChar = Ncurses::ACS_LRCORNER
      @HZChar = Ncurses::ACS_HLINE
      @VTChar = Ncurses::ACS_VLINE
      @BXAttr = Ncurses::A_NORMAL
    end

    def setBox(box)
      @box = box
      @border_size = if @box then 1 else 0 end
    end

    def getBox
      return @box
    end

    # Set the object's upper-left-corner line-drawing character.
    def setULchar(ch)
      @ULChar = ch
    end

    # Set the object's upper-right-corner line-drawing character.
    def setURchar(ch)
      @URChar = ch
    end

    # Set the object's lower-left-corner line-drawing character.
    def setLLchar(ch)
      @LLChar = ch
    end

    # Set the object's upper-right-corner line-drawing character.
    def setLRchar(ch)
      @LRChar = ch
    end

    # Set the object's horizontal line-drawing character
    def setHZchar(ch)
      @HZChar = ch
    end

    # Set the object's vertical line-drawing character
    def setVTchar(ch)
      @VTChar = ch
    end

    # Set the object's box-attributes.
    def setBXattr(ch)
      @BXAttr = ch
    end
  end # module Borders
end # module CDK
