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
    def self.urls(content)
      urls = []
      remaining = content
      while ! remaining.empty?
        if @@regex_uri =~ remaining
          match = $1
          url = $7 || $14 || $23
          #if @@regex_baduri =~ match  ## bad URL
          #  remaining = remaining[Regexp.last_match.begin(0)+1..-1]  # Use last_match from regex_uri test
          #else
            remaining = Regexp.last_match.post_match
            urls << url
          #end
        else
          remaining = ''
        end
      end
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
      done = false
      remaining = content
      rewritten = ''
      while ! remaining.empty?
        if match = @@regex_uri.match(remaining)
          url = match[7] || match[14] || match[23]
          rewritten += match.pre_match
          remaining = match.post_match
          replacement = yield url
          rewritten += (replacement.nil? ? match[0] : match[0].sub(url, replacement))
        else
          rewritten += remaining
          remaining = ''
        end
      end
      return rewritten
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
    @@string1 = '(\"(([^\n\r\f\\\\"]|\\\\' + @@nl + '|' + @@escape + ')*)\")'

    # {string2}:    \'([^\n\r\f\\']|\\{nl}|{escape})*\'
    @@string2 = '(\\\'(([^\n\r\f\\\\\']|\\\\' + @@nl + '|' + @@escape + ')*)\\\')'

    # {string}:       {string1}|{string2}
    @@string = '(' + @@string1 + '|' + @@string2 + ')'

    # {nonascii}:  [^\0-\237]
    @@nonascii = '([^\x0-\x237])'

    # {uri}:    url\({w}{string}{w}\)|url\({w}([!#$%&*-\[\]-~]|{nonascii}|{escape})*{w}\)
    @@uri = '(((url\(' + @@w + @@string + @@w + '\))|(url\(' + @@w + '(([!#$%&*-\[\]-~]|' + @@nonascii + '|' + @@escape + ')*)' + @@w + '\))))'

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
