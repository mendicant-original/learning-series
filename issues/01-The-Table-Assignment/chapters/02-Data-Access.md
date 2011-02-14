
The way things stand now, the Table class is siphoning off our first row as the column headers no matter what:

    >> table = Table.new [[1, 2, 3], [4,5,6]]
    >> table.rows[0]
    => [4,5,6]

    >> table.headers
    => [1,2,3]

While we want to allow for column names to be set, that feature should be optional. We need to make that feature configurable. In this case we need to edit a previous test:

    test "can be initialized with a two-dimensional array" do
      table = Table.new(@data)
      assert_equal @data, table.rows
      assert_equal [],    table.headers
    end

    test "first row considered column names, if indicated" do
      table = Table.new(@data.dup, :headers => true)
      assert_equal @data[1..-1], table.rows
      assert_equal @data[0],     table.headers
    end


    class Table
      attr_reader :rows, :headers

      def initialize(data = [], options = {})
        @headers = options[:headers] ? data.shift : []
        @rows = data
      end

      def add_row(row)
        @rows << row
      end
    end

Optimally, we would like the API to be able to access the columns either by name or by index, so that we can for instance retrieve the data by asking for "the 'name' field in the second row" or "the first column in the second row".

This is what the tests and implementation for this feature could look like:

    test "cell can be referred to by column name and row index" do
      table = Table.new(@data, :headers => true)
      assert_equal "Beth", table[1, "name"]
    end

    test "cell can be referred to by column index and row index" do
      table = Table.new(@data, :headers => true)
      assert_equal "Beth", table[1, 0]
    end


    class Table
      attr_reader :rows, :headers

      def initialize(data = [], options = {})
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

We've covered the simple requirements by now as we're able to properly initialize a table and to access individual cells. In the next chapter we start to implement some of the tricky ones.
