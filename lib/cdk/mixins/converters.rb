module CDK
  module Converters
    def encode_attribute (string, from, mask)
      mask << 0
      case string[from + 1]
      when 'B'
        mask[0] = Ncurses::A_BOLD
      when 'D'
        mask[0] = Ncurses::A_DIM
      when 'K'
        mask[0] = Ncurses::A_BLINK
      when 'R'
        mask[0] = Ncurses::A_REVERSE
      when 'S'
        mask[0] = Ncurses::A_STANDOUT
      when 'U'
        mask[0] = Ncurses::A_UNDERLINE
      end

      if mask[0] != 0
        from += 1
      elsif CDK.digit?(string[from+1]) and CDK.digit?(string[from + 2])
        if Ncurses.has_colors?
          # XXX: Only checks if terminal has colours not if colours are started
          pair = string[from + 1..from + 2].to_i
          mask[0] = Ncurses.COLOR_PAIR(pair)
        else
          mask[0] = Ncurses.A_BOLD
        end

        from += 2
      elsif CDK.digit?(string[from + 1])
        if Ncurses.has_colors?
          # XXX: Only checks if terminal has colours not if colours are started
          pair = string[from + 1].to_i
          mask[0] = Ncurses.COLOR_PAIR(pair)
        else
          mask[0] = Ncurses.A_BOLD
        end

        from += 1
      end

      return from
    end

    # The reverse of encode_attribute
    # Well, almost.  If attributes such as bold and underline are combined in the
    # same string, we do not necessarily reconstruct them in the same order.
    # Also, alignment markers and tabs are lost.

    def decode_attribute (string, from, oldattr, newattr)
      table = {
        'B' => Ncurses::A_BOLD,
        'D' => Ncurses::A_DIM,
        'K' => Ncurses::A_BLINK,
        'R' => Ncurses::A_REVERSE,
        'S' => Ncurses::A_STANDOUT,
        'U' => Ncurses::A_UNDERLINE
      }

      result = if string.nil? then '' else string end
      base_len = result.size
      tmpattr = oldattr & Ncurses::A_ATTRIBUTES

      newattr &= Ncurses::A_ATTRIBUTES
      if tmpattr != newattr
        while tmpattr != newattr
          found = false
          table.keys.each do |key|
            if (table[key] & tmpattr) != (table[key] & newattr)
              found = true
              result << CDK::L_MARKER
              if (table[key] & tmpattr).nonzero?
                result << '!'
                tmpattr &= ~(table[key])
              else
                result << '/'
                tmpattr |= table[key]
              end
              result << key
              break
            end
          end
          # XXX: Only checks if terminal has colours not if colours are started
          if Ncurses.has_colors?
            if (tmpattr & Ncurses::A_COLOR) != (newattr & Ncurses::A_COLOR)
              oldpair = Ncurses.PAIR_NUMBER(tmpattr)
              newpair = Ncurses.PAIR_NUMBER(newattr)
              if !found
                found = true
                result << CDK::L_MARKER
              end
              if newpair.zero?
                result << '!'
                result << oldpair.to_s
              else
                result << '/'
                result << newpair.to_s
              end
              tmpattr &= ~(Ncurses::A_COLOR)
              newattr &= ~(Ncurses::A_COLOR)
            end
          end

          if found
            result << CDK::R_MARKER
          else
            break
          end
        end
      end

      return from + result.size - base_len
    end

    # This function takes a string, full of format markers and translates
    # them into a chtype array.  This is better suited to curses because
    # curses uses chtype almost exclusively
    def char2Chtype (string, to, align)
      to << 0
      align << LEFT
      result = []

      if string.size > 0
        used = 0

        # The original code makes two passes since it has to pre-allocate space but
        # we should be able to make do with one since we can dynamically size it
        adjust = 0
        attrib = Ncurses::A_NORMAL
        last_char = 0
        start = 0
        used = 0
        x = 3

        # Look for an alignment marker.
        if string[0] == L_MARKER
          if string[1] == 'C' && string[2] == R_MARKER
            align[0] = CENTER
            start = 3
          elsif string[1] == 'R' && string[2] == R_MARKER
            align[0] = RIGHT
            start = 3
          elsif string[1] == 'L' && string[2] == R_MARKER
            start = 3
          elsif string[1] == 'B' && string[2] == '='
            # Set the item index value in the string.
            result = [' '.ord, ' '.ord, ' '.ord]

            # Pull out the bullet marker.
            while x < string.size and string[x] != R_MARKER
              result << (string[x].ord | Ncurses::A_BOLD)
              x += 1
            end
            adjust = 1

            # Set the alignment variables
            start = x
            used = x
          elsif string[1] == 'I' && string[2] == '='
            from = 3
            x = 0

            while from < string.size && string[from] != Ncurses.R_MARKER
              if CDK.digit?(string[from])
                adjust = adjust * 10 + string[from].to_i
                x += 1
              end
              from += 1
            end

            start = x + 4
          end
        end

        while adjust > 0
          adjust -= 1
          result << ' '
          used += 1
        end

        # Set the format marker boolean to false
        inside_marker = false

        # Start parsing the character string.
        from = start
        while from < string.size
          # Are we inside a format marker?
          if !inside_marker
            if string[from] == L_MARKER &&
                ['/', '!', '#'].include?(string[from + 1])
              inside_marker = true
            elsif string[from] == "\\" && string[from + 1] == L_MARKER
              from += 1
              result << (string[from].ord | attrib)
              used += 1
              from += 1
            elsif string[from] == "\t"
              begin
                result << ' '
                used += 1
              end while (used & 7).nonzero?
            else
              result << (string[from].ord | attrib)
              used += 1
            end
          else
            case string[from]
            when R_MARKER
              inside_marker = false
            when '#'
              last_char = 0
              case string[from + 2]
              when 'L'
                case string[from + 1]
                when 'L'
                  last_char = Ncurses::ACS_LLCORNER
                when 'U'
                  last_char = Ncurses::ACS_ULCORNER
                when 'H'
                  last_char = Ncurses::ACS_HLINE
                when 'V'
                  last_char = Ncurses::ACS_VLINE
                when 'P'
                  last_char = Ncurses::ACS_PLUS
                end
              when 'R'
                case string[from + 1]
                when 'L'
                  last_char = Ncurses::ACS_LRCORNER
                when 'U'
                  last_char = Ncurses::ACS_URCORNER
                end
              when 'T'
                case string[from + 1]
                when 'T'
                  last_char = Ncurses::ACS_TTEE
                when 'R'
                  last_char = Ncurses::ACS_RTEE
                when 'L'
                  last_char = Ncurses::ACS_LTEE
                when 'B'
                  last_char = Ncurses::ACS_BTEE
                end
              when 'A'
                case string[from + 1]
                when 'L'
                  last_char = Ncurses::ACS_LARROW
                when 'R'
                  last_char = Ncurses::ACS_RARROW
                when 'U'
                  last_char = Ncurses::ACS_UARROW
                when 'D'
                  last_char = Ncurses::ACS_DARROW
                end
              else
                case [string[from + 1], string[from + 2]]
                when ['D', 'I']
                  last_char = Ncurses::ACS_DIAMOND
                when ['C', 'B']
                  last_char = Ncurses::ACS_CKBOARD
                when ['D', 'G']
                  last_char = Ncurses::ACS_DEGREE
                when ['P', 'M']
                  last_char = Ncurses::ACS_PLMINUS
                when ['B', 'U']
                  last_char = Ncurses::ACS_BULLET
                when ['S', '1']
                  last_char = Ncurses::ACS_S1
                when ['S', '9']
                  last_char = Ncurses::ACS_S9
                end
              end

              if last_char.nonzero?
                adjust = 1
                from += 2

                if string[from + 1] == '('
                  # check for a possible numeric modifier
                  from += 2
                  adjust = 0

                  while from < string.size && string[from] != ')'
                    if CDK.digit?(string[from])
                      adjust = (adjust * 10) + string[from].to_i
                    end
                    from += 1
                  end
                end
              end
              (0...adjust).each do |x|
                result << (last_char | attrib)
                used += 1
              end
            when '/'
              mask = []
              from = encode_attribute(string, from, mask)
              attrib |= mask[0]
            when '!'
              mask = []
              from = encode_attribute(string, from, mask)
              attrib &= ~(mask[0])
            end
          end
          from += 1
        end

        if result.size == 0
          result << attrib
        end
        to[0] = used
      else
        result = []
      end
      return result
    end

    # ...
    #def self.char2Chtype (string, to, align)
    #end

    def charOf(chtype)
      (chtype.ord & 255).chr
    end

    # This returns a string from a chtype array
    # Formatting codes are omitted.
    def chtype2Char(string)
      newstring = ''

      unless string.nil?
        string.each do |char|
          newstring << charOf(char)
        end
      end

      return newstring
    end

    # This returns a string from a chtype array
    # Formatting codes are embedded
    def chtype2String(string)
      newstring = ''
      unless string.nil?
        need = 0
        (0...string.size).each do |x|
          need = decode_attribute(newstring, need,
                                     x > 0 ? string[x - 1] : 0, string[x])
          newstring << string[x]
        end
      end

      return newstring
    end
  end # module Converters
end # module CDK
