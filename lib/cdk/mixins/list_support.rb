module CDK
  module ListSupport
    # This looks for a subset of a word in the given list
    def search_list(list, list_size, pattern)
      index = -1

      if pattern.size > 0
        (0...list_size).each do |x|
          len = [list[x].size, pattern.size].min
          ret = (list[x][0...len] <=> pattern)

          # If 'ret' is less than 0 then the current word is alphabetically
          # less than the provided word.  At this point we will set the index
          # to the current position.  If 'ret' is greater than 0, then the
          # current word is alphabetically greater than the given word. We
          # should return with index, which might contain the last best match.
          # If they are equal then we've found it.
          if ret < 0
            index = ret
          else
            if ret == 0
              index = x
            end
            break
          end
        end
      end
      return index
    end
  end # module ListSupport
end # module CDK
