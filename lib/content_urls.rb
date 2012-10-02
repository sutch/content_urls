require 'content_urls/version'
require 'uri'

class ContentUrls

  @@type_parser = Hash.new { |hash, key| hash[key] = [] }  # mapping of type regex to parser class

  def self.urls(content, type)
    urls = []
    if (parser = get_parser(type))
      parser.new(content).urls.each { |url| urls << url }
    end
    urls
  end

  def self.rewrite_each_url(content, type, &block)
    if (parser = get_parser(type))
      parser.rewrite_each_url(content) do |url|
        replacement = yield url
        (replacement.nil? ? url : replacement)
      end
    end
    content
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

  # Parser implementations
  # - each implementation's urls method should return unique URLs

  require 'content_urls/parsers/html_parser'
  register_parser ContentUrls::HtmlParser, %r{^(text/html)\b}, %r{^(application/xhtml+xml)\b}

  require 'content_urls/parsers/css_parser'
  register_parser ContentUrls::CssParser, %r{^(text/css)\b}

  require 'content_urls/parsers/java_script_parser'
  register_parser ContentUrls::JavaScriptParser, %r{^(application/x-javascript)\b}, %r{^(application/javascript)\b}, %r{^(text/javascript)\b}

end
