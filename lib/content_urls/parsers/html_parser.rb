require 'nokogiri'

class ContentUrls

  # +HtmlParser+ finds and rewrites URLs in HTML content.
  #
  # === Implementation note:
  # This methods in this class use Nokogiri to identify URLs.  Nokogiri cleans HTML code when rewriting, so expect some changes to rewritten content.
  class HtmlParser

    # Returns the URLs found in the HTML content.
    #
    # @param [String] content the HTML content.
    # @return [Array] the unique URLs found in the content.
    #
    # @example Parse HTML code for URLs
    #   html = '<html><a href="index.htm">Click me</a></html>'
    #   ContentUrls::HtmlParser.urls(html).each do |url|
    #     puts "Found URL: #{url}"
    #   end
    #   # => "Found URL: index.htm"
    #
    def self.urls(content)
      doc = Nokogiri::HTML(content) if content rescue nil
      urls = []
      return urls if !doc

      rewrite_each_url(content) { |url| urls << url; url }
      urls.uniq!
      urls
    end

    # Rewrites each URL in the HTML content by calling the supplied block with each URL.
    #
    # @param [String] content the HTML content.
    #
    # @example Rewrite URLs in HTML code
    #   html = '<html><a href="index.htm">Click me</a></html>'
    #   html = ContentUrls::HtmlParser.rewrite_each_url(html) {|url| 'index.php'}
    #   puts "Rewritten: #{html}"
    #   # => "Rewritten: <html><a href="index.php">Click me</a></html>"
    #
    def self.rewrite_each_url(content, &block)
      doc = Nokogiri::HTML(content) if content rescue nil
      return nil if !doc

      # TODO: handle href attribute of base tag
      #  - should href URL be changed?
      #  - should relative URLs be modified using base?
      #  - how should rewritten relative URLs be handled?
      base = doc.search('//head/base/@href')  # base URI for resolving relative URIs
      base = nil if base && base.to_s.strip.empty?

      @@parser_definition.each do |type, definition|
        doc.search(definition[:xpath]).each do |obj|
          if definition.has_key?(:attribute)  # use tag attribute if provided
            value = obj[definition[:attribute]]
          else  # otherwise use tag's content
            value = obj.to_s
          end
          next if value.nil? or value.strip.empty?

          if definition.has_key?(:parser)  # parse value using parser
            ContentUrls.rewrite_each_url(value, definition[:parser]) { |url| yield url }

          elsif definition.has_key?(:attribute)  # rewrite the URL within the attribute

            if definition.has_key?(:url_regex)  # use regex to obtain URL
              if (match = definition[:url_regex].match(value))
                url = yield match[:url]
                next if url.nil? or url.to_s == match.to_s  # don't change URL
                obj[definition[:attribute]] = match.pre_match + url.to_s + match.post_match
              end

            else  # value is the URL
              next if value =~ /^#/  # do not capture anchors within the content being parsed
              url = yield value
              next if url.nil? or url.to_s == match.to_s  # don't change URL
              #obj[definition[:attribute]] = url.to_s
              obj.set_attribute(definition[:attribute], url.to_s)
            end
          else
            $stderr.puts "WARNING: unable to rewrite URL for #{value.to_s}"
          end
        end
      end
      return doc.to_s
    end  # rewrite_each

    protected

    @@parser_definition = {
      a_href: {
        xpath: "//a[@href]",
        attribute: 'href'
      },
      area_href: {
        xpath: "//area[@href]",
        attribute: 'href'
      },
      body_background: {
        xpath: "//body[@background]",
        attribute: 'background'
      },
      embed_src: {
        xpath: "//embed[@src]",
        attribute: 'src'
      },
      frame_src: {
        xpath: "//frame[@src]",
        attribute: 'src'
      },
      iframe_src: {
        xpath: "//iframe[@src]",
        attribute: 'src'
      },
      img_src: {
        xpath: "//img[@src]",
        attribute: 'src'
      },
      link_href: {
        xpath: "//link[@href]",
        attribute: 'href'
      },
      meta_content: {
        xpath: "//meta[((@http-equiv='location') or (@http-equiv='refresh'))
          and @content and contains(@content,';')
          and number(substring-before(@content,';'))=substring-before(@content,';')]",
        attribute: 'content',
        url_regex: %r{^\d+\s*;\s*url\s*=\s*(?<quote>['"]?)(?<url>[^'"]+)\k<quote>$}i  # must return named capture of :url containing URL
      },
      object_data: {
        xpath: "//object[@data]",
        attribute: 'data'
      },
      script_src: {
        xpath: "//script[@src]",
        attribute: 'src'
      },
      style_attribute: {
        xpath: "//*[@style]",
        attribute: 'style',
        parser: 'text/css'
      },
      style_tag: {
        xpath: "//style",
        parser: 'text/css'
      },
      javascript: {
        xpath: "//script[(@type='application/javascript')
          or (@type='text/javascript')
          or (@language='javascript')]/text()",
        parser: 'application/x-javascript'
       }
    }

  end
end
