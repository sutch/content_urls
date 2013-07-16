require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ContentUrls::HtmlParser do
  it "should return no URLs when given no content" do
    ContentUrls::HtmlParser.urls('').should eq []
  end
  it "should return no URLs when given garbage content" do
    ContentUrls::HtmlParser.urls('j;alksdjfkladsjflkajdfaksdjfsdj  kladjsf lkfjalkdfj lkajdf9458094djjf').should eq []
  end
end

describe ContentUrls::HtmlParser do
  it "should return the URL in the content" do
    ContentUrls::HtmlParser.urls("<a href='index.html").first.should eq 'index.html'
    ContentUrls::HtmlParser.urls("<a href='index.html").count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 1 and return all a links and no other links" do

html_sample_1 =<<SAMPLE_1
<html>
<head>
  <title>HTML Sample 1</title>
</head>
<body>
  <h1>HTML Sample 1</h1>
  <a href="a-href-link-1.html"></a>
  <a href="http://www.example.com/1/2/3/a-href-link-2.html"></a>
  <a href="/folder/a-href-link-3.html?a=1"></a>
</body>
</html>
SAMPLE_1

    urls = ContentUrls::HtmlParser.urls(html_sample_1)
    urls.include?('a-href-link-1.html').should eq true
    urls.include?('http://www.example.com/1/2/3/a-href-link-2.html').should eq true
    urls.include?('/folder/a-href-link-3.html?a=1').should eq true
    urls.count.should eq 3
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 1 and rewrite all a links" do

html_sample_1 =<<SAMPLE_1
<html>
<head>
  <title>HTML Sample 1</title>
</head>
<body>
  <h1>HTML Sample 1</h1>
  <a href="a-href-link-1.html"></a>
  <a href="http://www.example.com/1/2/3/a-href-link-2.html"></a>
  <a href="/folder/a-href-link-3.html?a=1"></a>
</body>
</html>
SAMPLE_1

    content = ContentUrls::HtmlParser.rewrite_each_url(html_sample_1) do |url|
      url = URI.parse url
      url.path = url.path.sub(/\.html\b/, '.php')
      url
    end
    urls = ContentUrls::HtmlParser.urls(content)
    urls.include?('a-href-link-1.php').should eq true
    urls.include?('http://www.example.com/1/2/3/a-href-link-2.php').should eq true
    urls.include?('/folder/a-href-link-3.php?a=1').should eq true
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 2 and return all 'area href' URLs and no other URLs" do

html_sample_2 =<<SAMPLE_2
<html>
<head>
  <title>HTML Sample 2</title>
</head>
<body>
  <h1>HTML Sample 2</h1>
  <!-- commented out in order to not affect URL count
    <img src="sample.gif" width="200" height="200" alt="Click somewhere" usemap="#sample-map">
  -->
  <map name="sample-map">
    <area shape="rect" coords="0,0,100,100" href="area-href-link-1.html" alt="link 1">
    <area shape="circle" coords="150,150,2" href="http://www.example.com/1/2/3/area-href-link-2.html" alt="link 2">
    <area shape="circle" coords="100,180,1" href="/folder/area-href-link-3.html?a=1" alt="link 3">
  </map>
</body>
</html>
SAMPLE_2

    urls = ContentUrls::HtmlParser.urls(html_sample_2)
    urls.include?('area-href-link-1.html').should eq true
    urls.include?('http://www.example.com/1/2/3/area-href-link-2.html').should eq true
    urls.include?('/folder/area-href-link-3.html?a=1').should eq true
    urls.count.should eq 3
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 3 and return 'body background' URL and no other URLs" do

html_sample_3 =<<SAMPLE_3
<html>
<head>
  <title>HTML Sample 3</title>
</head>
<body background="/images/background.png">
  <h1>HTML Sample 3</h1>
</body>
</html>
SAMPLE_3

    urls = ContentUrls::HtmlParser.urls(html_sample_3)
    urls.first.should eq '/images/background.png'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 4 and return 'embed src' URL and no other URLs" do

html_sample_4 =<<SAMPLE_4
<html>
<head>
  <title>HTML Sample 4</title>
</head>
<body>
  <h1>HTML Sample 4</h1>
  <embed src="sample.swf" />
</body>
</html>
SAMPLE_4

    urls = ContentUrls::HtmlParser.urls(html_sample_4)
    urls.first.should eq 'sample.swf'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 5 and return 'img src' URL and no other URLs" do

html_sample_5 =<<SAMPLE_5
<html>
<head>
  <title>HTML Sample 5</title>
</head>
<body>
  <h1>HTML Sample 5</h1>
  <img src="sample.gif">
</body>
</html>
SAMPLE_5

    urls = ContentUrls::HtmlParser.urls(html_sample_5)
    urls.first.should eq 'sample.gif'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 6 and return 'link href' URL and no other URLs" do

html_sample_6 =<<SAMPLE_6
<html>
<head>
  <title>HTML Sample 6</title>
  <link href="/index.php" REL="index">
</head>
<body>
  <h1>HTML Sample 6</h1>
</body>
</html>
SAMPLE_6

    urls = ContentUrls::HtmlParser.urls(html_sample_6)
    urls.first.should eq '/index.php'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 7 and return 'object data' URL and no other URLs" do

