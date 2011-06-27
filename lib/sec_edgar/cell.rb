module SecEdgar

  class Cell
    attr_accessor :log, :text, :val, :flags

    def initialize
      @text = nil
      @val = nil
      @flags = {}
    end

    def empty?
      if @text.nil?
        return true
      end
      return @text.length == 0
    end

    def is_number?
      !@val.nil?
    end

    def parse(text_in)
      # clean up the text 
      @text = text_in.gsub(/[\r\n]/,' ') # turn newlines into whitespace
      @text.gsub!(/[^\(\)A-Za-z0-9,'":\. ]/, '')
      @text.gsub!(/^ */, '')            # kill leading whitespace
      @text.gsub!(/ *$/, '')            # kill trailing whitespace
      @text.gsub!(/ +/, ' ')            # collapse consecutive spaces

      # If there are any alphabetic characters, return it as a string
      alpha_str = @text.gsub(/[^A-Za-z]/,'')
      if alpha_str.length > 2
        # its a text string.  Done.
      else
        # Otherwise, try converting it to a Float or Integer
        numer_str = @text.gsub(/\(/,'-').gsub(/\)/,'') # turn "(22)" into "-22"
        numer_str = numer_str.gsub(/[^\-0-9.]/,'') # get rid of all other non-numbers characters
        return if numer_str.length == 0
        if numer_str.match('\.$')
          numer_str += "0"
        end
        @val = Float(numer_str)
      end

    end
  
  end

end
