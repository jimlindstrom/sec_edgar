module SecEdgar
  
  class BalanceSheet < FinancialStatement
    AR_ALLOWANCE_REGEX=/, net of allowance of ([$0-9,]+) and ([$0-9,]+)/
    STOCK_REGEX=/par value/
    NUMBER_REGEX=/[\$0-9,]+/
  
    # original values
    attr_accessor :assets, :liabs, :equity 
    attr_accessor :total_assets, :total_liabs, :total_equity 

    # reformulated values
    attr_accessor :operational_assets, :operational_liabs
    attr_accessor :financial_assets, :financial_liabs
    attr_accessor :common_equity 
    attr_accessor :total_oa, :total_fa, :total_ol, :total_fl
    attr_accessor :noa, :nfa, :cse

    def initialize
      super()
      @name = "Balance Sheet"

      @assets = []
      @liabs = []
      @equity = []
      @total_assets = nil
      @total_liabs = nil
      @total_equity = nil

      @operational_assets = []
      @operational_liabs = []
      @financial_assets = []
      @financial_liabs = []
      @common_equity = []
    end

    def parse(edgar_fin_stmt)
      # pull the table into rows (akin to CSV)
      return false if not super(edgar_fin_stmt)
  
      # text-matching to pull out dates, net amounts, etc.
      parse_common_stock_line # pass/fail?
      parse_reporting_periods # pass/fail?
      parse_accounts_receivable # pass/fail?

      # pull apart assets, liabilities, equity (as originally stated)
      return false if not parse_assets_liabs_and_equity
      return false if not classify_assets
      return false if not classify_liabs
      return false if not classify_equity

      return true
    end

    ###########################################################################
    # calculate reformulated values (this needs to change)
    ###########################################################################

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

    ###########################################################################
    # Supplemental parsing functions
    ###########################################################################
  
    def parse_common_stock_line
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
    end

    def parse_reporting_periods
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
    end

    def parse_accounts_receivable
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
    end

    def parse_assets_liabs_and_equity
      @state = :waiting_for_cur_assets
      @rows.each do |cur_row|
        @log.debug("balance sheet parser.  Cur label: #{cur_row[0].text}") if @log
        @next_state = nil
        case @state
        when :waiting_for_cur_assets
          if !cur_row[0].nil? and cur_row[0].text.downcase =~ /current assets[:]*/
            @next_state = :reading_current_assets
          #elsif !cur_row[0].nil? and cur_row[0].text.downcase =~ /^assets$/ # in case they don't break out current ones
          elsif !cur_row[1].val.nil? # if the values have started and we didn't see 'current ...', assume this stmt doesn't break out cur/non-cur
            @log.info("balance sheet parser. this stmt doesn't break out current assets...") if @log
            @next_state = :reading_non_current_assets
          end

        when :reading_current_assets
          if cur_row[0].text.downcase =~ /total current assets/
            @log.debug("balance sheet parser. matched total current assets: #{cur_row[0].text}") if @log
            @next_state = :reading_non_current_assets
          elsif cur_row[0].text.downcase =~ /total cash.*/
            # don't save the totals line
          else
            cur_row[0].flags[:current] = true
            @assets.push(cur_row)
          end

        when :reading_non_current_assets
          if cur_row[0].text.downcase =~ /total assets/
            @next_state = :waiting_for_cur_liabs
            @total_assets = [ nil, cur_row[1].val, cur_row[2].val ] # 3-column specific
          else
            cur_row[0].flags[:non_current] = true
            @assets.push(cur_row)
          end

        when :waiting_for_cur_liabs
          if cur_row[0].text.downcase =~ /current liabilities[:]*/
            @next_state = :reading_cur_liabs
          #elsif cur_row[0].text.downcase =~ /^liabilities.*/ # in case they don't break out current ones
          #  @next_state = :reading_non_current_liabilities
          #elsif cur_row[0].text.downcase =~ /^total liabilities.*/ # in case they don't break out current ones
          elsif !cur_row[1].val.nil? # if the values have started and we didn't see 'current ...', assume this stmt doesn't break out cur/non-cur
            @next_state = :reading_non_current_liabilities
          end

        when :reading_cur_liabs
          if cur_row[0].text.downcase == "total current liabilities"
            @next_state = :reading_non_current_liabilities
          else
            cur_row[0].flags[:current] = true
            @liabs.push(cur_row)
          end

        when :reading_non_current_liabilities
          if cur_row[0].text.downcase =~ /(share|stock)holders.* equity:/
            @next_state = :reading_shareholders_equity
          elsif cur_row[0].text.downcase =~ /common stock/ 
            @equity.push(cur_row)
            @next_state = :reading_shareholders_equity
          elsif cur_row[0].text.downcase =~ /total liab.*/
            # don't save the totals line
          else
            cur_row[0].flags[:non_current] = true
            @liabs.push(cur_row)
          end

        when :reading_shareholders_equity
          if cur_row[0].text.downcase =~ /total.*(share|stock)holders.*equity/
            @next_state = :done
            @total_equity = [ nil, cur_row[1].val, cur_row[2].val ]
          else
            @equity.push(cur_row)
          end

        when :done
          # FIXME: this should be a 2nd-to-last state and should THEN go to done...
          if cur_row[0].text.downcase =~ /total liabilities and.*equity/
            @total_liabs = [ nil, nil, nil ]
            @total_liabs[1] = cur_row[1].val - @total_equity[1]
            @total_liabs[2] = cur_row[2].val - @total_equity[2]
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

    ###########################################################################
    # Classifiers for assets, liabilities, equity
    ###########################################################################

    def classify_assets
      ac = AssetClassifier.new

      @total_oa = [nil, 0.0, 0.0]
      @total_fa = [nil, 0.0, 0.0]
      @noa = [nil, 0.0, 0.0]
      @nfa = [nil, 0.0, 0.0]
      @assets.each do |a|
        if a.length < 3
          @log.warn("asset must be 3 columns wide #{a}")
        else
          case ac.classify(a[0].text)[:class]
          when :oa
            @operational_assets.push(a)
            @total_oa[1] += a[1].val if !a[1].val.nil?
            @total_oa[2] += a[2].val if !a[2].val.nil?
            @noa[1] += a[1].val if !a[1].val.nil?
            @noa[2] += a[2].val if !a[2].val.nil?
          when :fa
            @financial_assets.push(a)
            @total_fa[1] += a[1].val if !a[1].val.nil?
            @total_fa[2] += a[2].val if !a[2].val.nil?
            @nfa[1] += a[1].val if !a[1].val.nil?
            @nfa[2] += a[2].val if !a[2].val.nil?
          else
            raise "Unknown class #{ac.classify(a[0].text)[:class]}"
          end
        end
      end
    end

    def classify_liabs
      lc = LiabClassifier.new

      @total_ol = [nil, 0.0, 0.0]
      @total_fl = [nil, 0.0, 0.0]
      @liabs.each do |l|
        if l.length < 3
          @log.warn("asset must be 3 columns wide #{l}")
        else
          case lc.classify(l[0].text)[:class]
          when :ol
            @operational_liabs.push(l)
            @total_ol[1] += l[1].val if !l[1].val.nil?
            @total_ol[2] += l[2].val if !l[2].val.nil?
            @noa[1] -= l[1].val if !l[1].val.nil?
            @noa[2] -= l[2].val if !l[2].val.nil?
          when :fl
            @financial_liabs.push(l)
            @total_fl[1] += l[1].val if !l[1].val.nil?
            @total_fl[2] += l[2].val if !l[2].val.nil?
            @nfa[1] -= l[1].val if !l[1].val.nil?
            @nfa[2] -= l[2].val if !l[2].val.nil?
          else
            raise "Unknown class #{lc.classify(l[0].text)[:class]}"
          end
        end
      end
    end

    def classify_equity
      ec = EquityClassifier.new

      @cse = [nil, 0.0, 0.0]
      @equity.each do |e|
        if e.length < 3
          @log.warn("asset must be 3 columns wide #{e}")
        else
          case ec.classify(e[0].text)[:class]
          when :pse
            #puts "pse: #{e[0].text}"
            @financial_liabs.push(e)
            @total_fl[1] += e[1].val if !e[1].val.nil?
            @total_fl[2] += e[2].val if !e[2].val.nil?
            @nfa[1] -= e[1].val if !e[1].val.nil?
            @nfa[2] -= e[2].val if !e[2].val.nil?
          when :cse
            #puts "cse: #{e[0].text}"
            @common_equity.push(e)
            @cse[1] += e[1].val if !e[1].val.nil?
            @cse[2] += e[2].val if !e[2].val.nil?
          else
            raise "Unknown class #{ec.classify(e[0].text)[:class]}"
          end
        end
      end
    end

  end
  
end
