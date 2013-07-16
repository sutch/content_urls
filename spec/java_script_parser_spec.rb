require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ContentUrls::JavaScriptParser do
  it "should return no URLs given no content" do
    ContentUrls::JavaScriptParser.urls('').should eq []
  end
end

describe ContentUrls::JavaScriptParser do
  it "should return only the URLs in the content" do
    ContentUrls::JavaScriptParser.urls('var link="http://www.sample.com/index.html"').first.should eq 'http://www.sample.com/index.html'
    ContentUrls::JavaScriptParser.urls('var link="http://www.sample.com/index.html"').count.should eq 1
  end
end

describe ContentUrls::JavaScriptParser do
  it "should execute the sample code for rewrite_each_url method" do
    output = ''
    javascript = 'var link="http://example.com/"'
    javascript = ContentUrls::JavaScriptParser.rewrite_each_url(javascript) {|url| url.upcase}
    output += "Rewritten: #{javascript}" + "\n"
    output.should eq %Q{Rewritten: var link="HTTP://EXAMPLE.COM/"\n}
  end
  it "should execute sample code for urls method" do
    output = ''
    javascript = 'var link="http://example.com/"'
    ContentUrls::JavaScriptParser.urls(javascript).each do |url|
      output += "Found URL: #{url}" + "\n"
    end
    output.should eq %Q{Found URL: http://example.com/\n}
  end
end
