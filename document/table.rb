# encoding: utf-8

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"
require "learning_material"

LearningMaterial.generate("table.pdf") do

  chapters_folder = File.expand_path(File.join(File.dirname(__FILE__),
                                               "chapters"))

  Dir.chdir(chapters_folder) do
    Dir.glob("*") do |chapter|
      load_chapter(File.join(chapters_folder, chapter))
    end
  end
end