require 'uri'

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
      URI.extract(content).each { |u| urls << u }
      urls.uniq!
      urls
    end

    # Rewrites each URL in the JavaScript content by calling the supplied block with each URL.
    #
    # @param [String] content the JavaScript content.
    #
    # @example Rewrite URLs in JavaScript code
    #   javascript = 'var link="http://example.com/"'
    #   javascript = ContentUrls::JavaScriptParser.rewrite_urls(javascript).each {|url| url.upcase}
    #   # => "Rewritten: var link="HTTP://EXAMPLE.COM/""
    #
    def self.rewrite_each(content, &block)
      done = false
      remaining = content
      rewritten = ''
      while ! done
        if match = URI.regexp.match(remaining)
          url = match.to_s
          rewritten += match.pre_match
          replacement = url.nil? ? nil : (yield url)
          if replacement.nil? or replacement == url  # no change in URL
            rewritten += url[0]
            remaining = url[1..-1] + match.post_match
          else
            rewritten += replacement
            remaining = match.post_match
          end
        else
          rewritten += remaining
          remaining = ''
          done = true
        end
      end
      return rewritten
    end

  end
end
