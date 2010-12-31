# encoding: utf-8

$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"
require "learning_material"

LearningMaterial.generate("table.pdf") do

  title "CHAPTER 1", "Driving Code Through Tests"
  prose %{
    If you've done some Ruby--even a little bit--you have probably heard of 
    <i>test-driven development</i> (TDD). Many advocates present this software
    practice as the "secret key" to programming success.  However, it's still
    a lot of work to convince people that writing tests that are often longer
    than their implementation code can actually lower the total time spent on
    a particular project and increase overall efficiency.

    In my work, I've found most of the claims about the benefits of TDD to
    be true.  My code is better because I write tests that document the
    expected behaviors of my software while verifying that my code is meeting
    its requirements.  By writing automated test, I can be sure that once I
    narrow down the source of a bug and fix it, it'll never resurface without
    me knowing right away.   Because my tests are automated, I can hand my code
    off to others and mechanically assert my expectations, which does more for
    me than a handwritten specification ever could do.

    However, the important thing to take home from this is that automated
    testing is really no different than what we did before we discovered it.
    If you've ever tried to narrow down a bug with a print statement based on
    a conditional, you've already written a primitive form of unit test:
  }

  code <<-'EOS'
    if foo != "blah"
      puts "I expected 'blah' but foo contains #{foo}"
    end
  EOS
  
end