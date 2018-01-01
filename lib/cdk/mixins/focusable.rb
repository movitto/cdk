module CDK
  module Focusable
    attr_accessor :has_focus
    attr_accessor :accepts_focus

    def init_focus
      @has_focus = true
      @accepts_focus = false
    end

    def focus
    end

    def unfocus
    end
  end # module Focusable
end # module CDK
