module Hpricot
  class Elem

    # traverse backward (previous siblings) and up (parents) looking for 
    # nodes who match a given set of regexes
    def search_tree_reverse(regexes, depth)
      # see if this node contains strings maching any of the regexes
      str = self.to_plain_text.downcase 
      regexes.each do |r|
        if str =~ r
          return { :elem => self, :str => str, :regex => r }
        end
      end
    
      # If we've bottomed out, it's game over
      return nil if (depth == 0)

      # try a previous node (walking back until you find one that's not a Hpricot::Text
      prev_node = self.previous
      while !prev_node.nil?
        if prev_node.class == Hpricot::Elem 
          return prev_node.search_tree_reverse(regexes, depth-1)
        end
        prev_node = prev_node.previous
      end

      # last option: go up to the parent
      return self.parent.search_tree_reverse(regexes, depth-1)
    end

  end
end

module SecEdgar

  class FinancialStatement
    attr_accessor :log, :name, :rows, :sheet, :num_cols, :report_dates
    attr_accessor :base_multiplier

    BASE_MULTIPLIER_REGEXES =
      [ /^in (millions|thousands)/,
        /\(in[ \r\n]*(millions|thousands)/,
        /\(in.(millions|thousands)/,
        /\(unaudited, in.(millions|thousands)/ ]
  
    def initialize
      @report_dates = []
      @rows = []
      @name = ""
    end

    ###########################################################################
    # Parsing
    ###########################################################################
 
    def parse(table_elem)
      parse_table(table_elem)
      return false if !parse_reporting_dates

      delete_empty_columns
      convert_rows_to_sheetrows

      return parse_base_multiplier(table_elem)
    end
   
    ###########################################################################
    # Debugging, Exporting
    ###########################################################################

    def write_to_csv(filename=nil)
      filename = @name + ".csv" if filename.nil?
      f = File.open(filename, "w")
      @rows.each do |row|
        f.puts row.collect{ |r| r.text }.join("~")
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
   
    ###########################################################################
    # Merging with other financial statements
    ###########################################################################

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

    ###########################################################################
    # Validating sheets to see that they've been properly parsed
    ###########################################################################

    def fail_if_doesnt_equal(name_of_a, a, b, str=nil)
      if a != b
        msg = "#{@name} validation fail: #{name_of_a} (#{a}) != b"
        @log.error(msg)
        @log.error("Note: #{str}") if !str.nil?
        filename = @name + String(Integer(Time.now.to_f))+".csv"
        @log.error("see #{filename}")
        write_to_csv(filename)
        raise ParseError, msg
      end
    end

    def fail_if_equals(name_of_a, a, b, str=nil)
      if a == b
        msg = "#{@name} validation fail: #{name_of_a} (#{a}) != b"
        @log.error(msg)
        @log.error("Note: #{str}") if !str.nil?
        filename = @name + String(Integer(Time.now.to_f))+".csv"
        @log.error("see #{filename}")
        write_to_csv(filename)
        raise ParseError, msg
      end
    end

    def validate
      fail_if_equals("report_dates",    @report_dates,    [])
      fail_if_equals("base_multiplier", @base_multiplier, nil)
    end

  private

    ###########################################################################
    # Parsing helpers
    ###########################################################################

    def parse_table(table_elem)

      table_elem.children.each do |row_in| 
        # FIXME: do this better with hpricot search for TR and TD
        if row_in.is_a? Hpricot::Elem
          row_out = []
          if !row_in.children.nil?
            row_in.children.each do |cell_str|

              # parse the contents of this cell
              cell = Cell.new { |c| c.log = @log }
              cell.parse( String(cell_str.to_plain_text) )
              row_out.push(cell)

              # in case there's a "colspan" - parse it and push some blank cells
              if cell_str.is_a? Hpricot::Elem
                if !cell_str.attributes['colspan'].nil? and cell_str.attributes['colspan'] =~ /\d/
                  (Integer(cell_str.attributes['colspan'])-1).times do
                    cell = Cell.new { |c| c.log = @log }
                    cell.parse("") # not sure if this is needed
                    row_out.push(cell)
                  end
                end
              end

            end
          end

          @rows.push(row_out) if !row_out.empty?
        end
      end

    end

    def get_col_filled_count
      col_filled_count = []
      (@rows.collect{ |r| r.length }.max).times { col_filled_count.push 0 }
      @rows.each do |r|
        r.each_with_index do |c, idx|
          if !c.nil? and !c.empty?
            col_filled_count[idx] += 1
          end
        end
      end
      return col_filled_count
    end

    def delete_cols_if_less_full_than_threshold(col_filled_count, min_filled_count)
      @num_cols = @rows.collect{ |r| r.length }.max
      Array(0..(@num_cols-1)).reverse.each do |idx|
        if col_filled_count[idx] < min_filled_count
          ## @log.debug("  deleting column #{idx} (cols filled: #{col_filled_count[idx]} <  threshold: #{min_filled_count}") if @log
          @rows.each { |r| r.delete_at(idx) }
          @num_cols -= 1
        else
          ## @log.debug("  keeping  column #{idx} (cols filled: #{col_filled_count[idx]} >= threshold: #{min_filled_count}") if @log
        end
      end
    end

    def delete_empty_columns

      # delete completely empty columns
      col_filled_count = get_col_filled_count
      min_filled_count = 1
      delete_cols_if_less_full_than_threshold(col_filled_count, min_filled_count)

      # some sheets use separate TDs/cols to indent.  Undo this
      max_col = 1
      @rows.each do |r|
        if r[0].nil? or r[0].empty?
          indices = Array(1..max_col)
          while !indices.empty?
            idx = indices.shift
            if !r[idx].nil? and !r[idx].empty? 
              if r[idx].val.nil?  # only swap columns if it doesn't parse as a number
                tmp     = r[0] 
                r[0]    = r[idx]
                r[idx]  = tmp
                max_col = [idx+1, max_col].max
              end
              indices = [] # done
            end
          end
        end
      end

      # delete those with less than 30% of cells filled in
      col_filled_count = get_col_filled_count
      min_filled_count = Integer(col_filled_count.max * 0.60)
      delete_cols_if_less_full_than_threshold(col_filled_count, min_filled_count)
    end

    def convert_rows_to_sheetrows
      @sheet = []
      @rows.each do |r|
        if r.length > 0
          sr = SheetRow.new(@num_cols, 0)
          sr.label = r[0].text
          sr.flags = r[0].flags
          sr.cols  = r[1..r.length].collect { |x| x.val }
          @sheet.push(sr)
        end
      end
    end

    def parse_reporting_dates
      @rows[0..20].each do |row|
        ## @log.debug("  looking for report date year (ignoring column 0: \"#{row[0].text}\"") if @log
        row[1..(row.length-1)].each_with_index do |cell, idx|
          if cell.text =~ /([0-9]{4})/ # check later ones too
            @report_dates.push $1
            ## @log.debug("  looking for report date year in \"#{cell.text}\" (found $1)") if @log
          else
            ## @log.debug("  looking for report date year in \"#{cell.text}\" (nothing found)") if @log
          end
        end
      
        if !@report_dates.empty?
          return true
        end
      end
      
      @log.warn("couldn't find report dates in #{@name}") if @log
      return false
    end

    ###########################################################################
    # Merging with other financial statements
    ###########################################################################

    def parse_base_multiplier(table_elem)
      result = table_elem.search_tree_reverse(BASE_MULTIPLIER_REGEXES, 10)
      if result.nil?
        @log.debug("couldn't find base multiplier") if @log
        return false
      end

      result[:str] =~ result[:regex]

      case $1
      when "billions", "billion"
        @base_multiplier = 1000 * 1000 * 1000
      when "millions", "million"
        @base_multiplier = 1000 * 1000
      when "thousands", "thousand"
        @base_multiplier = 1000
      else
        raise ParseError, "Unknown base multiplier #{str}"
      end
    end

  end
  
end
