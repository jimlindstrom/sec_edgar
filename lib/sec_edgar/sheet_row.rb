module SecEdgar

  class SheetRow
    attr_accessor :label, :flags, :cols

    def initialize(num_cols, initial_val=nil)
      @label = ""
      @flags = { }
      @cols  = [ ]
      num_cols.times { cols.push initial_val }
    end

    def num_cols
      cols.length
    end
   
    def subtract(b)
      while @cols.length < b.cols.length
        @cols.push nil
      end

      @cols = @cols.zip(b.cols).collect do |x,y| 
        if x.nil? and y.nil?
          nil
        elsif x.nil?
          0.0 - y
        elsif y.nil?
          x
        else
          x - y 
        end
      end
    end

    def add(b)
      while @cols.length < b.cols.length
        @cols.push nil
      end

      @cols = @cols.zip(b.cols).collect do |x,y| 
        if x.nil? and y.nil?
          nil
        elsif x.nil?
          y
        elsif y.nil?
          x
        else
          x + y 
        end

      end
    end

  end

end

