module CDK
  module ExitConditions
    attr_reader :exit_type

    def init_exit_conditions
      # set default exit-types
      @exit_type = :NEVER_ACTIVATED
    end

    # Set the object's exit-type based on the input.
    # The .exitType field should have been part of the CDKOBJS struct, but it
    # is used too pervasively in older applications to move (yet).
    def setExitType(ch)
      case ch
      when CDK::KEY_ESC
        @exit_type = :ESCAPE_HIT
      when CDK::KEY_TAB, Ncurses::KEY_ENTER, CDK::KEY_RETURN
        @exit_type = :NORMAL
      when Ncurses::ERR
        @exit_type = :TIMEOUT
      when 0
        @exit_type = :EARLY_EXIT
      end
    end

    def resetExitType
      @exit_type = :NEVER_ACTIVATED
    end

  end # module ExitConditions
end # module CDK
