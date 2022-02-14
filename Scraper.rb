require 'proxycrawl'
require 'nokogiri'
require 'cgi'
require 'open-uri'
require 'uri'

token = 'TE5rnKchrHwH40QRwCT6MA'
api = ProxyCrawl::API.new(token: token)
url = 'https://www.amazon.com/s?i=specialty-aps&bbn=16225007011&rh=n%3A16225007011%2Cn%3A193870011'

def getDocFromUrl(url, api)
  html = api.get(url)
  doc = Nokogiri::HTML(html.body)
  return doc
end

def getLinks(doc)
  links = []
  doc.xpath("//*[@class=\"a-link-normal s-underline-text s-underline-link-text s-link-style a-text-normal\"]").each do |link|
    attr = link.attribute_nodes
    attr.each {|x| if x.text.include? "/"
                     x = "https://www.amazon.com".concat(x)
                     links.concat([x])
                   end}
  end
  return links
end

def getProductsInfo(links, api)
  links.each do |link|
    String uri = link
    begin
      html2 = api.get(link)
      doc2 = Nokogiri::HTML(html2.body)
      product_name = doc2.at('#productTitle').text
      product_price = doc2.css('span.a-offscreen')[0].text

      puts "Amazon Product URL: #{uri}"
      puts "Amazon Product Name: #{product_name.strip!}"
      puts "Amazon Product Price: #{product_price}"

      cnt = 0
      doc2.xpath("//*[@class=\"a-section a-spacing-medium a-spacing-top-small\"]").each do |link|
        inf = link.text
        subStr = inf.split('P.when("ReplacementPartsBulletLoader").execute(function(module){ module.initializeDPX(); })',-1).last.strip!
        infos = subStr.split('    ')
        infos.each do |x|
          puts "Amazon Product Subinfo: #{x}"
        end

        cnt = cnt + 1
      end
      puts "*******************************************************************"
    rescue
      puts "[ERROR] triggered"
    ensure
      #puts link
    end
  end
end

def getNextSubsite(doc, api)
  docc = nil
  doc.xpath("//*[@class=\"s-pagination-item s-pagination-next s-pagination-button s-pagination-separator\"]").each do |link|
    attr = link.attribute_nodes
    attr.each {|x| if x.text.include? "/"
                     x = "https://www.amazon.com".concat(x)
                     html = api.get(x)
                     docc = Nokogiri::HTML(html.body)
                   end}
  end
  return docc
end



#Extract whole category with details from subsite, and links to products
doc = getDocFromUrl(url, api)

counter = 0
while counter < 3
  links = getLinks(doc)
  if links.nil?
    break
  end
  puts "------------------------------------------------------"
  getProductsInfo(links, api)
  doc = getNextSubsite(doc, api)
  counter = counter + 1
end


#Extract by keyword with details from subsite, and links to products
keyword = 'keyboard'

urlparsed = "https://www.amazon.com/s?k=#{keyword}&ref=nb_sb_noss"
doc = getDocFromUrl(urlparsed, api)
counter = 0
while counter < 3
  links = getLinks(doc)
  if links.nil?
    break
  end
  puts "------------------------------------------------------"
  getProductsInfo(links, api)
  doc = getNextSubsite(doc, api)
  counter = counter + 1
end