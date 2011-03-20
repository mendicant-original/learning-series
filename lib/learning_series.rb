# encoding: utf-8

require "rubygems"
require "bundler/setup"

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../vendor/jambalaya/lib"
require "jambalaya"
require "bluecloth"
require "nokogiri"

class LearningSeries < Jambalaya
  
  def setup_page_numbering
    repeat(:all, :dynamic => true) do
      stroke_line [bounds.left, bounds.bottom  - 0.2.in],
                  [bounds.right, bounds.bottom - 0.2.in]

      pn_width = width_of(page_number.to_s, :size => 6)

      if page_number > 1
        font("serif") do
          draw_text (page_number-1).to_s, :size => 6,
            :at => [bounds.right - pn_width, bounds.bottom - 0.4.in],
            :style => :bold
        end
      end
    end
  end
  
  def cover(issue, authors)
    font_families["cover"] = {
      :normal => "#{File.dirname(__FILE__)}/../assets/thryn___.ttf"
    }

    move_down 100

    font("cover") do
      formatted_text([ {:text => "RMU",
                        :color => "70120B",
                        :size => 48}
                     ])

      move_up 20
      formatted_text([ {:text => "Learning Series",
                        :color => "70120B",
                        :size => 56}
                     ])

      move_down 20
      font_size(30) do
        text issue, :align => :right
      end

      move_cursor_to 30
      font_size(15) do
        text authors, :align => :right
      end
    end

    image("#{File.dirname(__FILE__)}/../assets/rmu_logo.png",
          :scale => 0.3,
          :at => [0, 30])
    
    
    outline.define do
      page(:title => "Cover", :destination => page_number)
    end
  end
  
  def load_chapter(filename, number, title)
    mk   = BlueCloth.new(File.read(filename))
    tags = Nokogiri::HTML(mk.to_html)
    
    chapter = number > 0 ? "CHAPTER #{number}" : nil
    title(chapter, title)
    
    process_tags(tags.search("body").children)
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
  
  #
  # Mapping the html tags to Jambalaya methods
  #
  
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
    move_down 0.05.in
    
    aside(tag["title"]) do
      prose tag.inner_html
    end
    
    move_down 0.15.in
  end
  
  def p_to_prawn(tag)
    if tag.inner_html =~ /page_break/
      start_new_page
    else
      prose_text = tag.inner_html.gsub(/<a href.+?a>/,
                                       '<color rgb="#0000EE">\0</color>')
      
      prose(prose_text)
    end
  end
  alias :text_to_prawn :p_to_prawn
  
  def pre_to_prawn(tag)
    group do
      indent(0.2.in) do
        previous_color = fill_color
        fill_color("222222")
      
        snippet = tag.children[0].inner_html
        snippet.gsub!("&gt;", ">")
        snippet.gsub!("&lt;", "<")
        snippet.gsub!("&amp;", "&")
        
        code(snippet, 7)
      
        fill_color(previous_color)
      end
      move_down 0.05.in
    end
  end
  
  def blockquote_to_prawn(tag)
    group do
      font("serif", :size => 9) do
        move_down 0.05.in
        
        formatted_text_box([:text => "“", :color => "888888"],
                           :at => [0, cursor + 4],
                           :size => 40)
      
        indent(0.4.in) do
          tag.children.each do |p|
          
            text(p.inner_html.gsub(/\s+/," "),
                 :align         => :justify,
                 :inline_format => true,
                 :leading       => 2,
                 :style         => :italic)
            
            move_down 0.05.in
          end
        end
        
        move_down 0.1.in
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
  
end