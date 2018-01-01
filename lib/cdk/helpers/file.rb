module CDK
  # This reads a file and sticks it into the list provided.
  def self.readFile(filename, array)
    begin
      fd = File.new(filename, "r")
    rescue
      return -1
    end

    lines = fd.readlines.map do |line|
      if line.size > 0 && line[-1] == "\n"
        line[0...-1]
      else
        line
      end
    end
    array.concat(lines)
    fd.close
    array.size
  end

  # This opens the current directory and reads the contents.
  def self.getDirectoryContents(directory, list)
    counter = 0

    # Open the directory.
    Dir.foreach(directory) do |filename|
      next if filename == '.'
      list << filename
    end

    list.sort!
    return list.size
  end

  # Returns the directory for the given pathname, i.e. the part before the
  # last slash
  # For now this function is just a wrapper for File.dirname kept for ease of
  # porting and will be completely replaced in the future
  def self.dirName (pathname)
    File.dirname(pathname)
  end
end # module CDK