html_sample_7 =<<SAMPLE_7
<html>
<head>
  <title>HTML Sample 7</title>
</head>
<body>
  <h1>HTML Sample 7</h1>
  <object width="400" height="400" data="/stuff/example.swf"></object>
</body>
</html>
SAMPLE_7

    urls = ContentUrls::HtmlParser.urls(html_sample_7)
    urls.first.should eq '/stuff/example.swf'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 8 and return 'script src' URL and no other URLs" do

html_sample_8 =<<SAMPLE_8
<html>
<head>
  <title>HTML Sample 8</title>
</head>
<body>
  <h1>HTML Sample 8</h1>
  <script language="javascript" src="../scripts/go.js"></script>
</body>
</html>
SAMPLE_8

    urls = ContentUrls::HtmlParser.urls(html_sample_8)
    urls.first.should eq '../scripts/go.js'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 9 and return 'meta content' URL and no other URLs" do

html_sample_9 =<<SAMPLE_9
<html>
<head>
  <title>HTML Sample 9</title>
  <meta http-equiv="refresh" content="5;URL='http://example.com/'">
</head>
<body>
  <h1>HTML Sample 9</h1>
</body>
</html>
SAMPLE_9

    urls = ContentUrls::HtmlParser.urls(html_sample_9)
    urls.first.should eq 'http://example.com/'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 10 and return URLs found within 'style' attributes, and return no other URLs" do

html_sample_10 =<<SAMPLE_10
<html>
<head>
  <title>HTML Sample 10</title>
</head>
<body style="background-image:url('background.jpg');">
  <h1>HTML Sample 10</h1>
</body>
</html>
SAMPLE_10

    urls = ContentUrls::HtmlParser.urls(html_sample_10)
    urls.first.should eq 'background.jpg'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 11 and return URLs found within 'style' tags, and return no other URLs" do

html_sample_11 =<<SAMPLE_11
<html>
<head>
  <title>HTML Sample 11</title>
  <style type="text/css">
body {background-image:url('/image/background.jpg');}
  </style>
</head>
<body>
  <h1>HTML Sample 11</h1>
</body>
</html>
SAMPLE_11

    urls = ContentUrls::HtmlParser.urls(html_sample_11)
    urls.first.should eq '/image/background.jpg'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 12 and return URLs found within 'script' tags, and return no other URLs" do

html_sample_12 =<<SAMPLE_12
<html>
<head>
  <title>HTML Sample 12</title>
<script type="text/javascript">
var link="http://www.sample.com/index.html"
// ...
</script>
</head>
<body>
  <h1>HTML Sample 12</h1>
</body>
</html>
SAMPLE_12

    urls = ContentUrls::HtmlParser.urls(html_sample_12)
    urls.first.should eq 'http://www.sample.com/index.html'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse HTML Sample 13 and return 'frame src' URL and no other URLs" do

html_sample_13 =<<SAMPLE_13
<html>
<head>
  <title>HTML Sample 8</title>
</head>
<body>
  <h1>HTML Sample 13</h1>
  <frame src='/info.html'>
</body>
</html>
SAMPLE_13

    urls = ContentUrls::HtmlParser.urls(html_sample_13)
    urls.first.should eq '/info.html'
    urls.count.should eq 1
  end
end

describe ContentUrls::HtmlParser do
  it "should parse the HTML and return nil when no 'base' URL" do

    html_missing_base_sample =<<MISSING_BASE_SAMPLE
<html>
<head>
  <title>HTML no base Sample</title>
</head>
<body>
  <h1>HTML no base Sample</h1>
</body>
</html>
MISSING_BASE_SAMPLE

    url = ContentUrls::HtmlParser.base(html_missing_base_sample)
    url.should eq nil
  end
end

describe ContentUrls::HtmlParser do
  it "should parse the HTML and return the 'base' URL and no other URLs" do

  html_base_sample =<<BASE_SAMPLE
<html>
<head>
  <base href='/en/'>
  <title>HTML base Sample</title>
</head>
<body>
  <h1>HTML base Sample</h1>
</body>
</html>
BASE_SAMPLE

    url = ContentUrls::HtmlParser.base(html_base_sample)
    url.should eq '/en/'
  end
end

describe ContentUrls::HtmlParser do
  it "should execute the sample code for rewrite_each_url method" do
    #output = ''
    html = '<html><a href="index.htm">Click me</a></html>'
    html = ContentUrls::HtmlParser.rewrite_each_url(html) {|url| 'index.php'}
    #output += "Rewritten: #{html}" + "\n"
    #output.should eq %Q{Rewritten: <html><a href="index.php">Click me</a></html>\n}
    ContentUrls::HtmlParser.urls(html).first.should eq 'index.php'  # Nokogiri rewrites HTML, instead check rewritten URL
  end
  it "should execute sample code for urls method" do
    output = ''
    html = '<html><a href="index.htm">Click me</a></html>'
    ContentUrls::HtmlParser.urls(html).each do |url|
      output += "Found URL: #{url}" + "\n"
    end
    output.should eq %Q{Found URL: index.htm\n}
  end
end
