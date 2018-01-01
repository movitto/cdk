module CDK
  VERSION_MAJOR = 0
  VERSION_MINOR = 9
  VERSION_PATCH = 0

  CDK_PATHMAX = 256

  L_MARKER = '<'
  R_MARKER = '>'

  LEFT       = 9000
  RIGHT      = 9001
  CENTER     = 9002
  TOP        = 9003
  BOTTOM     = 9004
  HORIZONTAL = 9005
  VERTICAL   = 9006
  FULL       = 9007

  NONE = 0
  ROW  = 1
  COL  = 2

  MAX_BINDINGS = 300
  MAX_ITEMS    = 2000
  MAX_BUTTONS  = 200

  def self.CTRL(c)
    c.ord & 0x1f
  end

  REFRESH    = CTRL('L')
  PASTE      = CTRL('V')
  COPY       = CTRL('Y')
  ERASE      = CTRL('U')
  CUT        = CTRL('X')
  BEGOFLINE  = CTRL('A')
  ENDOFLINE  = CTRL('E')
  BACKCHAR   = CTRL('B')
  FORCHAR    = CTRL('F')
  TRANSPOSE  = CTRL('T')
  NEXT       = CTRL('N')
  PREV       = CTRL('P')
  DELETE     = "\177".ord
  KEY_ESC    = "\033".ord
  KEY_RETURN = "\012".ord
  KEY_TAB    = "\t".ord

  def self.Version
    return "%d.%d.%d" % [CDK::VERSION_MAJOR,
                         CDK::VERSION_MINOR,
                         CDK::VERSION_PATCH]
  end
end # module CDK
