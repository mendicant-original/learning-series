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
      if tag.content == "\n\n"
        tag.remove
        # puts tag.class
        # puts tag.inspect
        # puts
      else
        name = tag.name == "p" ? "para" : tag.name
        send name.to_sym, tag
      end
    end
  end
  
  def h1(tag)
    title nil, tag.inner_html
  end
  
  def h2(tag)
    section tag.inner_html
  end
  
  def para(tag)
    prose tag.inner_html
  end
  
  def pre(tag)
    code tag.children[0].inner_html
  end
  
  def ul(tag)
    items = tag.children.map do |li|
      li.inner_html.empty? ? nil : li.inner_html
    end
    list *items.compact
  end
end