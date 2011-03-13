
The most intuitive way to represent a table in Ruby is using a two dimensional array - where an individual row is an array and the collection of rows is also an array. 

In keeping with TDD practices, we'll begin with the simplest possible scenario, in this case, initializing an empty table object. 

To verify that the table is indeed empty, we first write a test to check that the table contains no rows:

    require 'test/unit'
    require 'contest'

    # This is a Test::Unit test suite
    # From now on we will omit this class declaration
    class TableTest < Test::Unit::TestCase

      test "can be initialized empty" do
        table = Table.new
        assert_equal [], table.rows
      end

    end

Making this test pass is as trivial as setting up a Table class with a single instance method - rows() - that returns an empty array. It is standard practice in TDD to "fake" return values - in this case, an empty array - to just satisfy the test requirements. As we progress, these stand-in return values will, of course,  be replaced by more meaningful code.

    class Table
      def rows
        []
      end
    end

Next, we need the ability to add rows to the empty table. Let's write a test for that: 

    test "row can be appended after empty initialization" do
      table = Table.new
      table.add_row([1,2,3])
      assert_equal [[1,2,3]], table.rows
    end

To satisfy this requirement, the rows() method can no longer simply return an empty array. Ideally, we want to make this new test pass without causing the first one to fail. This is the most straight forward code that would cause both tests to pass:

    class Table
      attr_reader :rows
      
      def initialize 
        @rows = []
      end

      def add_row(row)
        @rows << row
      end
    end

Given a large enough dataset, populating the table row by row would no longer be practical. It would be preferable to have the option to initialize the table with data. To accomplish this, we can pass a two-dimensional array to the initializer method of the Table class.

We need some sample data to work with while testing. In order to have it available to all of our tests, we'll stick it in a setup block:

    setup do
      @data = [["name",   "age", "occupation"  ],
               ["Tom",     32,   "engineer"    ],
               ["Beth",    12,   "student"     ],
               ["George",  45,   "photographer"],
               ["Laura",   23,   "aviator"     ],
               ["Marilyn", 84,   "retiree"     ]]
    end

Next we need to hook up our Table class in such a way that it can accept a two dimensional array as an argument upon initialization.

    test "can be initialized with a two-dimensional array" do
      table = Table.new(@data)
      assert_equal @data, table.rows
    end


    class Table
      attr_reader :rows

      def initialize(data = [])
        @rows = data
      end

      def add_row(row)
        @rows << row
      end
    end

Another common feature of tables is to have named columns. In a two-dimensional array the column names could be represented by the first nested array with the following arrays being the actual data rows. 

As things exist now, the first row of @data represents the column names. Therefore, when we try to access what we'd semantically expect to be the first row of data, the column names are returned instead:

    >> table = Table.new(@data)
    >> table.rows[0]
    => ["name", "age", "occupation"]

To remedy this, we could extract the first row and assign it to a separate variable, as follows:

    test "first row represents column names" do
      table = Table.new(@data)
      assert_equal ["name", "age", "occupation"], table.headers
    end


    class Table
      attr_reader :rows, :headers

      def  initialize(data = [])
        if !data.empty? 
          @headers = data.shift
          @rows = data
        else
          @rows, @headers = [], []
        end
      end

      def add_row(row)
        @rows << row
      end
    end

Here have reached a first milestone of sorts. We are able to initialize a Table with or without data and add rows to it manually. We have also laid the foundation to support named columns.

As you can see, taking a test driven approach allows us to make sure that the code is behaving as it should by focusing on small tasks. Following TDD principles also enables us to write code that progressively takes us in the right direction without having to worry about the full set of requirements at the outset.

Although it's a good start, as we shall see, this implementation has some undesired consequences. It corrupts the initialization data and fails to vet user input. Rather than cover those issues now, we'll keep building on the requirements and tackle these pitfalls in chapter 5.
