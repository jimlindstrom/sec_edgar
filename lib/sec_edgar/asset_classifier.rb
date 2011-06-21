
class AssetClassifier
  def initialize(do_training=true)
    @a = NaiveBayes.new(:oa, :fa)
    @s = Lingua::Stemmer.new

    if do_training
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
    fh = File.new("classifier_training/assets_training_scored.txt", "r")
    fh.readlines.each do |cur_line|
    
      puts "cur_line: #{cur_line}"
      cur_tokens = cur_line.split(' ')
      cur_class = cur_tokens.shift
      cur_tokens.collect! { |x| @s.stem(x) }
    
      case cur_class
      when "FA"
        @a.train(:fa, *cur_tokens)
      when "OA"
        @a.train(:oa, *cur_tokens)
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

#ac = AssetClassifier.new
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

