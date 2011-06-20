#!/usr/bin/env ruby

module FinStmt

  class Cell
    attr_accessor :text, :val, :style, :flags

    def initialize
      @text = nil
      @style = {}
      @flags = {}
    end

    def empty?
      if @text.nil?
        return true
      end
      return @text.length == 0
    end

    def parse(html_str)
      @text = html_str

      # look for underlining
      if html_str =~ /STYLE="([^"]*)"/
        style_str = $1

        if style_str =~ /border-bottom:([^;]*)/
          if $1 =~ /double/
            @style[:underlined] = 2
          else
            @style[:underlined] = 1
          end
        end

        if style_str =~ /border-top:([^;]*)/
          if $1 =~ /double/
            @style[:prev_underlined] = 2
          else
            @style[:prev_underlined] = 1
          end
        end

      end

      # look for indenting
      if html_str =~ /margin-left:([0-9\.]*)/
        @style[:indent] = $1
      end

      # strip everything else out
      @text.gsub!(/<[^>]*>/, '') # totally ignore HTML
      @text.gsub!(/&nbsp;/, ' ') # render spaces
      @text.gsub!(/^[ \n]*/, '') # kill leading whitespace
      @text.gsub!(/[ \n]*$/, '') # kill trailing whitespace

      # convert to floating point number
      begin
        @val = Float(@text.gsub(/[^0-9]*/,''))
      rescue
        @val = nil
      end

    end
  end

  class Sheet
    attr_accessor :rows

    def initialize
      @rows = []
    end

    def parse(filename)
      parse_pre(filename)
      delete_empty_columns
      parse_post
    end

  private

    def parse_pre(filename)
      # read all the lines
      f = File.open(filename, 'r')
      sheet = f.readlines.join
      f.close

      # remove header and footer
      sheet.gsub!(/^.*<TABLE/, '<TABLE')
      sheet.gsub!(/<\/TABLE>.*$/, '')
      
      # remove newlines
      sheet.gsub!(/\n/, ' ')
      sheet.gsub!(/<BR>/, ' ')
      
      # split into rows
      sheet.split('</TR>').each do |cur_row|

        row_out = []
      
        cur_row.gsub(/^.*<TR[^>]*>[^<]*<TD/, "<TD").split(/<\/TD>/).each do |cur_cell|
          cell_out = Cell.new
          cell_out.parse(cur_cell)
          row_out.push(cell_out)
        end

        @rows.push(row_out)

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
      Array(0..last_col).reverse.each do |idx|
        if col_filled_count[idx] < min_filled_count
          #puts "Column #{idx} - delete (#{col_filled_count[idx]} < #{min_filled_count})"
          @rows.each { |r| r.delete_at(idx) }
        else
          #puts "Column #{idx} - keep (#{col_filled_count[idx]} >= #{min_filled_count})"
        end
      end

    end

    def parse_post

      # find cells with :border_top, and set :underlined in the above cell
      (1..(@rows.length-1)).each do |row_idx|
        (0..(@rows[row_idx].length-1)).each do |col_idx|
          if @rows[row_idx][col_idx].style[:prev_underlined]

            @rows[row_idx-1][col_idx].style[:underlined] = @rows[row_idx][col_idx].style[:prev_underlined]
            @rows[row_idx][col_idx].style.delete(:prev_underlined)

          end
        end
      end

    end

  end

  class BalSheet < Sheet
    attr_accessor :assets, :liabs, :equity
    attr_accessor :total_assets, :total_liabs, :total_equity
    def initialize
      super

      @assets = []
      @liabs = []
      @equity = []
      @total_assets = nil
      @total_liabs = nil
      @total_equity = nil
    end

    def parse(filename)
      super(filename)
      find_assets_liabs_and_equity
    end

  private
    def find_assets_liabs_and_equity
      @state = :waiting_for_cur_assets
      @rows.each do |cur_row|
        @next_state = nil
        case @state
        when :waiting_for_cur_assets
          if !cur_row[0].nil? and cur_row[0].text == "Current assets:"
            @next_state = :reading_current_assets
          end

        when :reading_current_assets
          if cur_row[0].text == "Total current assets"
            @next_state = :reading_non_current_assets
          else
            cur_row[0].flags[:current] = true
            @assets.push(cur_row)
          end

        when :reading_non_current_assets
          if cur_row[0].text == "Total assets"
            @next_state = :waiting_for_cur_liabs
            @total_assets = cur_row
          else
            cur_row[0].flags[:non_current] = true
            @assets.push(cur_row)
          end

        when :waiting_for_cur_liabs
          if cur_row[0].text == "Current liabilities:"
            @next_state = :reading_cur_liabs
          end

        when :reading_cur_liabs
          if cur_row[0].text == "Total current liabilities"
            @next_state = :reading_non_current_liabilities
          else
            cur_row[0].flags[:current] = true
            @liabs.push(cur_row)
          end

        when :reading_non_current_liabilities
          if cur_row[0].text == "Stockholders&#146; equity:"
            @next_state = :reading_shareholders_equity
          else
            cur_row[0].flags[:non_current] = true
            @liabs.push(cur_row)
          end

        when :reading_shareholders_equity
          if cur_row[0].text == "Total stockholders&#146; equity"
            @next_state = :done
            @total_equity = cur_row
          else
            @equity.push(cur_row)
          end

        when :done
          if cur_row[0].text == "Total liabilities and stockholders&#146; equity"
            raise "TL&SE[1] is nil" if cur_row[1].nil?
            raise "TL&SE[2] is nil" if cur_row[2].nil?
            @total_liabs = cur_row
            @total_liabs[0].text = "Total Liabilities"
            @total_liabs[1].val = cur_row[1].val - @total_equity[1].val 
            @total_liabs[2].val = cur_row[2].val - @total_equity[2].val
            @total_liabs[1].text = "" # FIXME
            @total_liabs[2].text = "" # FIXME
          end

        else
          raise "Balance sheet parser state machine.  Got into weird state, #{@state}"
        end

        if !@next_state.nil?
          #puts "Switching to state: #{@next_state}"
          @state = @next_state
        end
      end

      if @state != :done
        raise "Balance sheet parser state machine.  Unexpected final state, #{@state}"
      end
    end

  end

end

bs = FinStmt::BalSheet.new
bs.parse('balsheet.html')

