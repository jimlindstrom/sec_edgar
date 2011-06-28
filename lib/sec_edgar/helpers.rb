module SecEdgar

  module Helpers

    def Helpers.get_all_10ks(ticker)
      rept_type = '10-K'
      download_path = "/tmp/"
      edgar = SecEdgar::Edgar.new
      
      reports = edgar.lookup_reports(ticker)
      raise SecEdgar::ParseError, "couldn't lookup reports for #{ticker}" if reports==[] or reports.nil?
      reports.keep_if{ |r| r[:type] == rept_type }
      reports.sort! {|a,b| a[:date] <=> b[:date] }
      raise SecEdgar::ParseError, "No 10-K's found for #{ticker}" if reports==[] or reports.nil?
      
      files = edgar.get_reports(reports, download_path)
      raise SecEdgar::ParseError, "couldn't get reports for #{ticker}" if files==[] or files.nil?
      
      summary = nil
      while summary == nil
        if files.empty?
          raise SecEdgar::ParseError, "ERROR: ran out of files to parse..."
        end
        ten_k = SecEdgar::AnnualReport.new 
        ten_k.log = Logger.new('sec_edgar.log')
        ten_k.log.level = Logger::DEBUG
        begin
          cur_file = files.shift
          ten_k.parse(cur_file)
          summary = ten_k.get_summary
          ten_k = nil
        rescue SecEdgar::ParseError => e
          puts "WARNING: #{cur_file}: #{ e } (#{ e.class })!"
        end
      end
      
      while !files.empty?
        ten_k2 = SecEdgar::AnnualReport.new 
        ten_k2.log = Logger.new('sec_edgar.log')
        ten_k2.log.level = Logger::DEBUG
        begin
          cur_file = files.shift
          ten_k2.parse(cur_file)
          summary2 = ten_k2.get_summary
        rescue SecEdgar::ParseError => e
          puts "WARNING: #{cur_file}: #{ e } (#{ e.class })!"
        end
      
        summary.merge(summary2)
      end

      return summary
    end

    def Helpers.get_actual_market_cap(ticker)
      ext_quotes = YahooFinance::get_quotes(YahooFinance::ExtendedQuote, ticker)
    
      mkt_cap = Float(ext_quotes[ticker].marketCap.gsub(/[A-Za-z]/,''))
      case ext_quotes[ticker].marketCap.split('').last.upcase # last character indicates billions, millions, etc...
      when 'B'
        mkt_cap = mkt_cap * 1000.0 * 1000.0 * 1000.0
      when 'M'
        mkt_cap = mkt_cap * 1000.0 * 1000.0
      when 'K'
        mkt_cap = mkt_cap * 1000.0 
      else
        raise SecEdgar::ParseError, "unknown modifier"
      end
    
      return mkt_cap 
    end

    def Helpers.get_actual_share_price(ticker)
      std_quotes = YahooFinance::get_quotes(YahooFinance::StandardQuote, ticker)
      return Float(std_quotes[ticker].lastTrade)
    end

    def Helpers.get_shares_outstanding(ticker)
      mkt_cap     = Helpers.get_actual_market_cap(ticker)
      share_price = Helpers.get_actual_share_price(ticker)
    
      return mkt_cap / share_price
    end
    
    RISK_FREE_RATE               = 0.04 # feel free to use this for calculating equity cost-of-capital
    EXPECTED_RETURN_FOR_EQUITIES = 0.09 # feel free to use this for calculating equity cost-of-capital

    def Helpers.equity_cost_of_capital__capm(risk_free_rate, expected_return_for_equities, beta)
      return risk_free_rate + (beta * (expected_return_for_equities - risk_free_rate))
    end

    def Helpers.weighted_avg_cost_of_capital(ticker, summary, rho_e, rho_d, tax_rate)
      v_e = Helpers.get_actual_market_cap(ticker)
      v_d = summary.nfa.last * 1000.0
      v_f = v_e + v_d

      rho_f = ((v_e / v_f) * rho_e) + ((v_d / v_f) * rho_d)
      return rho_f
    end

  end
end
