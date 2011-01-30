# encoding: utf-8

require_relative "../lib/learning_material"

LearningMaterial.generate("table.pdf") do
  
  
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
      text "#1 The Table assignment", :align => :right
    end
    
    move_cursor_to 30
    font_size(15) do
      text "Andrea Singh and Felipe Doria", :align => :right
    end
  end
  
  image "#{File.dirname(__FILE__)}/../assets/rmu_logo.png",
        :scale => 0.3,
        :at => [0, 30]
        
  ###

  chapters_folder = File.expand_path(File.join(File.dirname(__FILE__),
                                               "chapters"))
  
  Dir.chdir(chapters_folder) do
    Dir.glob("*") do |chapter|
      start_new_page
      
      number, title = chapter.split('-')
      number = number.to_i
      title.gsub!('.mk', ' ').gsub!('_', ' ')
      title = "Chapter #{number.to_i}: #{title}" if number > 0
      
      outline.define do
        section(title, :destination => page_number)
      end
      
      load_chapter(File.join(chapters_folder, chapter))
    end
  end
end