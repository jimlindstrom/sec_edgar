module SecEdgar

  class FinancialStatement
    attr_accessor :log, :name, :rows, :sheet, :num_cols, :report_dates
    attr_accessor :base_multiplier
  
    def initialize
      @report_dates = []
      @rows = []
      @name = ""
    end
  
    def parse(edgar_fin_stmt)
      parse_html(edgar_fin_stmt)
      delete_empty_columns
      parse_reporting_dates
      parse_second_pass_for_base_multiplier

      return true
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
        cur_rows.each do |row| 
          if !row[0].nil?
            f.puts(row[0].text) 
          end
        end
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
          new_row = [@rows[idx][0]]
          while new_row.length < stmt2.rows[idx].length
            new_row.push(Cell.new)
          end
          stmt2.rows.insert(idx,new_row)
        elsif cur_diff == ">"
          new_row = [stmt2.rows[idx][0]]
          while new_row.length < @rows[idx].length
            new_row.push(Cell.new)
          end
          @rows.insert(idx,new_row)
        else
        end
      end
  
      # merge them together
      @rows.size.times do |i|
        @rows[i].concat(stmt2.rows[i])
      end
    end

    def set_base_multiplier(str)

      case str
      when "millions"
        @base_multiplier = 1000000
      when "thousands"
        @base_multiplier = 1000
      else
        raise "Unknown base multiplier #{str}"
      end

    end

  private

     def parse_html(edgar_fin_stmt)

      edgar_fin_stmt.children.each do |row_in| 
        if row_in.is_a? Hpricot::Elem
          row_out = []
          row_in.children.each do |cell_str|
            # in case there's a "colspan" - parse it and push some blank cells
            if cell_str.is_a? Hpricot::Elem
              if !cell_str.attributes['colspan'].nil? and cell_str.attributes['colspan'] =~ /\d/
                Integer(cell_str.attributes['colspan']).times do
                  cell = Cell.new { |c| c.log = @log }
                  cell.parse("") # not sure if this is needed
                  row_out.push(cell)
                end
              end
            end

            cell = Cell.new { |c| c.log = @log }
            cell.parse( String(cell_str.to_plain_text) )
            row_out.push(cell)
          end

          @rows.push(row_out)
        end
      end

    end

    def delete_empty_columns

      last_col = @rows.collect{ |r| r.length }.max - 1

      # figure out how many times each column is actually filled in
      col_filled_count = (0..last_col).map do |col|
        col_filled = @rows.collect do |r|
          if (col < r.length) and (not r[col].empty?)
            1
          else
            0
          end
        end
        eval col_filled.join("+")
      end

      # define a threshold (must be filed in >50% of the time)
      min_filled_count = Integer(col_filled_count.max * 5/10)

      # delete each column that isn't sufficiently filled in
      @num_cols = 0
      Array(0..last_col).reverse.each do |idx|
        if col_filled_count[idx] < min_filled_count
          @log.debug("Column #{idx} - delete (#{col_filled_count[idx]} < #{min_filled_count})") if @log
          @rows.each { |r| r.delete_at(idx) }
        else
          @log.debug("Column #{idx} - keep (#{col_filled_count[idx]} >= #{min_filled_count})") if @log
          @num_cols += 1
        end
      end
      @num_cols -= 1 # because the first column is just the label

      # convert rows to SheetRows
      @sheet = []
      @rows.each do |r|
        sr = SheetRow.new(@num_cols, 0)
        sr.label = r[0].text
        sr.flags = r[0].flags
        sr.cols  = r[1..r.length].collect { |x| x.val }
        @sheet.push(sr)
      end

    end

    def parse_reporting_dates
      # pull out the date ranges
      @rows[0..10].each do |row|
        row[1..(row.length-1)].each_with_index do |cell, idx|
          if cell.text =~ /([0-9]{4})/ # check later ones too
            @report_dates[idx] = $1
          end
        end
      end
    end

    # FIXME: we may not need this....
    def parse_second_pass_for_base_multiplier
      # pull out the date ranges
      @rows[0..10].each do |row|
        row[1..(row.length-1)].each_with_index do |cell, idx|
          if cell.text.downcase =~ /^in (billions|millions|thousands)/
            set_base_multiplier($1)
          elsif cell.text.downcase =~ /\(in (billions|millions|thousands)/
            set_base_multiplier($1)
          elsif cell.text.downcase =~ /\((billion|million|thousand)/ # AMD 2003 10-k
            set_base_multiplier($1)
          end
        end
      end
    end

  end
  
end
