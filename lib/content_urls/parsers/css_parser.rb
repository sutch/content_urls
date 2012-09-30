class ContentUrls
  class CssParser

    def links(body, base_url)
      links = []
      parser = Parser.new(body).each do |u|
        abs = to_absolute(URI(u), base_url) rescue next
        links << abs
      end
      links.uniq!
      links
    end

    def rewrite_each(body, base_url, &block)
      Parser.rewrite_each(body, base_url) do |u|
        abs = to_absolute(URI(u), base_url) rescue next
        replacement = yield abs
        (replacement.nil? ? u : replacement)
      end
    end

    class Parser

      include Enumerable

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

      def self.test_uri(css)
        @@regex_uri =~ css ? true : false
      end

      def self.test_baduri(css)
        @@regex_baduri =~ css ? true : false
      end

      attr_reader :css

      def initialize(css)
        @remaining = @css = css
      end

      def each
        done = false
        while ! done
          if @@regex_uri =~ @remaining
            match = $1
            uri = $7 || $14 || $23
            #if @@regex_baduri =~ match  ## bad URI
            #  @remaining = @remaining[Regexp.last_match.begin(0)+1..-1]  # Use last_match from regex_uri test
            #  done = true if @remaining.length == 0
            #  next
            #else
              @remaining = Regexp.last_match.post_match
              yield uri
            #end
          else
            @remaining = ''
            done = true
          end
        end
      end

      def self.rewrite_each(css, url, &block)
        done = false
        remaining = css
        rewritten = ''
        while ! done
          if match = @@regex_uri.match(remaining)
            uri = match[7] || match[14] || match[23]
            rewritten += match.pre_match
            remaining = match.post_match
            replacement = yield uri
            rewritten += (replacement.nil? ? match[0] : match[0].sub(uri, replacement))
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
end
