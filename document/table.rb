# encoding: utf-8

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"
require "learning_material"

DOC_TITLE = "The Table assignment"

LearningMaterial.generate("table.pdf") do

  chapters_folder = File.expand_path(File.join(File.dirname(__FILE__),
                                               "chapters"))

  text "Cover", :size => 50
  
  outline.define do
    section DOC_TITLE, :destination => page_number
  end

  Dir.chdir(chapters_folder) do
    Dir.glob("*") do |chapter|
      start_new_page
      
      number, title = chapter.split('-')
      number = number.to_i
      title.gsub!('.mk', ' ').gsub!('_', ' ')
      title = "Chapter #{number.to_i}: #{title}" if number > 0
      
      outline.add_subsection_to(DOC_TITLE) do
        outline.section(title, :destination => page_number)
      end
      
      load_chapter(File.join(chapters_folder, chapter))
    end
  end
end