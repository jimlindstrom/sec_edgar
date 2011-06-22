module SecEdgar
  
  class BalanceSheet < FinancialStatement
    AR_ALLOWANCE_REGEX=/, net of allowance of ([$0-9,]+) and ([$0-9,]+)/
    STOCK_REGEX=/par value/
    NUMBER_REGEX=/[\$0-9,]+/
  
    attr_accessor :assets, :liabs, :equity
    attr_accessor :total_assets, :total_liabs, :total_equity

    def initialize
      super()
      @name = "Balance Sheet"

      @assets = []
      @liabs = []
      @equity = []
      @total_assets = nil
      @total_liabs = nil
      @total_equity = nil
    end

    def parse(edgar_fin_stmt)
      ret = super(edgar_fin_stmt)
      return false if ret == false
  
      # parse the common stock line
      @rows.each_with_index do |row, idx|
        if String(row[0]).match(STOCK_REGEX) and
           String(row[1]).match(STOCK_REGEX) then
          @rows[idx].delete_at(0)
          @rows[idx].delete_at(0)
          @rows[idx].insert(0,"Common or Preferred Stock")
  
        elsif String(row[0]).match(STOCK_REGEX)  and
              String(row[1]).match(NUMBER_REGEX) and
              String(row[2]).match(STOCK_REGEX)  and
              String(row[3]).match(NUMBER_REGEX) then
          @rows[idx].delete_at(0)
          @rows[idx].insert(0,"Common or Preferred Stock")
          @rows[idx].delete_at(2)
          @rows[idx].insert(2,"Common or Preferred Stock")
  
        elsif String(row[0]).match(STOCK_REGEX)
          @rows[idx].delete_at(0)
          @rows[idx].insert(0,"Common or Preferred Stock")
        end
      end
  
      # pull out the date ranges
      @rows.each_with_index do |row, idx|
        # Match [][As of Dec 31, 2003][As of Dec 31, 2004]
        if String(row[0]).match(/As[^A-Za-z]*of/) and
           String(row[1]).match(/As[^A-Za-z]*of/) then
          @rows[idx][0].gsub!(/As[^A-Za-z]*of[^A-Za-z]*/,'')
          @rows[idx][1].gsub!(/As[^A-Za-z]*of[^A-Za-z]*/,'')
          @rows[idx].insert(0,"As of")
          @rows[idx].delete_at(3)
  
        # Match [As of][][]
        #       [2003][2004][]
        elsif String(row[0]).match(/As[^A-Za-z]*of/) and
              String(@rows[idx+1][0]).match(/[0-9]{4}/) and
              String(@rows[idx+1][1]).match(/[0-9]{4}/) then
          @rows[idx].concat(@rows[idx+1])
          @rows.delete_at(idx+1)
  
        # Match [December 31][][]
        #       [2003][2004][]
        elsif String(row[0]).match(/[A-Za-z]+[^A-Za-z]+ [0-9]+/) and
              String(@rows[idx+1][0]).match(/[0-9]{4}/) and
              String(@rows[idx+1][1]).match(/[0-9]{4}/) then
          @rows[idx].concat(@rows[idx+1])
          @rows.delete_at(idx+1)
        end
      end
  
      # pull out the A/R allowances
      @rows.each_with_index do |row, index|
        if String(row[0]).match(AR_ALLOWANCE_REGEX)
          # first, (FIXME) pull out the allowances from the regex
          allowances = [$1, $2]
          allowances.map!{|item| item.gsub(/[$,]/,"")} # strip out comma and dollar sign
          allowances_row=["A/R Allowance"].concat(allowances)
  
          # now remove the allowances from the current line
          row[0] = row[0].gsub(AR_ALLOWANCE_REGEX,', net of allowance')
          @rows[index] = row
          @rows[index+1] = allowances_row
        end
      end

      return find_assets_liabs_and_equity()
    end

    def operational_assets(col_idx)
      sum = 0.0
      @assets.each do |cur_asset|
        if cur_asset[0].flags[:operational]
          if !cur_asset[col_idx].val.nil?
            sum += cur_asset[col_idx].val
          end
        end
      end
      return sum
    end

    def financial_assets(col_idx)
      sum = 0.0
      @assets.each do |cur_asset|
        if cur_asset[0].flags[:financial]
          if !cur_asset[col_idx].val.nil?
            sum += cur_asset[col_idx].val
          end
        end
      end
      return sum
    end

    def calculated_total_assets(col_idx)
      sum = 0.0
      @assets.each do |cur_asset|
        if !cur_asset[col_idx].val.nil?
          sum += cur_asset[col_idx].val
        end
      end
      return sum
    end

    def operational_liabs(col_idx)
      sum = 0.0
      @liabs.each do |cur_liab|
        if cur_liab[0].flags[:operational]
          if !cur_liab[col_idx].val.nil?
            sum += cur_liab[col_idx].val
          end
        end
      end
      return sum
    end

    def financial_liabs(col_idx)
      sum = 0.0
      @liabs.each do |cur_liab|
        if cur_liab[0].flags[:financial]
          if !cur_liab[col_idx].val.nil?
            sum += cur_liab[col_idx].val
          end
        end
      end
      return sum
    end

    def calculated_total_liabs(col_idx)
      sum = 0.0
      @liabs.each do |cur_liab|
        if !cur_liab[col_idx].val.nil?
          sum += cur_liab[col_idx].val
        end
      end
      return sum
    end

    def net_financial_assets(col_idx)
      return financial_assets(col_idx) - financial_liabs(col_idx)
    end

    def net_operational_assets(col_idx)
      return operational_assets(col_idx) - operational_liabs(col_idx)
    end

    def common_shareholders_equity(col_idx)
      return net_operational_assets(col_idx) + net_financial_assets(col_idx)
    end

  private
    def find_assets_liabs_and_equity
      ac = AssetClassifier.new
      lc = LiabClassifier.new

      @state = :waiting_for_cur_assets
      @rows.each do |cur_row|
        @log.debug("balance sheet parser.  Cur label: #{cur_row[0].text}") if @log
        @next_state = nil
        case @state
        when :waiting_for_cur_assets
          if !cur_row[0].nil? and cur_row[0].text.downcase == "current assets:"
            @next_state = :reading_current_assets
          end

        when :reading_current_assets
          if cur_row[0].text == "Total current assets"
            @next_state = :reading_non_current_assets
          elsif cur_row[0].text.downcase =~ /total cash.*/
            # don't save the totals line
          else
            cur_row[0].flags[:current] = true
            case ac.classify(cur_row[0].text)[:class]
            when :fa
              cur_row[0].flags[:financial] = true
            when :oa
              cur_row[0].flags[:operational] = true
            end
            @assets.push(cur_row)
          end

        when :reading_non_current_assets
          if cur_row[0].text.downcase == "total assets"
            @next_state = :waiting_for_cur_liabs
            @total_assets = cur_row
          else
            cur_row[0].flags[:non_current] = true
            case ac.classify(cur_row[0].text)[:class]
            when :fa
              cur_row[0].flags[:financial] = true
            when :oa
              cur_row[0].flags[:operational] = true
            end
            @assets.push(cur_row)
          end

        when :waiting_for_cur_liabs
          if cur_row[0].text.downcase == "current liabilities:"
            @next_state = :reading_cur_liabs
          end

        when :reading_cur_liabs
          if cur_row[0].text.downcase == "total current liabilities"
            @next_state = :reading_non_current_liabilities
          else
            cur_row[0].flags[:current] = true
            case lc.classify(cur_row[0].text)[:class]
            when :fl
              cur_row[0].flags[:financial] = true
            when :ol
              cur_row[0].flags[:operational] = true
            end
            @liabs.push(cur_row)
          end

        when :reading_non_current_liabilities
          if cur_row[0].text.downcase =~ /stockholders.* equity:/
            @next_state = :reading_shareholders_equity
          elsif cur_row[0].text.downcase =~ /total liab.*/
            # don't save the totals line
          else
            cur_row[0].flags[:non_current] = true
            case lc.classify(cur_row[0].text)[:class]
            when :fl
              cur_row[0].flags[:financial] = true
            when :ol
              cur_row[0].flags[:operational] = true
            end
            @liabs.push(cur_row)
          end

        when :reading_shareholders_equity
          if cur_row[0].text.downcase =~ /total.*stockholders.*equity/
            @next_state = :done
            @total_equity = cur_row
          else
            @equity.push(cur_row)
          end

        when :done
          # FIXME: this should be a 2nd-to-last state and should THEN go to done...
          if cur_row[0].text.downcase =~ /total liabilities and.*equity/
            @total_liabs = cur_row
            @total_liabs[0].text = "total Liabilities"
            @total_liabs[1].val = cur_row[1].val - @total_equity[1].val 
            @total_liabs[2].val = cur_row[2].val - @total_equity[2].val
            @total_liabs[1].text = "" # FIXME
            @total_liabs[2].text = "" # FIXME
          end

        else
          @log.error("Balance sheet parser state machine.  Got into weird state, #{@state}") if @log
          return false
        end

        if !@next_state.nil?
          @log.debug("balance sheet parser.  Switching to state: #{@next_state}") if @log
          @state = @next_state
        end
      end

      if @state != :done
        @log.warn("Balance sheet parser state machine.  Unexpected final state, #{@state}") if @log
        return false
      end

      return true
    end

  end
  
end
