require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ContentUrls.to_absolute(nil, 'http://www.sample.com/') do
  it "returns nil when url is nil" do
    ContentUrls.to_absolute(nil, 'http://www.sample.com/').should eq nil
  end
end

describe ContentUrls.to_absolute('index.html', 'http://www.sample.com/') do
  it "merges url to base_url" do
    ContentUrls.to_absolute('index.html', 'http://www.sample.com/one/two/three/').should eq 'http://www.sample.com/one/two/three/index.html'
    ContentUrls.to_absolute('/index.html', 'http://www.sample.com/one/two/three/').should eq 'http://www.sample.com/index.html'
    ContentUrls.to_absolute('/four/index.html', 'http://www.sample.com/one/two/three/').should eq 'http://www.sample.com/four/index.html'
    ContentUrls.to_absolute('../index.html', 'http://www.sample.com/one/two/three/').should eq 'http://www.sample.com/one/two/index.html'
    ContentUrls.to_absolute('../four/index.html', 'http://www.sample.com/one/two/three/').should eq 'http://www.sample.com/one/two/four/index.html'
  end
end

describe ContentUrls.get_parser('bogus/bogus') do
  it "returns nil when content type is unknown" do
    ContentUrls.get_parser('bogus/bogus').should eq nil
  end
end

describe ContentUrls.register_parser('some_parser_class', %r{^(content/test)\b}) do
  it "returns the class for the content type" do
    ContentUrls.get_parser('content/test').should eq 'some_parser_class'
  end
end
