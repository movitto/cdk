module CDK
  module HasScreen
    attr_accessor :screen_index,
                  :screen,
                  :is_visible

    def init_screen
      @is_visible = true
    end

    def SCREEN_XPOS(n)
      n + @border_size
    end

    def SCREEN_YPOS(n)
      n + @border_size + @title_lines
    end
  end # module HasScreen
end # module CDK
