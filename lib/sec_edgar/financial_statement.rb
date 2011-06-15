module SecEdgar

  class FinancialStatement
    attr_accessor :rows, :name
  
    def initialize
      @rows = []
      @name = ""
    end
  
    def parse_edgar_fin_stmt(edgar_fin_stmt)
      edgar_fin_stmt.children.each do |row| 
        cells = []
        if row.is_a? Hpricot::Elem
          row.children.each do |cell|
            cleaned_str = String(cell.to_plain_text)
            cleaned_str = cleaned_str.gsub(/[\r\n]/,' ')
            if cleaned_str.length > 0
              alpha_str = cleaned_str.gsub(/[^A-Za-z]/,'')
              numer_str = cleaned_str.gsub(/[^0-9.]/,'')
              if alpha_str.length > 2
                cells.push(cleaned_str)
              elsif numer_str.length > 0
                if numer_str.match('\.')
                  cells.push(Float(numer_str))
                else
                  cells.push(Integer(numer_str))
                end
              end
            end
          end
          if cells.length > 0
            @rows.push(cells)
          end
        end
      end
    end
  
    def normalize
      # first figure out how many cols wide the table is at its widest
      max_cols = @rows.sort{|x,y| y.length <=> x.length}[0].length
  
      # now make rows the same width, padding them with empty strings
      @rows.collect!{|r| [r, (r.length..(max_cols-1)).collect{''}].flatten }
    end
  
    def write_to_csv
      f = File.open(@name + ".csv", "w")
      @rows.each do |row|
        f.puts row.join("~")
      end
      f.close
    end
  
    def print
      puts
      puts @name
      @rows.each do |row|
        puts row.join("~")
      end
    end
  
    def merge(stmt2)
      # print 1st statment to a file
      f = File.open("/tmp/merge.1", "w")
      @rows.each do |row|
        f.puts(row[0])
      end
      f.close
  
      # print 2nd statment to a file
      f = File.open("/tmp/merge.2", "w")
      stmt2.rows.each do |row|
        f.puts(row[0])
      end
      f.close
  
      # run an sdiff on it
      $diffs = []
      IO.popen("sdiff -w1 /tmp/merge.1 /tmp/merge.2") do |f|
        f.each { |line| $diffs.push(line.chomp) }
      end
      system("rm /tmp/merge.1 /tmp/merge.2")
      
      # paralellize the arrays, by inserting blank rows
      $diffs.each_with_index do |cur_diff,idx|
        if cur_diff == "<"
          stmt2.rows.insert(idx,[@rows[idx][0]])
        elsif cur_diff == ">"
          @rows.insert(idx,[stmt2.rows[idx][0]])
        else
        end
      end
      normalize
      stmt2.normalize
  
      # merge them together
      @rows.size.times do |i|
        @rows[i].concat(stmt2.rows[i])
      end
    end
  end
  
end
