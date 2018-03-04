module CDK
  module Formattable
    attr_reader :skip_formatting

    # XXX Make sure to override this to undo any formatting operations
    def skip_formatting=(b)
      @skip_formatting_set  = true
      @skip_formatting = b
    end

    def skip_formatting?
      @skip_formatting_set ? @skip_formatting : false
    end
  end # module CommonControls
end # module CDK
