# encoding: utf-8

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../vendor/jambalaya/lib"
require "jambalaya"
require "bluecloth"
require "nokogiri"

class LearningMaterial < Jambalaya
  
  def load_chapter(filename)
    mk = BlueCloth.new(File.read(filename))
    tags = Nokogiri::HTML(mk.to_html)
    process_tags tags.search("body").children
  end
  
  def process_tags(tags)
    tags.each do |tag|
      
      # Nokogiri is returning some useless nodes like:
      # #<Nokogiri::XML::Text:0xa34a4e "\n\n">
      if tag.content != "\n\n"
        send "#{tag.name}_to_prawn".to_sym, tag
      end
    end
  end
  
  # Mapping the html tags to Jambalaya methods
  def h1_to_prawn(tag)
    chapter_number = nil
    str = tag.inner_html
    if str =~ /^\d+/
      chapter_number = "CHAPTER #{str.slice!(/^\d+/).to_i}"
    end
    title chapter_number, str.strip
  end
  
  def h2_to_prawn(tag)
    move_down 0.1.in

    font("sans", :style => :bold, :size => 12) do
      text tag.inner_html
    end
    
    move_down 0.25.in
  end
  
  # This renders the aside
  # Yes, I'm cheating
  def h6_to_prawn(tag)
    aside(tag["title"]) do
      prose tag.inner_html
    end
  end
  
  def p_to_prawn(tag)
    if tag.inner_html =~ /page_break/
      break_page
    else
      prose tag.inner_html
    end
  end
  alias :text_to_prawn :p_to_prawn
  
  def pre_to_prawn(tag)
    group do
      indent(0.2.in) do
        previous_color = fill_color
        fill_color "222222"
      
        snippet = tag.children[0].inner_html.gsub("&gt;", ">").gsub("&lt;", "<")
        snippet.gsub!("&amp;", "&")
        code(snippet, 7)
      
        fill_color previous_color
      end
    end
  end
  
  def ul_to_prawn(tag, pad = 0)
    font("serif", :size => 9) do
      tag.children.each do |li|
        unless li.inner_html.empty?
          
          if li.children.size == 1
            list_item(li.inner_html, pad)
            
          else
            li.children.each do |child|
              if child.name == "ul"
                ul_to_prawn(child, pad + 0.30.in)
              else
                list_item(child.to_s, pad)
              end
            end
          end
          
        end
      end
    end

    move_down 0.05.in
  end
  
  def list_item(li, pad = 0)
    indent(pad) do
      float { text "•" }
      indent(0.15.in) do
        text li.gsub(/\s+/," "), 
          :inline_format => true,
          :leading       => 2
      end
    end
    move_down 0.05.in
  end
  
  def break_page
    start_new_page
  end
  
end