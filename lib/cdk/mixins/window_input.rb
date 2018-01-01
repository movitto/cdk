module CDK
  module WindowInput
    def inject(a)
    end

    # Set data for preprocessing
    def setPreProcess (fn, data)
      @pre_process_func = fn
      @pre_process_data = data
    end

    # Set data for postprocessing
    def setPostProcess (fn, data)
      @post_process_func = fn
      @post_process_data = data
    end

    def getc
      cdktype = self.object_type
      test = self.bindableObject(cdktype)
      result = @input_window.wgetch

      if result >= 0 && !(test.nil?) && test.binding_list.include?(result) &&
          test.binding_list[result][0] == :getc
        result = test.binding_list[result][1]
      elsif test.nil? || !(test.binding_list.include?(result)) ||
          test.binding_list[result][0].nil?
        case result
        when "\r".ord, "\n".ord
          result = Ncurses::KEY_ENTER
        when "\t".ord
          result = CDK::KEY_TAB
        when CDK::DELETE
          result = Ncurses::KEY_DC
        when "\b".ord
          result = Ncurses::KEY_BACKSPACE
        when CDK::BEGOFLINE
          result = Ncurses::KEY_HOME
        when CDK::ENDOFLINE
          result = Ncurses::KEY_END
        when CDK::FORCHAR
          result = Ncurses::KEY_RIGHT
        when CDK::BACKCHAR
          result = Ncurses::KEY_LEFT
        when CDK::NEXT
          result = CDK::KEY_TAB
        when CDK::PREV
          result = Ncurses::KEY_BTAB
        end
      end

      return result
    end

    def getch(function_key)
      key = self.getc
      function_key << (key >= Ncurses::KEY_MIN && key <= Ncurses::KEY_MAX)
      return key
    end
  end # module WindowInput
end # module CDK
