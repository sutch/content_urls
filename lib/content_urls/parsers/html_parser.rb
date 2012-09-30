require 'nokogiri'

class ContentUrls
  class HtmlParser

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
      img_src: {
        xpath: "//img[@src]",
        attribute: 'src'
      },
      link_href: {
        xpath: "//link[@href]",
        attribute: 'href'
      },
#        meta_content:  # TODO: test
#        {
#          xpath: "//meta[((@http-equiv='location') or (@http-equiv='refresh'))
#            and @content and contains(@content,';')
#            and number(substring-before(@content,';'))=substring-before(@content,';')]",
#          attribute: 'content',
#          url_regex: %r{/^\d+\s*;\s*(.+)$/}
#        },
      object_data: {
        xpath: "//object[@data]",
        attribute: 'data'
      },
      script_src: {
        xpath: "//script[@src]",
        attribute: 'src'
      },
      style: {
        xpath: "//*[@style]",
        attribute: 'style',
###          parser: CssParser.new
      },
      javascript: {
        xpath: "//script[(@type='application/javascript')
          or (@type='text/javascript')
          or (@language='javascript')]/text()",
###          parser: JavaScriptParser.new
       }
    }

    # Array of distinct A tag HREFs from the page
    def each_url(body, url)
      doc = Nokogiri::HTML(body) if body rescue nil
      links = []
      return links if !doc

      href = doc.search('//head/base/@href')
      base_url = URI(href.to_s) unless href.nil? rescue nil
      base_url = url if base_url && base_url.to_s().empty?

      rewrite_each(body, url) { |u|
        links << u
      }
      links.uniq!
      links
    end

    def rewrite_each_url(body, url, &block)
      doc = Nokogiri::HTML(body) if body rescue nil
      return nil if !doc

      href = doc.search('//head/base/@href')
      base_url = URI(href.to_s) unless href.nil? rescue nil
      base_url = url if base_url && base_url.to_s().empty?

      @@parser_definition.each do |type, definition|
        doc.search(definition[:xpath]).each do |obj|
          if definition.has_key?(:attribute)  # use tag attribute if provided
            v = obj[definition[:attribute]]
          else  # otherwise use tag's content
            v = obj.to_s
          end
          next if v.nil? or v.empty?

          if definition.has_key?(:parser)
            definition[:parser].rewrite_each(v, base_url) { |u|
              yield u
            }
          else
            next if v =~ /^#/
            abs = to_absolute(URI(v), base_url) rescue next
            u = yield abs
            if definition.has_key?(:attribute)
              if ! u.nil?
                obj[definition[:attribute]] = u.to_s
              end
            else
              puts "WARNING: unable to rewrite URL for #{v.to_s}"
            end
          end
        end
      end
      doc.to_s
    end  # rewrite_each

  end
end
