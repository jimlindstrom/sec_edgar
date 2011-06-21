module SecEdgar

  class FinancialStatement
    attr_accessor :rows, :name
  
    def initialize
      @rows = []
      @name = ""
    end
  
    def parse(edgar_fin_stmt)
      edgar_fin_stmt.children.each do |row_in| 
        if row_in.is_a? Hpricot::Elem
          row_out = []
          row_in.children.each do |cell_str|
            cell = Cell.new
            cell.parse( String(cell_str.to_plain_text) )
            row_out.push(cell) unless cell.empty? ## FIXME: this isn't right
          end

          @rows.push(row_out) if row_out.length > 0
        end
      end

      normalize

      return true
    end
  
    def normalize
      # first figure out how many cols wide the table is at its widest
      max_cols = @rows.collect{ |x| x.length }.max
  
      # now make rows the same width, padding them with empty strings
      @rows.collect!{|r| [r, (r.length..(max_cols-1)).collect{ Cell.new }].flatten }
    end
  
    def write_to_csv(filename=nil)
      filename = @name + ".csv" if filename.nil?
      f = File.open(filename, "w")
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
      # print each statement to a file
      [ [ @rows,      "/tmp/merge.1" ],
        [ stmt2.rows, "/tmp/merge.2" ] ].each do | cur_rows, cur_file |
        f = File.open(cur_file, "w")
        cur_rows.each { |row| f.puts(row[0].text) }
        f.close
      end
  
      # run an sdiff on it
      @diffs = []
      IO.popen("sdiff -w1 /tmp/merge.1 /tmp/merge.2") do |f|
        f.each { |line| @diffs.push(line.chomp) }
      end
      system("rm /tmp/merge.1 /tmp/merge.2")
      
      # paralellize the arrays, by inserting blank rows
      @diffs.each_with_index do |cur_diff,idx|
        if cur_diff == "<"
          stmt2.rows.insert(idx,[@rows[idx][0]])
        elsif cur_diff == ">"
          @rows.insert(idx,[stmt2.rows[idx][0]])
        else
        end
      end
  
      # merge them together
      @rows.size.times do |i|
        @rows[i].concat(stmt2.rows[i])
      end
    end
  end
  
end
