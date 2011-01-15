02 Data Access
==============

The way things stand now, the Table class is siphoning off our first row as the column headers no matter what:

    >> my _table = Table.new [[1, 2, 3], [4,5,6]]
    >> my_table.rows[0]
    => [4,5,6]

    >> my_table.headers
    => [1,2,3]

While we want to allow for column names to be set, that feature should be optional. We need to make that feature configurable. In this case we need to edit a previous test:

    test "can be initialized with a two-dimensional array" do
      my_table = Table.new(@simple_data)
      assert_equal @simple_data, my_table.rows
      assert_equal [], my_table.headers
    end

    test "first row considered column names, if indicated" do
      my_table =  Table.new(@simple_data, :headers => true)
      assert_equal @simple_data[1..-1], my_table.rows
      assert_equal @simple_data[0], my_table.headers
    end


    class Table
      attr_reader :rows, :headers

      def  initialize(data = [], options = {})
        @headers = options[:headers] ? data.shift : []
        @rows = data
      end

      def add_row(row)
        @rows << row
      end
    end

Optimally, we would like the API to be able to access the columns either by name or by index, so that we can for instance retrieve the data by asking for "the 'name' field in the third row" or "the first column in the third row".

This is what a test for this feature could look like:

    test "cell can be referred to by column name and row index" do
      my_table = Table.new(@simple_data, :headers => true)
      assert_equal "Beth", my_table[1,"name"]
    end

    test "cell can be referred to by column index and row index" do
      my_table = Table.new(@simple_data, :headers => true)
      assert_equal "Beth", my_table[1, 0]
    end


    class Table
      attr_reader :rows, :headers

      def  initialize(data = [], options = {})
        @headers = options[:headers] ? data.shift : []
        @rows = data
      end

      def [](row, col)
        col = column_index(col)
        rows[row][col]
      end

      def column_index(pos)
        i = headers.index(pos)
        i.nil? ? pos : i
      end

      def add_row(row)
        @rows << row
      end
    end
