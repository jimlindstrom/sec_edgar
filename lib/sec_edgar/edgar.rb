module SecEdgar

  class Edgar
    
    def initialize
    end
  
    # Takes in something like "January 2, 2008" and returns 2008_01_02
    def parse_date_string(date_str)
  
      # parse the input string
      date_str.match(/([A-Za-z]+) ([0-9]+), ([0-9]+)/)
      $mon  = $1
      $day  = $2
      $year = $3
  
      # convert the month name to a number
      $months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
      $mon  = String($months.index{|x| x==$mon} + 1)
  
      # zero-pad the day and month to 2 digits
      if $mon.length < 2
        $mon = "0" + $mon
      end
      if $day.length < 2
        $day = "0" + $day
      end
  
      # construct return string
      $ret_str = $year + "_" + $mon + "_" + $day
      return $ret_str
    end
  
    def get_report_urls(ticker, rept_type_search)
      # set up
      agent = Mechanize.new { |a| a.log = Logger.new('mech.log') }
      agent.user_agent_alias = 'Windows IE 7'
      agent.redirection_limit= 5
      
      # first search for the company in question
      page  = agent.get('http://www.sec.gov/edgar/searchedgar/companysearch.html')
      form  = page.forms.first
      form['CIK'] = ticker
      page = form.submit
      
      # Now search for reports
      form  = page.forms.first
      form['type'] = rept_type_search
      page = form.submit
      
      # Now find the links to the reports 
      report_urls = []
      page.links.each do |link|
        if link.text == ' Documents'
          report_urls.push link.href
        end
      end
      
      return report_urls
    end
      
    def get_reports(report_urls, rept_type_linktext, save_folder)
      # for each report index
      report_urls.each do |url|
        page = agent.get('http://www.sec.gov' + url)
        page.links.each do |link|
          if link.text == rept_type_linktext
            subpage = agent.get('http://www.sec.gov' + link.href)
      
            /period ended ([^<]*) </.match(subpage.body)
            $report_date = $1.gsub(/&nbsp;/," ")
            $report_date = parse_date_string($report_date)
  
            if ($report_date.length > 5) and ($report_date.length < 50) # overly validation
              # save the file to a report
              output = File.open(save_folder + $report_date + ".html", "w") { |file|  file << subpage.body }
            end
          end
        end
      end
    end
      
    def get_10q_reports(ticker, save_folder)
      report_urls = get_reports_urls(ticker, '10-q')
      get_reports(report_urls, 'd10q.htm', save_folder)
    end
  
    def get_10k_reports(ticker, save_folder)
      report_urls = get_reports_urls(ticker, '10-k')
      get_reports(report_urls, 'd10k.htm', save_folder)
    end
  
    def get_fin_stmts(ticker, save_folder)
      get_10q_reports(ticker, save_folder)
      get_10k_reports(ticker, save_folder)
    end
  end
  
end
