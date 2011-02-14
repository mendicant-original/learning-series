The Ruby Mendicant University (RMU) takes a problem-driven approach to teaching Ruby. During the core course students are given a set of assignments, which they solve mostly on their own, but also in consultation with their peers and feedback from Gregory Brown, the founder of RMU.

Once the course is completed the assignments are posted publicly and can be used as learning material for self study. The RMU Learning Series examines actual solutions submitted by alumni to a particular problem. The purpose is to give you an overview of the types of solutions presented and the reasoning that went into producing them.

In this first installment we will look at the final exam assigned to the RMU core class of September 2010.

The Problem
-----------

The task was to build a general purpose table structure that can be used in a wide range of data processing scenarios. You can view the exact list of requirements on Github: https://github.com/rmu/s1-final

At a minimum, the API of the table structure needed to implement the following features:

* add, insert and delete rows and columns
* support named column headers
* access a particular row, column or cell
* update values of an entire row or column
* filter rows and columns by given criteria

As the end product is likely to be fairly complex, it is easy to get overwhelmed if we tried to implement all the features at once. If you read through the full list of requirements you can see that they become progressively more complex. This type of problem lends itself particularly well to a Test Driven Development (TDD) approach, since you can effectively check off one requirement at a time. You can start with the first one, design a test and then write the code to make it pass. Then repeat the same procedure for the next requirement, and so on.

The first four chapters walk through this TDD approach and, as we shall see, the resulting solution is somewhat similar to that submitted by the majority of students in this session. In the later chapters we will discuss some of the pitfalls of this simplistic approach like data corruption, bad input and problems with column names, as well as some more unique approaches that make a deliberate attempt to incorporate a variety of Ruby best practices.

Test Environment
----------------

We will use the Test::Unit library from the Ruby stdlib and the contest gem which adds just a thin layer on top of the Test::Unit API allowing us to write for example
    
    test "should do stuff" do
      assert true
    end
    
instead of

    def test_should_do_stuff
      assert true
    end

The contest library also supports nested context blocks, which make the organization of your test suite easier. Like in RSpec, every context block can have its own setup and teardown methods and nested contexts inherit the setup/teardown from their parents.