require 'content_urls/version'
require 'uri'

# +ContentUrls+ parses various file types (HTML, CSS, JavaScript, ...) for URLs and provides methods for iterating through URLs and changing URLs.
#
class ContentUrls

  # Returns the URLs found in the content.
  #
  # @param [String] content the content.
  # @param [String] type the media type of the content.
  # @param [Hash] opts the options for manipulating returned URLs
  # @option opts [String] :use_base_url (false) if base URL is found in content, this option indicates whether base URL will be used to change each relative URL to an absolute URL (note: base URL ignored if determined to be relative)
  # @option opts [String] :content_url the URL from which content was retrieved; will be used to change each relative URL to an absolute URL (note: :use_base_url option takes precedence over :content_url option; content URL will ignored if determined to be relative)
  # @return [Array] the unique URLs found in the content.
  #
  # @example Parse HTML code for URLs
  #   content = '<html><a href="index.html">Home</a></html>'
  #   ContentUrls.urls(content, 'text/html').each do |url|
  #     puts "Found URL: #{url}"
  #   end
  #   # => "Found URL: index.html"
  #
  # @example Parse HTML code for URLs, changing each to an absolute URL based on the address of the the original resource
  #   content = '<html><a href="index.html">Home</a></html>'
  #   ContentUrls.urls(content, 'text/html', content_url: 'http://www.example.com/sample.html').each do |url|
  #     puts "Found URL: #{url}"
  #   end
  #   # => "Found URL: http://www.example.com/index.html"
  #
  #  # @example Parse content obtained from a robot
  #   response = Net::HTTP.get_response(URI('http://example.com/sample-1'))
  #   puts "URLs found at http://example.com/sample-1:"
  #   ContentUrls.urls(response.body, response.content_type).each do |url|
  #     puts "  #{url}"
  #   end
  #   # => [a list of URLs found in the content located at http://example.com/sample-1]
  #
  def self.urls(content, type, options = {})
    options = {
        :use_base_url => false,
        :content_url => nil,
    }.merge(options)
    urls = []
    if (parser = get_parser(type))
      base = base_url(content, type) if options[:use_base_url]
      base = '' if URI(base || '').relative?
      if options[:content_url]
        content_url = URI(options[:content_url]) rescue ''
        content_url = '' if URI(content_url).relative?
        base = URI.join(content_url, base)
      end
      if URI(base).relative?
        parser.urls(content).each { |url| urls << url }
      else
        parser.urls(content).each { |url| urls << URI.join( base, url).to_s }
      end
    end
    urls
  end

  # Returns base URL found in the content, if available.
  #
  # @param [String] content the content.
  # @param [String] type the media type of the content.
  # @return [String] the base URL found in the content.
  #
  # @example Parse HTML code for base URL
  #   content = '<html><head><base href="/home/">'
  #   puts "Found base URL: #{ContentUrls.base_url(content, 'text/html')}"
  #   # => "Found base URL: /home/"
  #
  def self.base_url(content, type)
    base = nil
    if (parser = get_parser(type))
      if (parser.respond_to?(:base))
        base = parser.base(content)
      end
    end
    base
  end

  # Rewrites each URL in the content by calling the supplied block with each URL.
  #
  # @param [String] content the HTML content.
  # @param [String] type the media type of the content.
  # @returns [string] content the rewritten content.
  #
  # @example Rewrite URLs in HTML code
  #   content = '<html><a href="index.htm">Home</a></html>'
  #   content = ContentUrls.rewrite_each_url(content, 'text/html') {|url| 'gone.html'}
  #   puts "Rewritten: #{content}"
  #   # => "Rewritten: <html><a href="gone.html">Home</a></html>"
  #
  def self.rewrite_each_url(content, type, &block)
    if (parser = get_parser(type))
      content = parser.rewrite_each_url(content) do |url|
        replacement = yield url
        (replacement.nil? ? url : replacement)
      end
    end
    content
  end

  # Convert a relative URL to an absolute URL using base_url (for example, the content's original location or an HTML document's href attribute of the base tag).
  #
  # @example Obtain absolute URL of "../index.html" of page obtained from "http://example.com/one/two/sample.html"
  #   puts ContentUrls.to_absolute("../index.html", "http://example.com/folder/sample.html")
  #   # => "http://example.com/index.html"
  #
  def self.to_absolute(url, base_url)
    return nil if url.nil?

    url = URI.encode(URI.decode(url.to_s.gsub(/#[a-zA-Z0-9\s_-]*$/,'')))  # remove anchor
    absolute = URI(base_url).merge(url)
    absolute.path = '/' if absolute.path.empty?
    absolute.to_s
  end

  protected

  @@type_parser = Hash.new { |hash, key| hash[key] = [] }  # mapping of type regex to parser class

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

  # Parser implementations
  # - each implementation's urls method should return unique URLs

  require 'content_urls/parsers/html_parser'
  register_parser ContentUrls::HtmlParser, %r{^(text/html)\b}, %r{^(application/xhtml+xml)\b}

  require 'content_urls/parsers/css_parser'
  register_parser ContentUrls::CssParser, %r{^(text/css)\b}
  register_parser ContentUrls::StyleParser, %r{^(html-inline-style)\b}

  require 'content_urls/parsers/java_script_parser'
  register_parser ContentUrls::JavaScriptParser, %r{^(application/x-javascript)\b}, %r{^(application/javascript)\b}, %r{^(text/javascript)\b}

end
