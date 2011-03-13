The Ruby Mendicant University (RMU) - founded by "Ruby Best Practices" author, Gregory Brown - is a friendly, supportive online ruby-learning community. The on-going RMU courses feature an eclectic collection of practical problems that challenge students to test and deepen their core understanding of the Ruby programming language. 

Once a particular course is completed, the assignments are posted publicly and are quite useful for self-study. The RMU Learning Series was conceived as a means of providing an "under the hood" examination of solutions submitted by RMU alumni. Its purpose is not only to give other students an idea of what constitutes an acceptable solution and but also to provide insight into the type of reasoning that goes into crafting one.

In this first installment we will look at the final exam assigned to the RMU class session of September 2010.

The Problem
-----------

The task was to build a general purpose table structure that could be used in a wide range of data processing scenarios. You can view the exact list of requirements here on Github: https://github.com/rmu/s1-final

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

We will use the Test::Unit library from the Ruby stdlib and the contest gem. The latter adds a thin layer on top of the Test::Unit API, allowing us to write for example:
    
    test "should do stuff" do
      assert true
    end
    
instead of

    def test_should_do_stuff
      assert true
    end

The contest library also supports nested context blocks, which make the organization of your test suite easier. Like in RSpec, every context block can have its own setup and teardown methods and nested contexts inherit the setup/teardown from their parents.
