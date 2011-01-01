Introduction
============

The problem that we are examining here was the final exam assigned to the RMU core class of September 2010. This walkthrough presents how an acceptable solution can be reached using step by step Test Driven Development (TDD) practices. By the fourth chapter we will have arrived at a solution that is a conglomeration of the most common answers submitted. The later chapters discuss other solutions that would be more suitable for real-world application in that they set the groundwork for future requirements and maximizing performance.

Reading Notes
-------------

If you are new to Ruby or to TDD you will appreciate the first four chapters which walk you through developing a solution following TDD best practices. For those of you with more experience in these ares, you might want to scan the first four chapters and take a closer look at the later chapters.

The Problem
-----------

The RMU assignment was to build a general purpose table structure that can be used in a wide range of data processing scenarios. When exactly would you need to roll your own Table solution? Well, for example if you import (legacy) data from a CSV or YAML file and would like to manipulate, present or report on it. 

As a minimum, the API of the table structure needed to implement the following features:

* add, insert and delete rows and columns
* access a particular row, column or cell
* update values of an entire row or column
* filter rows and columns by given criteria

As the end product is likely to be fairly complex, it is easy to get overwhelmed if we tried to implement all the features at once. In this case, a better approach would be to start simple and add code for one requirement at the time. In other words, basic TDD.

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