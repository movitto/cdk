module CDK
  module Justifications
    # This takes a string, a field width, and a justification type
    # and returns the adjustment to make, to fill the justification
    # requirement
    def justify_string (box_width, mesg_length, justify)
      # make sure the message isn't longer than the width
      # if it is, return 0
      if mesg_length >= box_width
        return 0
      end

      # try to justify the message
      case justify
      when LEFT
        0
      when RIGHT
        box_width - mesg_length
      when CENTER
        (box_width - mesg_length) / 2
      else
        justify
      end
    end
  end # module Justifications
end # module CDK
