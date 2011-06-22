module SecEdgar
  class EquityClassifier
    def initialize(do_training=true)
      @a = NaiveBayes.new(:cse, :pse)
      @s = Lingua::Stemmer.new
  
      if do_training
        # FIXME: this needs rewritten so that it doesn't rely on an external file.  Turn it into an eval'able file?
        retrain
      end
    end
  
    def classify(str)
      tokens = tokenize(str)
      ret = @a.classify(*tokens)
      return {:class=>ret[0], :confidence=>ret[1]}
    end
  
  private
  
    def retrain
      fh = File.new("classifier_training/equity_training_scored.txt", "r")
      fh.readlines.each do |cur_line|
      
        cur_tokens = cur_line.split(' ')
        cur_class = cur_tokens.shift
        cur_tokens.collect! { |x| @s.stem(x) }
      
        case cur_class
        when "PSE"
          @a.train(:pse, *cur_tokens)
        when "CSE"
          @a.train(:cse, *cur_tokens)
        else
          raise "unknown class #{cur_class}"
        end
      end
  
      fh.close
    end
  
    def tokenize(str)
      str.split(' ').collect { |x| @s.stem(x) }
    end
  
  end
  
  #ac = EquityClassifier.new
  #
  #["property, plant and equipment",
  # "accounts receivable",
  # "prepaid revenue",
  # "cash and cash equivalents",
  # "income tax payable"].each do |cur_str|
  #
  #  classification = ac.classify(cur_str)
  #  puts "#{cur_str} => [#{classification[:class]}, #{classification[:confidence]}]"
  #
  #end
end

