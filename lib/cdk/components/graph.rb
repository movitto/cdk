require_relative '../cdk_objs'

module CDK
  class GRAPH < CDK::CDKOBJS
    def initialize(cdkscreen, xplace, yplace, height, width,
        title, xtitle, ytitle)
      super()
      parent_width = cdkscreen.window.getmaxx
      parent_height = cdkscreen.window.getmaxy

      self.setBox(false)

      box_height = CDK.setWidgetDimension(parent_height, height, 3)
      box_width = CDK.setWidgetDimension(parent_width, width, 0)
      box_width = self.setTitle(title, box_width)
      box_height += @title_lines
      box_width = [parent_width, box_width].min
      box_height = [parent_height, box_height].min

      # Rejustify the x and y positions if we need to
      xtmp = [xplace]
      ytmp = [yplace]
      CDK.alignxy(cdkscreen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Create the widget pointer
      @screen = cdkscreen
      @parent = cdkscreen.window
      @win = Ncurses::WINDOW.new(box_height, box_width, ypos, xpos)
      @box_height = box_height
      @box_width = box_width
      @minx = 0
      @maxx = 0
      @xscale = 0
      @yscale = 0
      @count = 0
      @display_type = :LINE

      if @win.nil?
        self.destroy
        return nil
      end
      @win.keypad(true)

      # Translate the X axis title string to a chtype array
      if !(xtitle.nil?) && xtitle.size > 0
        xtitle_len = []
        xtitle_pos = []
        @xtitle = CDK.char2Chtype(xtitle, xtitle_len, xtitle_pos)
        @xtitle_len = xtitle_len[0]
        @xtitle_pos = CDK.justifyString(@box_height,
            @xtitle_len, xtitle_pos[0])
      else
        xtitle_len = []
        xtitle_pos = []
        @xtitle = CDK.char2Chtype("<C></5>X Axis", xtitle_len, xtitle_pos)
        @xtitle_len = title_len[0]
        @xtitle_pos = CDK.justifyString(@box_height,
            @xtitle_len, xtitle_pos[0])
      end

      # Translate the Y Axis title string to a chtype array
      if !(ytitle.nil?) && ytitle.size > 0
        ytitle_len = []
        ytitle_pos = []
        @ytitle = CDK.char2Chtype(ytitle, ytitle_len, ytitle_pos)
        @ytitle_len = ytitle_len[0]
        @ytitle_pos = CDK.justifyString(@box_width, @ytitle_len, ytitle_pos[0])
      else
        ytitle_len = []
        ytitle_pos = []
        @ytitle = CDK.char2Chtype("<C></5>Y Axis", ytitle_len, ytitle_pos)
        @ytitle_len = ytitle_len[0]
        @ytitle_pos = CDK.justifyString(@box_width, @ytitle_len, ytitle_pos[0])
      end

      @graph_char = 0
      @values = []

      cdkscreen.register(:GRAPH, self)
    end

    # This was added for the builder.
    def activate(actions)
      self.draw(@box)
    end

    # Set multiple attributes of the widget
    def set(values, count, graph_char, start_at_zero, display_type)
      ret = self.setValues(values, count, start_at_zero)
      self.setCharacters(graph_char)
      self.setDisplayType(display_type)
      return ret
    end

    # Set the scale factors for the graph after wee have loaded new values.
    def setScales
      @xscale = (@maxx - @minx) / [1, @box_height - @title_lines - 5].max
      if @xscale <= 0
        @xscale = 1
      end

      @yscale = (@box_width - 4) / [1, @count].max
      if @yscale <= 0
        @yscale = 1
      end
    end

    # Set the values of the graph.
    def setValues(values, count, start_at_zero)
      min = 2**30
      max = -2**30

      # Make sure everything is happy.
      if count < 0
        return false
      end

      if !(@values.nil?) && @values.size > 0
        @values = []
        @count = 0
      end

      # Copy the X values
      values.each do |value|
        min = [value, @minx].min
        max = [value, @maxx].max

        # Copy the value.
        @values << value
      end

      # Keep the count and min/max values
      @count = count
      @minx = min
      @maxx = max

      # Check the start at zero status.
      if start_at_zero
        @minx = 0
      end

      self.setScales

      return true
    end

    def getValues(size)
      size << @count
      return @values
    end

    # Set the value of the graph at the given index.
    def setValue(index, value, start_at_zero)
      # Make sure the index is within range.
      if index < 0 || index >= @count
        return false
      end

      # Set the min, max, and value for the graph
      @minx = [value, @minx].min
      @maxx = [value, @maxx].max
      @values[index] = value

      # Check the start at zero status
      if start_at_zero
        @minx = 0
      end

      self.setScales

      return true
    end

    def getValue(index)
      if index >= 0 && index < @count then @values[index] else 0 end
    end

    # Set the characters of the graph widget.
    def setCharacters(characters)
      char_count = []
      new_tokens = CDK.char2Chtype(characters, char_count, [])

      if char_count[0] != @count
        return false
      end

      @graph_char = new_tokens
      return true
    end

    def getCharacters
      return @graph_char
    end

    # Set the character of the graph widget of the given index.
    def setCharacter(index, character)
      # Make sure the index is within range
      if index < 0 || index > @count
        return false
      end

      # Convert the string given to us
      char_count = []
      new_tokens = CDK.char2Chtype(character, char_count, [])

      # Check if the number of characters back is the same as the number
      # of elements in the list.
      if char_count[0] != @count
        return false
      end

      # Everything OK so far. Set the value of the array.
      @graph_char[index] = new_tokens[0]
      return true
    end

    def getCharacter(index)
      return graph_char[index]
    end

    # Set the display type of the graph.
    def setDisplayType(type)
      @display_type = type
    end

    def getDisplayType
      @display_type
    end

    # Set the background attribute of the widget.
    def setBKattr(attrib)
      @win.wbkgd(attrib)
    end

    # Move the graph field to the given location.
    def move(xplace, yplace, relative, refresh_flag)
      current_x = @win.getbegx
      current_y = @win.getbegy
      xpos = xplace
      ypos = yplace

      # If this is a relative move, then we will adjust where we want
      # to move to
      if relative
        xpos = @win.getbegx + xplace
        ypos = @win.getbegy + yplace
      end

      # Adjust the window if we need to.
      xtmp = [xpos]
      tymp = [ypos]
      CDK.alignxy(@screen.window, xtmp, ytmp, @box_width, @box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Get the difference
      xdiff = current_x - xpos
      ydiff = current_y - ypos

      # Move the window to the new location.
      CDK.moveCursesWindow(@win, -xdiff, -ydiff)
      CDK.moveCursesWindow(@shadow_win, -xdiff, -ydiff)

      # Touch the windows so they 'move'.
      CDK::SCREEN.refreshCDKWindow(@screen.window)

      # Reraw the windowk if they asked for it
      if refresh_flag
        self.draw(@box)
      end
    end

    # Draw the grpah widget
    def draw(box)
      adj = 2 + (if @xtitle.nil? || @xtitle.size == 0 then 0 else 1 end)
      spacing = 0
      attrib = ' '.ord | Ncurses::A_REVERSE

      if box
        Draw.drawObjBox(@win, self)
      end

      # Draw in the vertical axis
      Draw.drawLine(@win, 2, @title_lines + 1, 2, @box_height - 3,
          Ncurses::ACS_VLINE)

      # Draw in the horizontal axis
      Draw.drawLine(@win, 3, @box_height - 3, @box_width, @box_height - 3,
          Ncurses::ACS_HLINE)

      self.drawTitle(@win)

      # Draw in the X axis title.
      if !(@xtitle.nil?) && @xtitle.size > 0
        Draw.writeChtype(@win, 0, @xtitle_pos, @xtitle, CDK::VERTICAL,
            0, @xtitle_len)
        attrib = @xtitle[0] & Ncurses::A_ATTRIBUTES
      end

      # Draw in the X axis high value
      temp = "%d" % [@maxx]
      Draw.writeCharAttrib(@win, 1, @title_lines + 1, temp, attrib,
          CDK::VERTICAL, 0, temp.size)

      # Draw in the X axis low value.
      temp = "%d" % [@minx]
      Draw.writeCharAttrib(@win, 1, @box_height - 2 - temp.size, temp, attrib,
          CDK::VERTICAL, 0, temp.size)

      # Draw in the Y axis title
      if !(@ytitle.nil?) && @ytitle.size > 0
        Draw.writeChtype(@win, @ytitle_pos, @box_height - 1, @ytitle,
            CDK::HORIZONTAL, 0, @ytitle_len)
      end

      # Draw in the Y axis high value.
      temp = "%d" % [@count]
      Draw.writeCharAttrib(@win, @box_width - temp.size - adj,
          @box_height - 2, temp, attrib, CDK::HORIZONTAL, 0, temp.size)

      # Draw in the Y axis low value.
      Draw.writeCharAttrib(@win, 3, @box_height - 2, "0", attrib,
          CDK::HORIZONTAL, 0, "0".size)

      # If the count is zero then there aren't any points.
      if @count == 0
        @win.wrefresh
        return
      end

      spacing = (@box_width - 3) / @count  # FIXME magic number (TITLE_LM)

      # Draw in the graph line/plot points.
      (0...@count).each do |y|
        colheight = (@values[y] / @xscale) - 1
        # Add the marker on the Y axis.
        @win.mvwaddch(@box_height - 3, (y + 1) * spacing + adj,
            Ncurses::ACS_TTEE)

        # If this is a plot graph, all we do is draw a dot.
        if @display_type == :PLOT
          xpos = @box_height - 4 - colheight
          ypos = (y + 1) * spacing + adj
          @win.mvwaddch(xpos, ypos, @graph_char[y])
        else
          (0..@yscale).each do |x|
            xpos = @box_height - 3
            ypos = (y + 1) * spacing - adj
            Draw.drawLine(@win, ypos, xpos - colheight, ypos, xpos,
                @graph_char[y])
          end
        end
      end

      # Draw in the axis corners.
      @win.mvwaddch(@title_lines, 2, Ncurses::ACS_URCORNER)
      @win.mvwaddch(@box_height - 3, 2, Ncurses::ACS_LLCORNER)
      @win.mvwaddch(@box_height - 3, @box_width, Ncurses::ACS_URCORNER)

      # Refresh and lets see it
      @win.wrefresh
    end

    def destroy
      self.cleanTitle
      self.cleanBindings(:GRAPH)
      CDK::SCREEN.unregister(:GRAPH, self)
      CDK.deleteCursesWindow(@win)
    end

    def erase
      if self.validCDKObject
        CDK.eraseCursesWindow(@win)
      end
    end

    def object_type
      :GRAPH
    end

    def position
      super(@win)
    end
  end # class Graph
end # module CDK
