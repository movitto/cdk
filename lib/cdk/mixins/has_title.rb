module CDK
  module HasTitle
    # Set the widget's title.
    def setTitle (title, box_width)
      if !title.nil? 
        temp = title.split("\n")
        @title_lines = temp.size
        
        if box_width >= 0
          max_width = 0
          temp.each do |line|
            len = []
            align = []
            holder = char2Chtype(line, len, align)
            max_width = [len[0], max_width].max
          end
          box_width = [box_width, max_width + 2 * @border_size].max
        else
          box_width = -(box_width - 1)
        end

        # For each line in the title convert from string to chtype array
        title_width = box_width - (2 * @border_size)
        @title = []
        @title_pos = []
        @title_len = []
        (0...@title_lines).each do |x|
          len_x = []
          pos_x = []
          @title << char2Chtype(temp[x], len_x, pos_x)
          @title_len.concat(len_x)
          @title_pos << justify_string(title_width, len_x[0], pos_x[0])
        end
      end

      return box_width
    end

    # Draw the widget's title
    def drawTitle(win)
      (0...@title_lines).each do |x|
        Draw.writeChtype(@win, @title_pos[x] + @border_size,
            x + @border_size, @title[x], CDK::HORIZONTAL, 0,
            @title_len[x])
      end
    end

    # Remove storage for the widget's title.
    def cleanTitle
      @title_lines = ''
    end
  end # module HasTitle
end # module CDK
