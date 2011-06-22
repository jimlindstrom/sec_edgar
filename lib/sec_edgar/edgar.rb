class String
    def remove_non_ascii(replacement="")
        self.gsub(/[\u0080-\u00ff]/,replacement)
    end
end

module SecEdgar

  class Edgar
    AGENT_ALIAS = 'Windows IE 7'

    attr_accessor :log
    
    def initialize
    end
      
    def good_ticker?(ticker)
      # first search for the company in question
      agent = create_agent
      page  = agent.get('http://www.sec.gov/edgar/searchedgar/companysearch.html')
      form  = page.forms.first
      form['CIK'] = ticker
      page = form.submit
      
      # Now search for reports
      form  = page.forms.first

      return !form.nil?
    end
   
    def get_reports_urls(ticker, rept_type_search)
      @log.info("Getting report URLS of type #{rept_type_search} for #{ticker}") if @log
      return nil if !good_ticker?(ticker)
      return nil if !['10-q','10-k'].include?(rept_type_search)

      # first search for the company in question
      agent = create_agent
      page  = agent.get('http://www.sec.gov/edgar/searchedgar/companysearch.html')
      form  = page.forms.first
      form['CIK'] = ticker
      page = form.submit
      
      # Now search for reports
      form  = page.forms.first

      return nil if form.nil?

      form['type'] = rept_type_search
      page = form.submit
      
      # Now find the links to the reports 
      report_urls = []
      page.links.each do |link|
        if link.text.remove_non_ascii == "Documents"
          report_urls.push link.href
        end
      end
      
      return report_urls
    end
 
    # returns list of files downloaded
    # returns nil if bad ticker
    def download_10q_reports(ticker, save_folder)
      @log.info("Downloading 10q reports for #{ticker}") if @log
      return nil if not good_ticker?(ticker)

      report_urls = get_reports_urls(ticker, '10-q')
      return nil if report_urls.nil?

      report_files = get_reports(report_urls, 'd10q.htm', save_folder)
      return report_files
    end
 
    # returns list of files downloaded
    # returns nil if bad ticker
    def download_10k_reports(ticker, save_folder)
      @log.info("Downloading 10k reports for #{ticker}") if @log
      return nil if not good_ticker?(ticker)

      report_urls = get_reports_urls(ticker, '10-k')
      return nil if report_urls.nil?

      report_files = get_reports(report_urls, 'd10k.htm', save_folder)
      return report_files
    end

    def get_10q_reports(ticker, save_folder)
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

    def get_10k_reports(ticker, save_folder)
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
   
    # returns list of files downloaded
    # returns nil if bad ticker
    def get_fin_stmts(ticker, save_folder)
      return nil if not good_ticker?(ticker)

      files_10q = get_10q_reports(ticker, save_folder)
      return nil if files_10q.nil?

      files_10k = get_10k_reports(ticker, save_folder)
      return nil if files_10k.nil?

      return files_10q + files_10k
    end

  private
  
    # Takes in something like "January 2, 2008" and returns 2008_01_02
    def parse_date_string(date_str)

      if date_str =~ /([0-9]+)\/([0-9]+)\/([0-9]+)/
        $mon  = $1
        $day  = $2
        $year = $3

        # construct return string
        $ret_str = $year + "_" + $mon + "_" + $day
      elsif date_str.match(/([A-Za-z]+) ([0-9]+), ([0-9]+)/)
        $mon  = $1
        $day  = $2
        $year = $3
    
        # convert the month name to a number
        $months = ["january","february","march","april","may","june","july","august","september","october","november","december"]
        $mon  = String($months.index{|x| x==$mon.downcase} + 1)
    
        # zero-pad the day and month to 2 digits
        if $mon.length < 2
          $mon = "0" + $mon
        end
        if $day.length < 2
          $day = "0" + $day
        end
    
        # construct return string
        $ret_str = $year + "_" + $mon + "_" + $day
      else
        raise "Unrecognizable date string: #{date_str}"
      end

      return $ret_str
    end
     
    def get_reports(report_urls, rept_type_linktext, save_folder)
      @log.info("Getting reports") if @log
      files = []

      # for each report index
      agent = create_agent
      report_urls.each do |url|
        page = agent.get('http://www.sec.gov' + url)
        page.links.each do |link|
          if link.text == rept_type_linktext
            subpage = agent.get('http://www.sec.gov' + link.href)
      
            if subpage.body.downcase =~ /period[ &nbsp;]ended[ ^nbsp;]([^<]*)[ ^nbsp;]*</
              $report_date = $1.gsub(/&nbsp;/," ")
              $report_date = parse_date_string($report_date)
            else
              fh = File.open("/tmp/jbl.txt","w")
              fh.puts(subpage.body.downcase)
              fh.close
              raise "Could't match report, url=#{link.href}"
            end
  
            if ($report_date.length > 5) and ($report_date.length < 50) # overly validation
              # save the file to a report
              cur_filename = save_folder + $report_date + ".html"
              files.push cur_filename
              output = File.open(save_folder + $report_date + ".html", "w") { |file|  file << subpage.body }
            end
          end
        end
      end

      return files
    end

    def create_agent
      #agent = Mechanize.new { |a| a.log = Logger.new('mech.log') }
      agent = Mechanize.new 
      agent.user_agent_alias = AGENT_ALIAS
      agent.redirection_limit= 5
      return agent
    end


  end
  
end
