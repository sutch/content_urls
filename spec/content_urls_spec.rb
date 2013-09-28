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

describe ContentUrls do
  it "should return relative URLs as absolute when requested" do

    html_base_sample =<<BASE_SAMPLE
<html>
<head>
  <base href='http://www.example.com/sample/'>
  <title>HTML base Sample</title>
</head>
<body>
  <h1>HTML base Sample</h1>
  <a href='about.html'>about</a>
</body>
</html>
BASE_SAMPLE

    urls = ContentUrls.urls(html_base_sample, 'text/html', use_base_url: true)
    urls[0].should eq 'http://www.example.com/sample/about.html'

    urls = ContentUrls.urls(html_base_sample, 'text/html', content_url: 'https://www2.example.com/test/index.html')
    urls[0].should eq 'https://www2.example.com/test/about.html'

    urls = ContentUrls.urls(html_base_sample, 'text/html', use_base_url: true, content_url: 'https://www2.example.com/test/index.html')
    urls[0].should eq 'http://www.example.com/sample/about.html'
  end
end

describe ContentUrls do
  it "should not change absolute URLs when requested to make absolute URLs from relative URLs" do

    html_base_sample =<<BASE_SAMPLE
<html>
<head>
  <base href='http://www2.example.com/sample/'>
  <title>HTML base Sample</title>
</head>
<body>
  <h1>HTML base Sample</h1>
  <a href='http://www.example.com/about.html'>about</a>
</body>
</html>
BASE_SAMPLE

    urls = ContentUrls.urls(html_base_sample, 'text/html', use_base_url: true)
    urls[0].should eq 'http://www.example.com/about.html'

    urls = ContentUrls.urls(html_base_sample, 'text/html', content_url: 'https://www2.example.com/test/index.html')
    urls[0].should eq 'http://www.example.com/about.html'

    urls = ContentUrls.urls(html_base_sample, 'text/html', use_base_url: true, content_url: 'https://www2.example.com/test/index.html')
    urls[0].should eq 'http://www.example.com/about.html'
  end
end

describe ContentUrls do
  it "should not change absolute URLs when requested to make absolute URLs from relative URLs" do

    html_sample =<<HTML_SAMPLE
<html>
<head>
  <title>HTML Sample</title>
</head>
<body>
  <h1>HTML Sample</h1>
  <a href='http://www.example.com/about.html'>about</a>
</body>
</html>
HTML_SAMPLE

    rewritten = ContentUrls.rewrite_each_url(html_sample, 'text/html') {|u|
      'http://example.org/about.php'
    }
    urls = ContentUrls.urls(rewritten, 'text/html')
    urls[0].should eq 'http://example.org/about.php'
  end
end
