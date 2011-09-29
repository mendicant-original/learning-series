[Mendicant University (MU)](http://university.rubymendicant.com/) is a free online school aimed at socially minded software developers. It was founded in 2010 by [Gregory Brown](http://majesticseacreature.com/), author of the ["Practicing Ruby"](http://practicingruby.com/) weekly newsletter and original developer of the PDF generation library Prawn. 

The on-going MU three-week core courses focus on practical problems, designed to deepen the students' understanding of software programming. To date, over sixty students have successfully completed the course and achieved MU alumni status.

Once a course session is completed, the [assignments are posted publicly](http://university.rubymendicant.com/resources/learning_materials.html) and are can be used for self-study. The MU Learning Series was conceived as a means of providing an "under the hood" examination of real solutions submitted by alumni. The intention is to allow a glimpse into the type of reasoning that went into coming up with one possible solution.

In this first installment we will look at one of the assignments from the MU session of September 2010. 

The Problem
-----------

The task was to build a general purpose table structure that could be used in a wide range of data processing scenarios. You can view the exact list of requirements on Github [here](https://github.com/rmu/s1-final).

At a minimum, the API of the table structure needed to implement the following features:

* add, insert and delete rows and columns
* support named column headers
* access a particular row, column or cell
* update values of an entire row or column
* filter rows and columns by given criteria

As the end product is likely to be fairly complex, it would be easy to get overwhelmed were we to try to implement all the features at once. If you read through the full list of requirements, you can see that they become progressively more complex. This type of problem lends itself particularly well to a Test Driven Development (TDD) approach, that is, developing the solution in small incremental step. We can start with one basic requirement, design a test for it and then write the code to make it pass. Then repeat the same procedure for the next requirement, and so on.

The first four chapters are a walk-through of this TDD approach and, as we shall see, the resulting solution is somewhat similar to that submitted by the majority of students in this session. In the later chapters, we will discuss how a naive implementation of TDD can result in failing to account for potential errors - in this particular case, situations involving data corruption, bad user input and problems with column names. Finally, in the concluding chapters, we'll take a look at some of the more unique approaches that made a deliberate attempt to incorporate a variety of Ruby best practices.

Test Environment
----------------

We will use the `Test::Unit` library from the Ruby stdlib and the contest gem. The latter adds a thin layer on top of the Test::Unit API, allowing us to write for example:
    
    test "should do stuff" do
      assert true
    end
    
instead of

    def test_should_do_stuff
      assert true
    end

The contest library also supports nested context blocks, which make the organization of your test suite easier. Like in RSpec, every context block can have its own setup and teardown methods and nested contexts inherit the setup/teardown from their parents.
