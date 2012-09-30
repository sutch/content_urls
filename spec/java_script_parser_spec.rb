require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ContentUrls::JavaScriptParser do
  it "should return no URLs given no content" do
    ContentUrls::JavaScriptParser.each_url('').should eq []
  end
end

describe ContentUrls::JavaScriptParser do
  it "should return the URLs in the content" do
    ContentUrls::JavaScriptParser.each_url('var link="http://www.sample.com/index.html"').first.should eq 'http://www.sample.com/index.html'
  end
end
