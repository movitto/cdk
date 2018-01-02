module CDK
  module Display
    # Tell if a display type is "hidden"
    def Display.isHiddenDisplayType(type)
      case type
      when :HCHAR,
           :HINT,
           :HMIXED,
           :LHCHAR,
           :LHMIXED,
           :UHCHAR,
           :UHMIXED
        true

      when :CHAR,
           :INT,
           :INVALID,
           :LCHAR,
           :LMIXED,
           :MIXED,
           :UCHAR,
           :UMIXED,
           :VIEWONLY
        false
      end
    end

    # Given a character input, check if it is allowed by the display type
    # and return the character to apply to the display, or ERR if not
    def Display.filterByDisplayType(type, input)
      result = input
      if !CDK.isChar(input)
        result = Ncurses::ERR

      elsif [:INT, :HINT].include?(type) &&
            !CDK.digit?(result.chr)
        result = Ncurses::ERR

      elsif [:CHAR, :UCHAR, :LCHAR, :UHCHAR, :LHCHAR].include?(type) &&
            CDK.digit?(result.chr)
        result = Ncurses::ERR

      elsif type == :VIEWONLY
        result = ERR

      elsif [:UCHAR, :UHCHAR, :UMIXED, :UHMIXED].include?(type) &&
            CDK.alpha?(result.chr)
        result = result.chr.upcase.ord

      elsif [:LCHAR, :LHCHAR, :LMIXED, :LHMIXED].include?(type) &&
            CDK.alpha?(result.chr)
        result = result.chr.downcase.ord
      end

      return result
    end
  end
end
