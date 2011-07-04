module SecEdgar

  class Edgar
    AGENT_ALIAS = 'Windows IE 7'

    attr_accessor :log
    
    def initialize
      @agent = nil
      @page_cache = PageCache.new
      @index_cache = IndexCache.new
      @summary_cache = SummaryCache.new
    end

    ############################################################################
    # Basic info
    ############################################################################
     
    def good_ticker?(ticker)
      # first search for the company in question
      agent = create_agent
      page  = agent.get('http://www.sec.gov/edgar/searchedgar/companysearch.html')
      form  = page.forms.first
      form['CIK'] = ticker
      page = form.submit
      
      # if there's a form, it's a good ticker
      form  = page.forms.first

      return !form.nil?
    end
     
    ############################################################################
    # Download all 10-K's, merge into FinancialStatementSummary and return it
    ############################################################################

    def get_summary_of_10ks(ticker) 
      # check whether the summary for this ticker has already retrieved, in the cache
      if @summary_cache.exists?(ticker)
        return @summary_cache.lookup(ticker)
      end

      # reports for this ticker wasn't in the cache, so retrieve them
      summary = get_summary_of_10ks_from_scratch(ticker)

      # insert this set of reports into the cache
      if !summary.nil?
        @summary_cache.insert(ticker, summary)
      end

      return summary
    end

    def get_summary_of_10ks_from_scratch(ticker) 
      rept_type = '10-K'
      download_path = "/tmp/"
      
      reports = lookup_reports(ticker)
      raise ParseError, "couldn't lookup reports for #{ticker}" if reports==[] or reports.nil?
      reports.keep_if{ |r| r[:type] == rept_type }
      reports.sort! {|a,b| a[:date] <=> b[:date] }
      raise ParseError, "No 10-K's found for #{ticker}" if reports==[] or reports.nil?
      
      files = get_reports(reports, download_path)
      raise ParseError, "couldn't get reports for #{ticker}" if files==[] or files.nil?
      
      summary = nil
      while summary == nil
        if files.empty?
          raise ParseError, "ERROR: ran out of files to parse..."
        end
        ten_k = AnnualReport.new 
        ten_k.log = Logger.new('sec_edgar.log')
        ten_k.log.level = Logger::DEBUG
        begin
          cur_file = files.shift
          ten_k.parse(cur_file)
          summary = ten_k.get_summary
          ten_k = nil
        rescue ParseError => e
          puts "WARNING: #{cur_file}: #{ e } (#{ e.class })!"
        end
      end
      
      while !files.empty?
        ten_k2 = AnnualReport.new 
        ten_k2.log = Logger.new('sec_edgar.log')
        ten_k2.log.level = Logger::DEBUG
        begin
          cur_file = files.shift
          ten_k2.parse(cur_file)
          summary2 = ten_k2.get_summary
        rescue ParseError => e
          puts "WARNING: #{cur_file}: #{ e } (#{ e.class })!"
        end
      
        summary.merge(summary2) if !summary2.nil?
      end

      return summary
    end
   
    ############################################################################
    # get_* retrieve the 10q's or 10k's, parse them, and return an array of 
    # AnnualReport's or QuarterlyReport's
    ############################################################################

    def get_10q_reports(ticker, save_folder) # FIXME: get rid of 'save_folder' and just use /tmp'
      reports = []

      @log.info("Getting 10q reports for #{ticker}") if @log
      files = download_10q_reports(ticker, save_folder)
      return nil if files.nil?
      files.each do |cur_file|
        cur_ten_q = QuarterlyReport.new { |q| q.log = @log }
        cur_ten_q.parse(cur_file)

        reports.push cur_ten_q
      end
      return reports
    end

    def get_10k_reports(ticker, save_folder) # FIXME: get rid of 'save_folder' and just use /tmp'
      reports = []

      @log.info("Getting 10k reports for #{ticker}") if @log
      files = download_10k_reports(ticker, save_folder)
      return nil if files.nil?
      files.each do |cur_file|
        cur_ten_k = AnnualReport.new { |a| a.log = @log }
        cur_ten_k.parse(cur_file)

        reports.push cur_ten_k
      end
      return reports
    end
 
    ############################################################################
    # download_* retrieve the 10q's or 10k's and save them into a folder
    ############################################################################

    # returns list of files downloaded
    # returns nil if bad ticker
    def download_10q_reports(ticker, save_folder) # FIXME: should be private?
      @log.info("Downloading 10q reports for #{ticker}") if @log
      return nil if not good_ticker?(ticker)

      reports = lookup_reports(ticker)
      return nil if reports.nil?
      reports.keep_if { |r| r[:type]=='10-Q' }

      report_files = get_reports(reports, save_folder)
      return report_files
    end
 
    # returns list of files downloaded
    # returns nil if bad ticker
    def download_10k_reports(ticker, save_folder) # FIXME: should be private?
      @log.info("Downloading 10k reports for #{ticker}") if @log
      if !good_ticker?(ticker)
        @log.error("#{ticker} is not a good ticker") if @log
        return nil
      end

      reports = lookup_reports(ticker)
      return nil if reports.nil?
      reports.keep_if { |r| r[:type]=='10-K' }

      report_files = get_reports(reports, save_folder)
      return report_files
    end
     
    ############################################################################
    # these look up the company's reports and return an array of hashes that
    # describe each report's date, type, and URL.
    ############################################################################

    def lookup_reports(ticker)
      # check whether the reports for this ticker has already retrieved, in the cache
      if @index_cache.exists?(ticker)
        return @index_cache.lookup(ticker)
      end

      # reports for this ticker wasn't in the cache, so retrieve them
      reports = lookup_reports_from_scratch(ticker)

      # insert this set of reports into the cache
      if !reports.nil?
        @index_cache.insert(ticker, reports)
      end

      return reports
    end

    def lookup_reports_from_scratch(ticker) # FIXME: should be private?
      @log.info("Looking up reports for #{ticker}") if @log
      if !good_ticker?(ticker)
        @log.error("#{ticker} is not a good ticker") if @log
        return nil
      end

      # first search for the company in question
      agent = create_agent
      page  = agent.get('http://www.sec.gov/edgar/searchedgar/companysearch.html')
      form  = page.forms.first
      form['CIK'] = ticker
      page = form.submit
      return nil if page.nil?

      reports = [ ]

      while !page.nil?
        doc = Hpricot(page.body)
        trs = doc.search("table[@summary='Results']/tr")
        trs.shift # ignore the header row
        trs.each do |tr_item|
          tds = tr_item.search("td")
  
          reports.push( { :type => tds[0].innerHTML,
                          :url  => tds[1].children.first.attributes['href'],
                          :date => tds[3].innerHTML } )
        end
  
        buttons = doc.search("input[@value='Next 40']")
        if buttons.length > 0
          button = buttons.first
          next_url = button.attributes['onclick'].gsub(/^[^']*'/,'').gsub(/'$/,'')
          page = agent.get('http://www.sec.gov' + next_url)
        else
          page = nil
        end
      end

      return reports
    end
     
    def get_reports(reports, save_folder) # FIXME: should be private?
      @log.info("Getting reports") if @log
      files = []

      rept_type_linktext =
        { "10-Q" => "d10q.htm",
          "10-K" => "d10k.htm" }

      # for each report index
      reports.each do |report|
        raise TypeError, "unsupported report type #{report[:type]}" if !rept_type_linktext.keys.include?(report[:type])

        cur_file = get_single_report(report, save_folder)
        files.push cur_file if !cur_file.nil?
      end
  
      return files
    end

  private

    def get_single_report(report, save_folder)

      # check whether the page is already retrieved, in the cache
      if @page_cache.exists?(report[:url])
        return @page_cache.key_to_cache_filename(report[:url])
      end

      # page wasn't in the cache, so retrieve it
      cur_filename = get_single_report_from_scratch(report, save_folder)

      # insert the page into the cache
      if !cur_filename.nil?
        fh = File.open(cur_filename, "r") 
        @page_cache.insert(report[:url], fh.read)
        fh.close
      end

      return cur_filename

    end

    def get_single_report_from_scratch(report, save_folder)

      agent = create_agent
      page = agent.get('http://www.sec.gov' + report[:url])
      doc = Hpricot(page.body)

      trs = doc.search("table[@class='tableFile']/tr")
      trs.each do |tr_item|

        tds = tr_item.search("td")
        if !tds[3].nil? and tds[3].innerHTML == report[:type]
          subpage_url ='http://www.sec.gov' + tds[2].children.first.attributes['href']
          if subpage_url =~ /htm$/
            subpage = agent.get(subpage_url)
  
            cur_filename = save_folder + report[:date] + ".html"
  
            fh = File.open(cur_filename, "w") 
            fh << subpage.body
            fh.close

            return cur_filename
          end
        end

      end

      return nil
    end
       
    def create_agent
      return @agent if not @agent.nil?

      @agent = Mechanize.new # { |a| a.log = Logger.new('mech.log') }
      @agent.user_agent_alias = AGENT_ALIAS
      @agent.redirection_limit= 5
      return @agent
    end

  end
  
end
