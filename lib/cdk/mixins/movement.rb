module CDK
  module Movement
    def move(xplace, yplace, relative, refresh_flag)
      self.move_specific(xplace, yplace, relative, refresh_flag,
          [@win, @shadow_win], [])
    end

    def move_specific(xplace, yplace, relative, refresh_flag,
        windows, subwidgets)
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

      # Adjust the window if we need to
      xtmp = [xpos]
      ytmp = [ypos]
      alignxy(@screen.window, xtmp, ytmp, @box_width, @box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Get the difference
      xdiff = current_x - xpos
      ydiff = current_y - ypos

      # Move the window to the new location.
      windows.each do |window|
        CDK.moveCursesWindow(window, -xdiff, -ydiff)
      end

      subwidgets.each do |subwidget|
        subwidget.move(xplace, yplace, relative, false)
      end

      # Touch the windows so they 'move'
      CDK::SCREEN.refreshCDKWindow(@screen.window)

      # Redraw the window, if they asked for it
      if refresh_flag
        self.draw(@box)
      end
    end

    # This allows the user to use the cursor keys to adjust the
    # postion of the widget.
    def position(win)
      parent = @screen.window
      orig_x = win.getbegx
      orig_y = win.getbegy
      beg_x = parent.getbegx
      beg_y = parent.getbegy
      end_x = beg_x + @screen.window.getmaxx
      end_y = beg_y + @screen.window.getmaxy

      # Let them move the widget around until they hit return.
      while !([CDK::KEY_RETURN, Ncurses::KEY_ENTER].include?(
          key = self.getch([])))
        case key
        when Ncurses::KEY_UP, '8'.ord
          if win.getbegy > beg_y
            self.move(0, -1, true, true)
          else
            CDK.Beep
          end
        when Ncurses::KEY_DOWN, '2'.ord
          if (win.getbegy + win.getmaxy) < end_y
            self.move(0, 1, true, true)
          else
            CDK.Beep
          end
        when Ncurses::KEY_LEFT, '4'.ord
          if win.getbegx > beg_x
            self.move(-1, 0, true, true)
          else
            CDK.Beep
          end
        when Ncurses::KEY_RIGHT, '6'.ord
          if (win.getbegx + win.getmaxx) < end_x
            self.move(1, 0, true, true)
          else
            CDK.Beep
          end
        when '7'.ord
          if win.getbegy > beg_y && win.getbegx > beg_x
            self.move(-1, -1, true, true)
          else
            CDK.Beep
          end
        when '9'.ord
          if (win.getbegx + win.getmaxx) < end_x && win.getbegy > beg_y
            self.move(1, -1, true, true)
          else
            CDK.Beep
          end
        when '1'.ord
          if win.getbegx > beg_x && (win.getbegy + win.getmaxy) < end_y
            self.move(-1, 1, true, true)
          else
            CDK.Beep
          end
        when '3'.ord
          if (win.getbegx + win.getmaxx) < end_x &&
              (win.getbegy + win.getmaxy) < end_y
            self.move(1, 1, true, true)
          else
            CDK.Beep
          end
        when '5'.ord
          self.move(CDK::CENTER, CDK::CENTER, false, true)
        when 't'.ord
          self.move(win.getbegx, CDK::TOP, false, true)
        when 'b'.ord
          self.move(win.getbegx, CDK::BOTTOM, false, true)
        when 'l'.ord
          self.move(CDK::LEFT, win.getbegy, false, true)
        when 'r'.ord
          self.move(CDK::RIGHT, win.getbegy, false, true)
        when 'c'.ord
          self.move(CDK::CENTER, win.getbegy, false, true)
        when 'C'.ord
          self.move(win.getbegx, CDK::CENTER, false, true)
        when CDK::REFRESH
          @screen.erase
          @screen.refresh
        when CDK::KEY_ESC
          self.move(orig_x, orig_y, false, true)
        else
          CDK.Beep
        end
      end
    end
  end # module Movement
end # module CDK
