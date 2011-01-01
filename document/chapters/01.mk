01 Setting Up the Table
=======================

The simplest possible table is an empty one. We will represent the table by a two dimensional array - where an individual row is an array and the collection of rows is also an array. 

The first failing test for a table that contains no rows:

    require 'test/unit'
    require 'contest'

    # This is a Test::Unit test suite
    # From now on we will omit this class declaration
    class TableTest < Test::Unit::TestCase

    test "can be initialized empty" do
      my_table = Table.new
      assert_equal [], my_table.rows
    end

    end

Making this test pass is as trivial as setting up a Table class with a single instance method - #rows - that returns an empty array. It is standard practice in TDD to "fake" return values, in this case an empty array, to merely satisfy the test requirements. As we progress, these stand-in return values will of course be replaced by more meaningful code.

    class Table
      def rows
        []
      end
    end

Next, we need the ability to add rows to the empty table. Let's write a test for that: 

    test "row can be appended after empty initialization" do
      my_table = Table.new
      my_table.add_row([1,2,3])
      assert_equal [[1,2,3]], my_table.rows
    end

To satisfy this new requirement, the #rows method can no longer simply return an empty array. Ideally, we want to make this new test pass without causing the first one to fail. This is the most straightforward code that would make both tests pass.

    class Table
      attr_reader :rows
      
      def initialize 
        @rows = []
      end

      def add_row(row)
        @rows << row
      end
    end

Populating the table row by row can quickly become cumbersome. It would be better to have the option to initialize the table with data. To accomplish this, we would need to pass a two-dimensional array to the initializer method of the Table class.

In order to have access to the seed data in all our tests, we'll stick some initial data in a setup block:

    setup do
      @simple_data = [["name",  "age", "occupation"], 
                      ["Tom", 32,"engineer"], 
                      ["Beth", 12,"student"], 
                      ["George", 45,"photographer"],
                      ["Laura", 23, "aviator"],
                      ["Marilyn", 84, "retiree"]]
    end

Next we need to hook up our Table class in such a way that it can accept a two dimensional array as an argument upon initialization.

    test "can be initialized with a two-dimensional array" do
      my_table = Table.new(@simple_data)
      assert_equal @simple_data, my_table.rows
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

Another common feature of tables is to have named columns. In a two dimensional array the column names could be represented by the first nested array, while the following arrays are the actual data rows. 

As things exist now, the first row of @simple_data represents the column names. Thus, if we try to access the first row, the column names are returned instead:

    >> my_table = Table.new(@simple_data)
    >> my_table.rows[0]
    => ["name",  "age",  "occupation"]

To remedy this, we could extract the first row and assign it to a separate variable, as follows.

    test "first row represents column names" do
      my_table = Table.new(@simple_data)
      assert_equal ["name", "age", "occupation"], my_table.headers
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

As you can see, taking a test driven approach allows us to do two things: focusing on small tasks and making sure that the code written is behaving as it should. Following TDD principles also enables us to write code that progressively takes us in the right direction without having to prematurely worry about the full set of requirements.