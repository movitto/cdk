require_relative '../cdk_objs'

module CDK
  class BUTTON < CDK::CDKOBJS
    def initialize(cdkscreen, xplace, yplace, text, callback, box, shadow)
      super()
      parent_width = cdkscreen.window.getmaxx
      parent_height = cdkscreen.window.getmaxy
      box_width = 0
      xpos = xplace
      ypos = yplace

      self.setBox(box)
      box_height = 1 + 2 * @border_size

      # Translate the string to a chtype array.
      info_len = []
      info_pos = []
      @info = CDK.char2Chtype(text, info_len, info_pos)
      @info_len = info_len[0]
      @info_pos = info_pos[0]
      box_width = [box_width, @info_len].max + 2 * @border_size

      # Create the string alignments.
      @info_pos = CDK.justifyString(box_width - 2 * @border_size,
          @info_len, @info_pos)

      # Make sure we didn't extend beyond the dimensions of the window.
      box_width = if box_width > parent_width
                  then parent_width
                  else box_width
                  end
      box_height = if box_height > parent_height
                   then parent_height
                   else box_height
                   end

      # Rejustify the x and y positions if we need to.
      xtmp = [xpos]
      ytmp = [ypos]
      CDK.alignxy(cdkscreen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Create the button.
      @screen = cdkscreen
      # ObjOf (button)->fn = &my_funcs;
      @parent = cdkscreen.window
      @win = Ncurses::WINDOW.new(box_height, box_width, ypos, xpos)
      @shadow_win = nil
      @xpos = xpos
      @ypos = ypos
      @box_width = box_width
      @box_height = box_height
      @callback = callback
      @input_window = @win
      @accepts_focus = true
      @shadow = shadow

      if @win.nil?
        self.destroy
        return nil
      end

      @win.keypad(true)

      # If a shadow was requested, then create the shadow window.
      if shadow
        @shadow_win = Ncurses::WINDOW.new(box_height, box_width,
            ypos + 1, xpos + 1)
      end

      # Register this baby.
      cdkscreen.register(:BUTTON, self)
    end

    # This was added for the builder.
    def activate(actions)
      self.draw(@box)
      ret = -1

      if actions.nil? || actions.size == 0
        while true
          input = self.getch([])

          # Inject the character into the widget.
          ret = self.inject(input)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      else
        # Inject each character one at a time.
        actions.each do |x|
          ret = self.inject(action)
          if @exit_type == :EARLY_EXIT
            return ret
          end
        end
      end

      # Set the exit type and exit
      self.setExitType(0)
      return -1
    end

    # This sets multiple attributes of the widget.
    def set(mesg, box)
      self.setMessage(mesg)
      self.setBox(box)
    end

    # This sets the information within the button.
    def setMessage(info)
      info_len = []
      info_pos = []
      @info = CDK.char2Chtype(info, info_len, info_pos)
      @info_len = info_len[0]
      @info_pos = CDK.justifyString(@box_width - 2 * @border_size,
          info_pos[0])

      # Redraw the button widget.
      self.erase
      self.draw(box)
    end

    def getMessage
      return @info
    end

    # This sets the background attribute of the widget.
    def setBKattr(attrib)
      @win.wbkgd(attrib)
    end

    def drawText
      box_width = @box_width

      # Draw in the message.
      (0...(box_width - 2 * @border_size)).each do |i|
        pos = @info_pos
        len = @info_len
        if i >= pos && (i - pos) < len
          c = @info[i - pos]
        else
          c = ' '
        end

        if @has_focus
          c = Ncurses::A_REVERSE | c
        end

        @win.mvwaddch(@border_size, i + @border_size, c)
      end
    end

    # This draws the button widget
    def draw(box)
      # Is there a shadow?
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      # Box the widget if asked.
      if @box
        Draw.drawObjBox(@win, self)
      end
      self.drawText
      @win.wrefresh
    end

    # This erases the button widget.
    def erase
      if self.validCDKObject
        CDK.eraseCursesWindow(@win)
        CDK.eraseCursesWindow(@shadow_win)
      end
    end

    # This moves the button field to the given location.
    def move(xplace, yplace, relative, refresh_flag)
      current_x = @win.getbegx
      current_y = @win.getbegy
      xpos = xplace
      ypos = yplace

      # If this is a relative move, then we will adjust where we want
      # to move to.
      if relative
        xpos = @win.getbegx + xplace
        ypos = @win.getbegy + yplace
      end

      # Adjust the window if we need to.
      xtmp = [xpos]
      ytmp = [ypos]
      CDK.alignxy(@screen.window, xtmp, ytmp, @box_width, @box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Get the difference
      xdiff = current_x - xpos
      ydiff = current_y - ypos

      # Move the window to the new location.
      CDK.moveCursesWindow(@win, -xdiff, -ydiff)
      CDK.moveCursesWindow(@shadow_win, -xdiff, -ydiff)

      # Thouch the windows so they 'move'.
      CDK::SCREEN.refreshCDKWindow(@screen.window)

      # Redraw the window, if they asked for it.
      if refresh_flag
        self.draw(@box)
      end
    end

    # This allows the user to use the cursor keys to adjust the
    # position of the widget.
    def position
      # Declare some variables
      orig_x = @win.getbegx
      orig_y = @win.getbegy
      key = 0

      # Let them move the widget around until they hit return
      while key != Ncurses::KEY_ENTER && key != CDK::KEY_RETURN
        key = self.getch([])
        if key == Ncurses::KEY_UP || key == '8'.ord
          if @win.getbegy > 0
            self.move(0, -1, true, true)
          else
            CDK.Beep
          end
        elsif key == Ncurses::KEY_DOWN || key == '2'.ord
          if @win.getbegy + @win.getmaxy < @screen.window.getmaxy - 1
            self.move(0, 1, true, true)
          else
            CDK.Beep
          end
        elsif key == Ncurses::KEY_LEFT || key == '4'.ord
          if @win.getbegx > 0
            self.move(-1, 0, true, true)
          else
            CDK.Beep
          end
        elsif key == Ncurses::KEY_RIGHT || key == '6'.ord
          if @win.getbegx + @win.getmaxx < @screen.window.getmaxx - 1
            self.move(1, 0, true, true)
          else
            CDK.Beep
          end
        elsif key == '7'.ord
          if @win.getbegy > 0 && @win.getbegx > 0
            self.move(-1, -1, true, true)
          else
            CDK.Beep
          end
        elsif key == '9'.ord
          if @win.getbegx + @win.getmaxx < @screen.window.getmaxx - 1 &&
              @win.getbegy > 0
            self.move(1, -1, true, true)
          else
            CDK.Beep
          end
        elsif key == '1'.ord
          if @win.getbegx > 0 &&
              @win.getbegx + @win.getmaxx < @screen.window.getmaxx - 1
            self.move(-1, 1, true, true)
          else
            CDK.Beep
          end
        elsif key == '3'.ord
          if @win.getbegx + @win.getmaxx < @screen.window.getmaxx - 1 &&
              @win.getbegy + @win.getmaxy < @screen.window.getmaxy - 1
            self.move(1, 1, true, true)
          else
            CDK.Beep
          end
        elsif key == '5'.ord
          self.move(CDK::CENTER, CDK::CENTER, false, true)
        elsif key == 't'.ord
          self.move(@win.getbegx, CDK::TOP, false, true)
        elsif key == 'b'.ord
          self.move(@win.getbegx, CDK::BOTTOM, false, true)
        elsif key == 'l'.ord
          self.move(CDK::LEFT, @win.getbegy, false, true)
        elsif key == 'r'
          self.move(CDK::RIGHT, @win.getbegy, false, true)
        elsif key == 'c'
          self.move(CDK::CENTER, @win.getbegy, false, true)
        elsif key == 'C'
          self.move(@win.getbegx, CDK::CENTER, false, true)
        elsif key == CDK::REFRESH
          @screen.erase
          @screen.refresh
        elsif key == CDK::KEY_ESC
          self.move(orig_x, orig_y, false, true)
        elsif key != CDK::KEY_RETURN && key != Ncurses::KEY_ENTER
          CDK.Beep
        end
      end
    end

    # This destroys the button object pointer.
    def destroy
      CDK.deleteCursesWindow(@shadow_win)
      CDK.deleteCursesWindow(@win)

      self.cleanBindings(:BUTTON)

      CDK::SCREEN.unregister(:BUTTON, self)
    end

    # This injects a single character into the widget.
    def inject(input)
      ret = -1
      complete = false

      self.setExitType(0)

      # Check a predefined binding.
      if self.checkBind(:BUTTON, input)
        complete = true
      else
        case input
        when CDK::KEY_ESC
          self.setExitType(input)
          complete = true
        when Ncurses::ERR
          self.setExitType(input)
          complete = true
        when ' '.ord, CDK::KEY_RETURN, Ncurses::KEY_ENTER
          unless @callback.nil?
            @callback.call(self)
          end
          self.setExitType(Ncurses::KEY_ENTER)
          ret = 0
          complete = true
        when CDK::REFRESH
          @screen.erase
          @screen.refresh
        else
          CDK.Beep
        end
      end

      unless complete
        self.setExitType(0)
      end

      @result_data = ret
      return ret
    end

    def focus
      self.drawText
      @win.wrefresh
    end

    def unfocus
      self.drawText
      @win.wrefresh
    end

    def object_type
      :BUTTON
    end
  end # class BUTTON
end # module CDK
