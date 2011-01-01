# encoding: utf-8

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../vendor/jambalaya/lib"
require "jambalaya"
require "bluecloth"
require "nokogiri"

class LearningMaterial < Jambalaya
  
  def load_chapter(filename)
    mk = BlueCloth.new(File.read(filename))
    tags = Nokogiri::HTML(mk.to_html)
    tags.search("body").children.each do |tag|
      
      # Nokogiri is returning some useless nodes like:
      # #<Nokogiri::XML::Text:0xa34a4e "\n\n">
      if tag.content != "\n\n"
        
        # p is already a method name, so we need an alternative
        name = tag.name == "p" ? "para" : tag.name
        send name.to_sym, tag
      end
    end
  end
  
  # Mapping the html tags to Jambalaya methods
  def h1(tag)
    chapter_number = nil
    str = tag.inner_html
    if str =~ /^\d+/
      chapter_number = "CHAPTER #{str.slice!(/^\d+/).to_i}"
    end
    title chapter_number, str.strip
  end
  
  def h2(tag)
    section tag.inner_html
  end
  
  def para(tag)
    prose tag.inner_html
  end
  
  def pre(tag)
    indent(0.2.in) do
      previous_color = fill_color
      fill_color "222222"
      
      snippet = tag.children[0].inner_html.gsub("&gt;", ">").gsub("&lt;", "<")
      code(snippet, 8)
      
      fill_color previous_color
    end
  end
  
  def ul(tag)
    items = tag.children.map do |li|
      li.inner_html.empty? ? nil : li.inner_html
    end
    list *items.compact
  end
end