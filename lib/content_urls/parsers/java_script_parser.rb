require 'uri'

class ContentUrls
  class JavaScriptParser

    def self.each_url(content)
      urls = []
      URI.extract(content).each { |u| urls << u }
      urls.uniq!
      urls
    end

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
