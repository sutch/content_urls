require 'content_urls/version'
require 'uri'

class ContentUrls

  @@type_parser = Hash.new { |hash, key| hash[key] = [] }  # mapping of type regex to parser class

  def self.each(content, type, base_url)
    urls = []
    if (parser = get_parser(type))
      parser.new(content).each do |u|
        abs = to_absolute(URI(u), base_url) rescue next
        urls << abs
      end
      urls.uniq!
    end
    urls
  end

  def self.rewrite_each(content, type, base_url, &block)
    if (parser = get_parser(type))
      parser.rewrite_each(body, base_url) do |u|
        abs = to_absolute(URI(u), base_url) rescue next
        replacement = yield abs
        (replacement.nil? ? u : replacement)
      end
    end
  end

  # Register a parser implementation class for one or more content type regular expressions
  def self.register_parser(parser_class, *type_regexes)
    type_regexes.each do |regex|
      @@type_parser[regex].push parser_class
    end
  end

  # Return parser for a file type or nil if content type not recognized
  def self.get_parser(type)
    @@type_parser.each_pair do |regex, parser|
      if type =~ regex
        return parser.first
      end
    end
    return nil
  end

  # Convert relative URL to an absolute URL based on the content's location (base_url)
  def self.to_absolute(url, base_url)
    return nil if url.nil?

    url = URI.encode(URI.decode(url.to_s.gsub(/#[a-zA-Z0-9_-]*$/,'')))  # remove anchor
    absolute = URI(base_url).merge(url)
    absolute.path = '/' if absolute.path.empty?
    absolute.to_s
  end

end
