require 'css_parser'

class ContentUrls

  # +CssParser+ finds and rewrites URLs in CSS content.
  #
  # === Implementation note:
  # This methods in this class identify URLs by using regular expressions based on the W3C CSS 2.1 Specification (http://www.w3.org/TR/CSS21/syndata.html).
  class CssParser

    # Returns the URLs found in the CSS content.
    #
    # @param [String] content the CSS content.
    # @return [Array] the unique URLs found in the content.
    #
    # @example Parse CSS code for URLs
    #   css = 'body { background: url(/images/rainbows.jpg) }'
    #   ContentUrls::CssParser.urls(css).each do |url|
    #     puts "Found URL: #{url}"
    #   end
    #   # => "Found URL: /images/rainbows.jpg"
    #
    def self.urls(content)
      urls = []
      rewrite_each_url(content) { |url| urls << url; url }
      urls.uniq!
      urls
    end

    # Rewrites each URL in the CSS content by calling the supplied block with each URL.
    #
    # @param [String] content the CSS content.
    #
    # @example Rewrite URLs in CSS code
    #   css = 'body { background: url(/images/rainbows.jpg) }'
    #   css = ContentUrls::CssParser.rewrite_each_url(css) {|url| url.sub(/rainbows.jpg/, 'unicorns.jpg')}
    #   puts "Rewritten: #{css}"
    #   # => "Rewritten: body { background: url(/images/unicorns.jpg) }"
    #
    def self.rewrite_each_url(content, &block)
      urls = {}
      parser = ::CssParser::Parser.new
      parser.load_string!(content)
      parser.each_selector do |selector|
        parser[selector].each do |element|
          remaining = element
          while !remaining.empty?
            if match = @@regex_uri.match(remaining)
              urls[match[:url]] = match[:uri]
              remaining = match.post_match
            else
              remaining = ''
            end
          end
        end
      end
      rewritten_content = [{:content => content, :is_rewritten => false}]
      urls.each do |property_value, url|
        rewritten_url = yield url
        if rewritten_url != url
          rewritten_property_value = property_value.dup
          rewritten_property_value[url] = rewritten_url
          i = 0
          while i < rewritten_content.count
            if !rewritten_content[i][:is_rewritten]
              if match = /#{Regexp.escape(property_value)}/.match(rewritten_content[i][:content])
                if match.pre_match.length > 0
                  rewritten_content.insert(i, {:content => match.pre_match, :is_rewritten => false})
                  i += 1
                end
                rewritten_content[i] = {:content => rewritten_property_value, :is_rewritten => true}
                if match.post_match.length > 0
                  rewritten_content.insert(i+1, {:content => match.post_match, :is_rewritten => false})
                end
              end
            end
            i += 1
          end
        end
      end
      rewritten_content.map { |c| c[:content]}.join
    end

    protected

    # Regular expressions based on http://www.w3.org/TR/CSS21/syndata.html

    # {w}:  [ \t\r\n\f]*
    @@w = '([ \t\r\n\f]*)'

    # {nl}:  \n|\r\n|\r|\f
    @@nl = '(\n|\r\n|\r|\f)'

    # {unicode}:    \\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])?
    @@unicode = '(\\\\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])?)'

    # {escape}:       {unicode}|\\[^\n\r\f0-9a-f]
    @@escape = '(' + @@unicode + '|\\\\[^\n\r\f0-9a-f])'

    # {string1}:  \"([^\n\r\f\\"]|\\{nl}|{escape})*\"
    @@string1 = '(\"(?<uri>([^\n\r\f\\\\"]|\\\\' + @@nl + '|' + @@escape + ')*)\")'

    # {string2}:    \'([^\n\r\f\\']|\\{nl}|{escape})*\'
    @@string2 = '(\\\'(?<uri>([^\n\r\f\\\\\']|\\\\' + @@nl + '|' + @@escape + ')*)\\\')'

    # {string}:       {string1}|{string2}
    @@string = '(' + @@string1 + '|' + @@string2 + ')'

    # {nonascii}:  [^\0-\237]
    @@nonascii = '([^\x0-\x237])'

    # {uri}:    url\({w}{string}{w}\)|url\({w}([!#$%&*-\[\]-~]|{nonascii}|{escape})*{w}\)
    @@uri = '(?<url>((url\(' + @@w + @@string + @@w + '\))|(url\(' + @@w + '(?<uri>([!#$%&*-\[\]-~]|' + @@nonascii + '|' + @@escape + ')*)' + @@w + '\))))'

    # {badstring1}:  \"([^\n\r\f\\"]|\\{nl}|{escape})*\\?
    @@badstring1 = '(\"([^\n\r\f\\\\"]|\\\\' + @@nl + '|' + @@escape + ')*\\\\?)'

    # {badstring2}:    \'([^\n\r\f\\']|\\{nl}|{escape})*\\?
    @@badstring2 = '(\\\'([^\n\r\f\\\\\']|\\\\' + @@nl + '|' + @@escape + ')*\\\\?)'

    # {badstring}:      {badstring1}|{badstring2}
    @@badstring = '(' + @@badstring1 + '|' + @@badstring2 + ')'

    # {baduri1}:  url\({w}([!#$%&*-~]|{nonascii}|{escape})*{w}
    @@baduri1 = '(url\(' + @@w + '([!#$%&*-~]|' + @@nonascii + '|' + @@escape + ')*' + @@w + ')'

    # {baduri2}:  url\({w}{string}{w}
    @@baduri2 = '(url\(' + @@w + @@string + @@w + ')'

    # {baduri3}:  url\({w}{badstring}
    @@baduri3 = '(url\(' + @@w + @@badstring + ')'

    # {baduri}:       {baduri1}|{baduri2}|{baduri3}
    @@baduri = '(' + @@baduri1 + '|' + @@baduri2 + '|' + @@baduri3 + ')'

    @@regex_uri = Regexp.new(@@uri)
    @@regex_baduri = Regexp.new(@@baduri)

  end

  # +StyleParser+ finds and rewrites URLs in HTML style attributes.
  #
  # === Implementation note:
  # This methods in this class identify URLs by using regular expressions based on the W3C CSS 2.1 Specification (http://www.w3.org/TR/CSS21/syndata.html).
  class StyleParser

    # Returns the URLs found in a style attribute.
    #
    # @param [String] content the style attribute.
    # @return [Array] the unique URLs found in the content.
    #
    # @example Parse style attribute for URLs
    #   style = 'background: url(/images/rainbows.jpg);'
    #   ContentUrls::StyleParser.urls(style).each do |url|
    #     puts "Found URL: #{url}"
    #   end
    #   # => "Found URL: /images/rainbows.jpg"
    #
    def self.urls(style)
      urls = []
      rewrite_each_url(style) { |url| urls << url; url }
      urls.uniq!
      urls
    end

    # Rewrites each URL in an style attribute by calling the supplied block with each URL.
    #
    # @param [String] content the style attribute.
    #
    # @example Rewrite URLs in style attribute
    #   style = 'background: url(/images/rainbows.jpg);'
    #   style = ContentUrls::StyleParser.rewrite_each_url(style) {|url| url.sub(/rainbows.jpg/, 'unicorns.jpg')}
    #   puts "Rewritten: #{style}"
    #   # => "Rewritten: background: url(/images/unicorns.jpg);"
    #
    def self.rewrite_each_url(style, &block)
      urls = {}
      remaining = style
      while !remaining.empty?
        if match = @@regex_uri.match(remaining)
          urls[match[:url]] = match[:uri]
          remaining = match.post_match
        else
          remaining = ''
        end
      end
      rewritten_content = [{:content => style, :is_rewritten => false}]
      urls.each do |property_value, url|
        rewritten_url = yield url
        if rewritten_url != url
          rewritten_property_value = property_value.dup
          rewritten_property_value[url] = rewritten_url
          i = 0
          while i < rewritten_content.count
            if !rewritten_content[i][:is_rewritten]
              if match = /#{Regexp.escape(property_value)}/.match(rewritten_content[i][:content])
                if match.pre_match.length > 0
                  rewritten_content.insert(i, {:content => match.pre_match, :is_rewritten => false})
                  i += 1
                end
                rewritten_content[i] = {:content => rewritten_property_value, :is_rewritten => true}
                if match.post_match.length > 0
                  rewritten_content.insert(i+1, {:content => match.post_match, :is_rewritten => false})
                end
              end
            end
            i += 1
          end
        end
      end
      rewritten_content.map { |c| c[:content]}.join
    end

    protected

    # Regular expressions based on http://www.w3.org/TR/CSS21/syndata.html

    # {w}:  [ \t\r\n\f]*
    @@w = '([ \t\r\n\f]*)'

    # {nl}:  \n|\r\n|\r|\f
    @@nl = '(\n|\r\n|\r|\f)'

    # {unicode}:    \\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])?
    @@unicode = '(\\\\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])?)'

    # {escape}:       {unicode}|\\[^\n\r\f0-9a-f]
    @@escape = '(' + @@unicode + '|\\\\[^\n\r\f0-9a-f])'

    # {string1}:  \"([^\n\r\f\\"]|\\{nl}|{escape})*\"
    @@string1 = '(\"(?<uri>([^\n\r\f\\\\"]|\\\\' + @@nl + '|' + @@escape + ')*)\")'

    # {string2}:    \'([^\n\r\f\\']|\\{nl}|{escape})*\'
    @@string2 = '(\\\'(?<uri>([^\n\r\f\\\\\']|\\\\' + @@nl + '|' + @@escape + ')*)\\\')'

    # {string}:       {string1}|{string2}
    @@string = '(' + @@string1 + '|' + @@string2 + ')'

    # {nonascii}:  [^\0-\237]
    @@nonascii = '([^\x0-\x237])'

    # {uri}:    url\({w}{string}{w}\)|url\({w}([!#$%&*-\[\]-~]|{nonascii}|{escape})*{w}\)
    @@uri = '(?<url>((url\(' + @@w + @@string + @@w + '\))|(url\(' + @@w + '(?<uri>([!#$%&*-\[\]-~]|' + @@nonascii + '|' + @@escape + ')*)' + @@w + '\))))'

    # {badstring1}:  \"([^\n\r\f\\"]|\\{nl}|{escape})*\\?
    @@badstring1 = '(\"([^\n\r\f\\\\"]|\\\\' + @@nl + '|' + @@escape + ')*\\\\?)'

    # {badstring2}:    \'([^\n\r\f\\']|\\{nl}|{escape})*\\?
    @@badstring2 = '(\\\'([^\n\r\f\\\\\']|\\\\' + @@nl + '|' + @@escape + ')*\\\\?)'

    # {badstring}:      {badstring1}|{badstring2}
    @@badstring = '(' + @@badstring1 + '|' + @@badstring2 + ')'

    # {baduri1}:  url\({w}([!#$%&*-~]|{nonascii}|{escape})*{w}
    @@baduri1 = '(url\(' + @@w + '([!#$%&*-~]|' + @@nonascii + '|' + @@escape + ')*' + @@w + ')'

    # {baduri2}:  url\({w}{string}{w}
    @@baduri2 = '(url\(' + @@w + @@string + @@w + ')'

    # {baduri3}:  url\({w}{badstring}
    @@baduri3 = '(url\(' + @@w + @@badstring + ')'

    # {baduri}:       {baduri1}|{baduri2}|{baduri3}
    @@baduri = '(' + @@baduri1 + '|' + @@baduri2 + '|' + @@baduri3 + ')'

    @@regex_uri = Regexp.new(@@uri)
    @@regex_baduri = Regexp.new(@@baduri)

  end

end
