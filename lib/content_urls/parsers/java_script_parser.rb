require 'uri'
require 'rkelly'

class ContentUrls

  # +JavaScriptParser+ finds and rewrites URLs in JavaScript content.
  #
  # === Implementation note:
  # This methods in this class identify URLs by locating strings which match +URI+'s regexp.
  class JavaScriptParser

    # Returns the URLs found in the JavaScript content.
    #
    # @param [String] content the JavaScript content.
    # @return [Array] the unique URLs found in the content.
    #
    # @example Parse JavaScript code for URLs
    #   javascript = 'var link="http://example.com/"'
    #   ContentUrls::JavaScriptParser.urls(javascript).each do |url|
    #     puts "Found URL: #{url}"
    #   end
    #   # => "Found URL: http://example.com/"
    def self.urls(content)
      urls = []
      return urls if content.nil? || content.length == 0
      rewrite_each_url(content) { |url| urls << url; url }
      urls.uniq!
      urls
    end

    # Rewrites each URL in the JavaScript content by calling the supplied block with each URL.
    #
    # @param [String] content the JavaScript content.
    #
    # @example Rewrite URLs in JavaScript code
    #   javascript = 'var link="http://example.com/"'
    #   javascript = ContentUrls::JavaScriptParser.rewrite_each_url(javascript) {|url| url.upcase}
    #   puts "Rewritten: #{javascript}"
    #   # => "Rewritten: var link="HTTP://EXAMPLE.COM/""
    #
    def self.rewrite_each_url(content, &block)
      rewritten_content = content.dup
      rewrite_urls = {}
      parser = RKelly::Parser.new
      ast = parser.parse(content)
      return content if ast.nil?
      ast.each do |node|
        if node.kind_of? RKelly::Nodes::StringNode
          value = node.value
          if match = /^'(.*)'$/.match(value)
            value = match[1]  # remove single quotes
          end
          if match = URI.regexp.match(value)
            url = match.to_s
            rewritten_url = yield url
            rewrite_urls[url] = rewritten_url if url != rewritten_url
          end
        end
      end
      if rewrite_urls.count > 0
        rewrite_urls.each do |url, rewritten_url|
          rewritten_content[url] = rewritten_url.to_s
        end
      end
      rewritten_content
    end

  end
end
