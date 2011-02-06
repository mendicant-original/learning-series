# encoding: utf-8

require_relative "../lib/learning_material"

LearningMaterial.generate("table.pdf") do
  
  cover("#1 The Table assignment", "Andrea Singh and Felipe Doria")

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