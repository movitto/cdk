module CDK
  def self.digit?(character)
    !(character.match(/^[[:digit:]]$/).nil?)
  end

  def self.alpha?(character)
    !(character.match(/^[[:alpha:]]$/).nil?)
  end

  def self.isChar(c)
    c >= 0 && c < Ncurses::KEY_MIN
  end
end # module CDK
