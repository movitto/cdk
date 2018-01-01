module CDK
  module Alignments
    # This takes an x and y position and realigns the values iff they sent in
    # values like CENTER, LEFT, RIGHT
    #
    # window is an Ncurses::WINDOW object
    # xpos, ypos is an array with exactly one value, an integer
    # box_width, box_height is an integer
    def alignxy (window, xpos, ypos, box_width, box_height)
      first = window.getbegx
      last = window.getmaxx
      if (gap = (last - box_width)) < 0
        gap = 0
      end
      last = first + gap

      case xpos[0]
      when LEFT
        xpos[0] = first
      when RIGHT
        xpos[0] = first + gap
      when CENTER
        xpos[0] = first + (gap / 2)
      else
        if xpos[0] > last
          xpos[0] = last
        elsif xpos[0] < first
          xpos[0] = first
        end
      end

      first = window.getbegy
      last = window.getmaxy
      if (gap = (last - box_height)) < 0
        gap = 0
      end
      last = first + gap

      case ypos[0]
      when TOP
        ypos[0] = first
      when BOTTOM
        ypos[0] = first + gap
      when CENTER
        ypos[0] = first + (gap / 2)
      else
        if ypos[0] > last
          ypos[0] = last
        elsif ypos[0] < first
          ypos[0] = first
        end
      end
    end
  end # module Alignments
end # module CDK
