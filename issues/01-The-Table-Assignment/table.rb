# encoding: utf-8

require_relative "../../lib/learning_series"

LearningSeries.generate("RMU-Learning-Series-01.pdf") do
  
  cover("#1 The Table assignment", "Andrea Singh and Felipe Doria")

  chapters_folder = File.expand_path(File.join(File.dirname(__FILE__),
                                               "chapters"))
  
  Dir.chdir(chapters_folder) do
    Dir.glob("*") do |chapter|
      start_new_page
      
      title  = chapter.dup
      number = title.slice!(/\d+/).to_i
      
      title.gsub!('.md', ' ')
      title.gsub!('-', ' ')
      
      outline.define do
        t = number > 0 ? "Chapter #{number}: #{title}" : title
        section(t, :destination => page_number)
      end
      
      load_chapter(File.join(chapters_folder, chapter), number, title)
    end
  end
end