require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ContentUrls::CssParser do
  it "should return no URLs given no content" do
    ContentUrls::CssParser.urls('').should eq []
  end
  it "should return no URLs given garbage content" do
    ContentUrls::CssParser.urls('j;alksdjfkladsjflkajdfaksdjfsdj  kladjsf lkfjalkdfj lkajdf9458094djjf').should eq []
  end
end

describe ContentUrls::CssParser do
  it "should return the URLs in the content" do
    ContentUrls::CssParser.urls("body {background-image:url('image.png');}").first.should eq 'image.png'
  end
end

describe ContentUrls::CssParser do
  it "should execute the sample code for rewrite_each_url method" do
    output = ''
    css = 'body { background: url(/images/rainbows.jpg) }'
    css = ContentUrls::CssParser.rewrite_each_url(css) {|url| url.sub(/rainbows.jpg/, 'unicorns.jpg')}
    output += "Rewritten: #{css}" + "\n"
    output.should eq %Q{Rewritten: body { background: url(/images/unicorns.jpg) }\n}
  end
  it "should execute sample code for urls method" do
    output = ''
    css = 'body { background: url(/images/rainbows.jpg) }'
    ContentUrls::CssParser.urls(css).each do |url|
      output += "Found URL: #{url}" + "\n"
    end
    output.should eq %Q{Found URL: /images/rainbows.jpg\n}
  end
end
