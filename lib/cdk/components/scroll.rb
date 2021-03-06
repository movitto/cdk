require_relative 'scroller'

module CDK
  class SCROLL < CDK::SCROLLER
    include CommonControls

    attr_reader :item, :list_size, :current_item, :highlight

    def initialize (cdkscreen, xplace, yplace, splace, height, width, title,
        list, list_size, numbers, highlight, box, shadow)
      super()
      parent_width = cdkscreen.window.getmaxx
      parent_height = cdkscreen.window.getmaxy
      box_width = width
      box_height = height
      xpos = xplace
      ypos = yplace
      scroll_adjust = 0
      bindings = {
        CDK::BACKCHAR => Ncurses::KEY_PPAGE,
        CDK::FORCHAR  => Ncurses::KEY_NPAGE,
        'g'           => Ncurses::KEY_HOME,
        '1'           => Ncurses::KEY_HOME,
        'G'           => Ncurses::KEY_END,
        '<'           => Ncurses::KEY_HOME,
        '>'           => Ncurses::KEY_END
      }

      self.setBox(box)

      # If the height is a negative value, the height will be ROWS-height,
      # otherwise the height will be the given height
      box_height = CDK.setWidgetDimension(parent_height, height, 0)

      # If the width is a negative value, the width will be COLS-width,
      # otherwise the width will be the given width
      box_width = CDK.setWidgetDimension(parent_width, width, 0)
    
      box_width = self.setTitle(title, box_width)

      # Set the box height.
      if @title_lines > box_height
        box_height = @title_lines + [list_size, 8].min + 2 * @border_size
      end

      # Adjust the box width if there is a scroll bar
      if splace == CDK::LEFT || splace == CDK::RIGHT
        @scrollbar = true
        box_width += 1
      else
        @scrollbar = false
      end

      # Make sure we didn't extend beyond the dimensions of the window.
      @box_width = if box_width > parent_width 
                   then parent_width - scroll_adjust 
                   else box_width 
                   end
      @box_height = if box_height > parent_height
                    then parent_height
                    else box_height
                    end

      self.setViewSize(list_size)

      # Rejustify the x and y positions if we need to.
      xtmp = [xpos]
      ytmp = [ypos] 
      alignxy(cdkscreen.window, xtmp, ytmp, @box_width, @box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Make the scrolling window
      @win = Ncurses::WINDOW.new(@box_height, @box_width, ypos, xpos)

      # Is the scrolling window null?
      if @win.nil?
        return nil
      end

      # Turn the keypad on for the window
      @win.keypad(true)

      # Create the scrollbar window.
      if splace == CDK::RIGHT
        @scrollbar_win = @win.subwin(self.maxViewSize, 1,
            self.SCREEN_YPOS(ypos), xpos + box_width - @border_size - 1)
      elsif splace == CDK::LEFT
        @scrollbar_win = @win.subwin(self.maxViewSize, 1,
            self.SCREEN_YPOS(ypos), self.SCREEN_XPOS(xpos))
      else
        @scrollbar_win = nil
      end

      # create the list window
      @list_win = @win.subwin(self.maxViewSize,
          box_width - (2 * @border_size) - scroll_adjust,
          self.SCREEN_YPOS(ypos),
          self.SCREEN_XPOS(xpos) + (if splace == CDK::LEFT then 1 else 0 end))

      # Set the rest of the variables
      @screen = cdkscreen
      @parent = cdkscreen.window
      @shadow_win = nil
      @scrollbar_placement = splace
      @max_left_char = 0
      @left_char = 0
      @highlight = highlight
      # initExitType (scrollp);
      @accepts_focus = true
      @input_window = @win
      @shadow = shadow

      self.setPosition(0);

      # Create the scrolling list item list and needed variables.
      if self.createItemList(numbers, list, list_size) <= 0
        return nil
      end

      # Do we need to create a shadow?
      if shadow
        @shadow_win = Ncurses::WINDOW.new(@box_height, box_width,
            ypos + 1, xpos + 1)
      end

      # Set up the key bindings.
      bindings.each do |from, to|
        #self.bind(:SCROLL, from, getc_lambda, to)
        self.bind(:SCROLL, from, :getc, to)
      end

      cdkscreen.register(:SCROLL, self);
      
      return self
    end

    def object_type
      :SCROLL
    end

    def position
      super(@win)
    end

    # Put the cursor on the currently-selected item's row.
    def fixCursorPosition
      scrollbar_adj = if @scrollbar_placement == LEFT then 1 else 0 end
      ypos = self.SCREEN_YPOS(@current_item - @current_top)
      xpos = self.SCREEN_XPOS(0) + scrollbar_adj

      @input_window.wmove(ypos, xpos)
      wrefresh(@input_window)
    end

    # This actually does all the 'real' work of managing the scrolling list.
    def activate(actions)
      # Draw the scrolling list
      self.draw(@box)

      if actions.nil? || actions.size == 0
        while true
          self.fixCursorPosition
          input = self.getch([])

          # Inject the character into the widget.
          ret = self.inject(input)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      else
        # Inject each character one at a time.
        actions.each do |action|
          ret = self.inject(action)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      end

      # Set the exit type for the widget and return
      self.setExitType(0)
      return -1
    end

    # This injects a single character into the widget.
    def inject(input)
      pp_return = 1
      ret = -1
      @complete = false

      # Set the exit type for the widget.
      self.setExitType(0)

      # Draw the scrolling list
      self.drawList(@box)

      #Check if there is a pre-process function to be called.
      unless @pre_process_func.nil?
        pp_return = @pre_process_func.call(:SCROLL, self,
            @pre_process_data, input)
      end

      # Should we continue?
      if pp_return != 0
        # Check for a predefined key binding.
        if self.checkBind(:SCROLL, input) != false
          #self.checkEarlyExit
          @complete = true
        else
          case input
          when Ncurses::KEY_UP
            self.KEY_UP
          when Ncurses::KEY_DOWN
            self.KEY_DOWN
          when Ncurses::KEY_RIGHT
            self.KEY_RIGHT
          when Ncurses::KEY_LEFT
            self.KEY_LEFT
          when Ncurses::KEY_PPAGE
            self.KEY_PPAGE
          when Ncurses::KEY_NPAGE
            self.KEY_NPAGE
          when Ncurses::KEY_HOME
            self.KEY_HOME
          when Ncurses::KEY_END
            self.KEY_END
          when '$'
            @left_char = @max_left_char
          when '|'
            @left_char = 0
          when CDK::KEY_ESC
            self.setExitType(input)
            @complete = true
          when Ncurses::ERR
            self.setExitType(input)
            @complete = true
          when CDK::REFRESH
            @screen.erase
            @screen.refresh
          when CDK::KEY_TAB, Ncurses::KEY_ENTER, CDK::KEY_RETURN
            if quit_on_enter?
              self.setExitType(input)
              ret = @current_item
              @complete = true
            end
          end
        end

        if !@complete && !(@post_process_func.nil?)
          @post_process_func.call(:SCROLL, self, @post_process_data, input)
        end
      end

      if !@complete
        self.drawList(@box)
        self.setExitType(0)
      end

      self.fixCursorPosition
      @result_data = ret

      #return ret != -1
      return ret
    end

    def getCurrentTop
      return @current_top
    end

    def setCurrentTop(item)
      if item < 0
        item = 0
      elsif item > @max_top_item
        item = @max_top_item
      end
      @current_top = item

      self.setPosition(item);
    end

    # This moves the scroll field to the given location.
    def move(xplace, yplace, relative, refresh_flag)
      windows = [@win, @list_win, @shadow_win, @scrollbar_win]
      self.move_specific(xplace, yplace, relative, refresh_flag,
          windows, [])
    end

    # This function draws the scrolling list widget.
    def draw(box)
      # Draw in the shadow if we need to.
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      self.drawTitle(@win)

      # Draw in the scrolling list items.
      self.drawList(box)
    end

    def drawCurrent
      # Rehighlight the current menu item.
      screen_pos = @item_pos[@current_item] - @left_char
      highlight = if self.has_focus
                  then @highlight
                  else Ncurses::A_NORMAL
                  end

      Draw.writeChtypeAttrib(@list_win,
          if screen_pos >= 0 then screen_pos else 0 end,
          @current_high, @item[@current_item], highlight, CDK::HORIZONTAL,
          if screen_pos >= 0 then 0 else 1 - screen_pos end,
          @item_len[@current_item])
    end

    def drawList(box)
      # If the list is empty, don't draw anything.
      if @list_size > 0
        # Redraw the list
        (0...@view_size).each do |j|
          k = j + @current_top

          Draw.writeBlanks(@list_win, 0, j, CDK::HORIZONTAL, 0,
            @box_width - (2 * @border_size))

          # Draw the elements in the scrolling list.
          if k < @list_size
            screen_pos = @item_pos[k] - @left_char
            ypos = j

            # Write in the correct line.
            Draw.writeChtype(@list_win,
                if screen_pos >= 0 then screen_pos else 1 end,
                ypos, @item[k], CDK::HORIZONTAL,
                if screen_pos >= 0 then 0 else 1 - screen_pos end,
                @item_len[k])
          end
        end

        self.drawCurrent

        # Determine where the toggle is supposed to be.
        unless @scrollbar_win.nil?
          @toggle_pos = (@current_item * @step).floor

          # Make sure the toggle button doesn't go out of bounds.
          
          if @toggle_pos >= @scrollbar_win.getmaxy
            @toggle_pos = @scrollbar_win.getmaxy - 1
          end

          # Draw the scrollbar
          @scrollbar_win.mvwvline(0, 0, Ncurses::ACS_CKBOARD,
              @scrollbar_win.getmaxy)
          @scrollbar_win.mvwvline(@toggle_pos, 0, ' '.ord | Ncurses::A_REVERSE,
              @toggle_size)
        end
      end

      # Box it if needed.
      if box
        Draw.drawObjBox(@win, self)
      end

      # Refresh the window
      wrefresh
    end

    # This sets the background attribute of the widget.
    def setBKattr(attrib)
      @win.wbkgd(attrib)
      @list_win.wbkgd(attrib)
      unless @scrollbar_win.nil?
        @scrollbar_win.wbkgd(attrib)
      end
    end

    # This function destroys
    def destroy
      self.cleanTitle

      # Clean up the windows.
      CDK.deleteCursesWindow(@scrollbar_win)
      CDK.deleteCursesWindow(@shadow_win)
      CDK.deleteCursesWindow(@list_win)
      CDK.deleteCursesWindow(@win)

      # Clean the key bindings.
      self.cleanBindings(:SCROLL)

      # Unregister this object
      CDK::SCREEN.unregister(:SCROLL, self)
    end

    # This function erases the scrolling list from the screen.
    def erase
      CDK.eraseCursesWindow(@win)
      CDK.eraseCursesWindow(@shadow_win)
    end

    def allocListArrays(old_size, new_size)
      result = true
      new_list = Array.new(new_size)
      new_len = Array.new(new_size)
      new_pos = Array.new(new_size)

      (0...old_size).each do |n|
        new_list[n] = @item[n]
        new_len[n] = @item_len[n]
        new_pos[n] = @item_pos[n]
      end

      @item = new_list
      @item_len = new_len
      @item_pos = new_pos

      return result
    end

    def allocListItem(which, work, used, number, value)
      if number > 0
        value = "%4d. %s" % [number, value]
      end

      item_len = []
      item_pos = []
      @item[which] = char2Chtype(value, item_len, item_pos)
      @item_len[which] = item_len[0]
      @item_pos[which] = item_pos[0]

      @item_pos[which] = justify_string(@box_width,
          @item_len[which], @item_pos[which])
      return true
    end

    # This function creates the scrolling list information and sets up the
    # needed variables for the scrolling list to work correctly.
    def createItemList(numbers, list, list_size)
      status = 0
      if list_size > 0
        widest_item = 0
        x = 0
        have = 0
        temp = ''
        if allocListArrays(0, list_size)
          # Create the items in the scrolling list.
          status = 1
          (0...list_size).each do |x|
            number = if numbers then x + 1 else 0 end
            if !self.allocListItem(x, temp, have, number, list[x])
              status = 0
              break
            end

            widest_item = [@item_len[x], widest_item].max
          end

          if status
            self.updateViewWidth(widest_item);

            # Keep the boolean flag 'numbers'
            @numbers = numbers
          end
        end
      else
        status = 1  # null list is ok - for a while
      end

      return status
    end

    # This sets certain attributes of the scrolling list.
    def set(list, list_size, numbers, highlight, box)
      self.setItems(list, list_size, numbers)
      self.setHighlight(highlight)
      self.setBox(box)
    end

    # This sets the scrolling list items
    def setItems(list, list_size, numbers)
      if self.createItemList(numbers, list, list_size) <= 0
        return
      end

      # Clean up the display.
      (0...@view_size).each do |x|
        Draw.writeBlanks(@win, 1, x, CDK::HORIZONTAL, 0, @box_width - 2);
      end

      self.setViewSize(list_size)
      self.setPosition(0)
      @left_char = 0
    end

    def getItems(list)
      (0...@list_size).each do |x|
        list << chtype2Char(@item[x])
      end

      return @list_size
    end

    # This sets the highlight of the scrolling list.
    def setHighlight(highlight)
      @highlight = highlight
    end

    def getHighlight(highlight)
      return @highlight
    end

    # Resequence the numbers after an insertion/deletion.
    def resequence
      if @numbers
        (0...@list_size).each do |j|
          target = @item[j]

          source = "%4d. %s" % [j + 1, ""]

          k = 0
          while k < source.size
            # handle deletions that change the length of number
            if source[k] == "." && target[k] != "."
              source = source[0...k] + source[k+1..-1]
            end

            target[k] &= Ncurses::A_ATTRIBUTES
            target[k] |= source[k].ord
            k += 1
          end
        end
      end
    end

    def insertListItem(item)
      @item = @item[0..item] + @item[item..-1]
      @item_len = @item_len[0..item] + @item_len[item..-1]
      @item_pos = @item_pos[0..item] + @item_pos[item..-1]
      return true
    end

    # This adds a single item to a scrolling list, at the end of the list.
    def addItem(item)
      item_number = @list_size
      widest_item = self.WidestItem
      temp = ''
      have = 0

      if self.allocListArrays(@list_size, @list_size + 1) &&
          self.allocListItem(item_number, temp, have,
          if @numbers then item_number + 1 else 0 end,
          item)
        # Determine the size of the widest item.
        widest_item = [@item_len[item_number], widest_item].max

        self.updateViewWidth(widest_item)
        self.setViewSize(@list_size + 1)
      end
    end

    # This adds a single item to a scrolling list before the current item
    def insertItem(item)
      widest_item = self.WidestItem
      temp = ''
      have = 0

      if self.allocListArrays(@list_size, @list_size + 1) &&
          self.insertListItem(@current_item) &&
          self.allocListItem(@current_item, temp, have,
          if @numbers then @current_item + 1 else 0 end,
          item)
        # Determine the size of the widest item.
        widest_item = [@item_len[@current_item], widest_item].max

        self.updateViewWidth(widest_item)
        self.setViewSize(@list_size + 1)
        self.resequence
      end
    end

    # This removes a single item from a scrolling list.
    def deleteItem(position)
      if position >= 0 && position < @list_size
        # Adjust the list
        @item = @item[0...position] + @item[position+1..-1]
        @item_len = @item_len[0...position] + @item_len[position+1..-1]
        @item_pos = @item_pos[0...position] + @item_pos[position+1..-1]

        self.setViewSize(@list_size - 1)

        if @list_size > 0
          self.resequence
        end

        if @list_size < self.maxViewSize
          @win.werase  # force the next redraw to be complete
        end

        # do this to update the view size, etc
        self.setPosition(@current_item)
      end
    end
    
    def focus
      self.drawCurrent
      wrefresh(@list_win)
    end

    def unfocus
      self.drawCurrent
      wrefresh(@list_win)
    end

    def AvailableWidth
      @box_width - (2 * @border_size)
    end

    def updateViewWidth(widest)
      @max_left_char = if @box_width > widest
                       then 0
                       else widest - self.AvailableWidth
                       end
    end

    def WidestItem
      @max_left_char + self.AvailableWidth
    end
  end # class SCROLL
end # module CDK
