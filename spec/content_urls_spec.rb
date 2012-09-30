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
