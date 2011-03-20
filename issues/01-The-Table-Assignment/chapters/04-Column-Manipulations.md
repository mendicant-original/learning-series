
By modeling the table data as a two-dimensional array, we were able to easily access and manipulate rows using common Array methods. However, as we turn our attention to column functionality, we shall see that this "row-centric" representation is not without cost. For example, retrieving the contents of a particular column would necessitate iterating through each row, extracting the data cell of that column and then mapping it to a new array. 

To this effect, one might be tempted to use a convenient array method, such as Array#transpose to temporarily remap the rows as columns. Here is a quick demonstration of what this method accomplishes:

    >> @data.transpose
    => [["name", "Tom", "Beth", "George", "Laura", "Marilyn"],
        ["age", 32, 12, 45, 23, 84],
        ["occupation", "engineer", "student", "photographer", "aviator", "retiree"]]
      
This would allow us to essentially duplicate all the row methods, re-purposed for column manipulation. But herein lies the rub. Transposing the data in this fashion necessitates the creation a new array, effectively doubling the data held in memory. Consider for example the use of tranpose() to conveniently insert a column. Something like:

    def insert_column(pos)
      columns = @rows.transpose
      columns.insert_at(pos)
      @rows = columns.transpose
    end

As you can see from the code above, we have to use transpose() twice, once to map the rows to columns and a second time to update the rows. Extra steps and processing time are required.

Another, less obvious drawback is that transpose is quite picky about its input. Consider the following:

    >> table = [[1, 2, 3], [4,  5], [6]] # rows with different lengths 
    >> table.transpose
    => IndexError: element size differs (2 should be 3)

Now that we have seen that there is viable alternative to remapping the rows to columns, we have two choices: resign ourselves to extract columns from rows as needed or re-think the entire approach to this problem altogether. We'll continue exploring the code for the first option now and afterwards look at alternate design patterns for table representation.

Here then is test that demonstrates retrieving a column (both by name and index):

    # We will omit this context declaration for the remainder of the chapter
    context "column manipulations" do
      setup do
        @table = Table.new(@data, :headers => true)
      end
    
      test "can access a column by its name" do
        assert_equal ["Tom", "Beth", "George", "Laura", "Marilyn"],
                     @table.column("name")
      end
    
      test "can access a column by its index" do
        assert_equal ["Tom", "Beth", "George", "Laura", "Marilyn"],
                     @table.column(0)
      end
    end

To implement this, we map the rows by the index of the column in question:

    class Table
    
      def column_index(pos)
        i = @headers.index(pos)
        i.nil? ? pos : i
      end
  
      def column(pos)
        i = column_index(pos)
        @rows.map { |row| row[i] }
      end
    end 
 
Since we have already implemented column names and are saving a reference to them in a separate variable - @headers -, adding support for renaming a column simply requires replacing one item in the @headers array:
 
    test "can rename a column" do
      @table.rename_column("name", "first name")
      assert_equal ["first name", "age", "occupation"], @table.headers
    end

    
    class Table

      def rename_column(old_name, new_name)
        i = @headers.index(old_name)
        @headers[i] = new_name
      end
    end
 
As with rows, we want to be able to expand our data set by appending or inserting a new column. We will implement adding a column in similar fashion to the equivalent row method. Again, we want to support a position argument for insertion and a default behavior of appending the column at the end. However, we have to remember to take into account the column names along with the fact that they are optional.
 
    test "can append a column" do
      to_append = ["location", "Italy", "Mexico", "USA", "Finland", "China"]
      @table.add_column(to_append)
      assert_equal ["name", "age", "occupation", "location"], @table.headers
      assert_equal 4, @table.rows.first.length
    end
    
    test "can insert a column at any position" do
      to_append = ["last name", "Brown", "Crimson", "Denim", "Ecru", "Fawn"]
      @table.add_column(to_append, 1)
      assert_equal ["name", "last name", "age", "occupation"], @table.headers
      assert_equal "Brown", @table[0,1]
    end
    
The add\_column() method needs to know whether headers are being used or not. As such, we store that option in a boolean variable, @header_support. Of course this is a matter of taste. We could just as easily have checked whether the @headers array is empty.
    
    class Table
      attr_reader :rows, :headers, :header_support
      
      def initialize(data = [], options = {})
        @header_support = options[:headers]
        @headers = @header_support ? data.shift : []
        @rows = data
      end

      def add_column(col, pos=nil)
        i = pos.nil? ? rows.first.length : pos
        if header_support
          @headers.insert(i, col.shift)
        end
        @rows.each do |row|
          row.insert(i, col.shift)
        end
      end
    end


A similar procedure is needed for deleting a column. That is, in each row we need to delete the item belonging to that column.

    test "can delete a column from any position" do
      @table.delete_column(1)
      assert_equal ["name", "occupation"], @table.headers
      assert_equal ["Tom", "engineer"],    @table.row(0)
    end


    class  Table

      def delete_column(pos)
        pos = column_index(pos)
        if header_support
          @headers.delete_at(pos)
        end
        @rows.map {|row| row.delete_at(pos) }
      end
    end

Finally, we want to be able to transform the values of a column one by one. For example, we would like to "age" everyone in our table by five years.

    test "can run a transformation on a column which changes its content" do
      expected_ages = @table.column("age").map {|a| a+= 5 }
      @table.transform_columns("age") do |col|
        col += 5
      end
      assert_equal expected_ages, @table.column("age")
    end
 
In this case we are yielding each cell in the column to the block defined by the user of the API.
    
    class Table
  
      def transform_columns(pos, &block)
        pos = column_index(pos)
        @rows.each do |row|
          row[pos] = yield row[pos]
        end
      end
    end

Last but not least, we need to filter out columns that don't meet a particular condition. As a somewhat contrived example, let's select only those items for which the column sum is lower than 10:

    test "can select columns by some criteria" do
      table = Table.new([["item1", "item2", "item3", "item4", "item5"],
                         [3, 7, 4, 9, 2],
                         [4, 8, 2, 3, 1],
                         [0, 9, 3, 4, 6]
                         ],
                        :headers => true)
    
      table.select_columns do |col|
        col.inject(0, &:+) < 10
      end
    
      assert_equal 3, table.rows[0].length
      assert_equal(["item1", "item3", "item5"], table.headers)
    end
  
Given our current, row-biased approach there is simply no easy way to do this. We have to temporarily create each column and check it against the condition defined in the block sent to the select\_columns() method. Since we expect the block to return true or false, we can use that to determine whether we should keep or delete the column. The execution of the latter we will delegate to the existing delete_column() method.
    
    class Table

      def max_y
        rows[0].length
      end

      def select_columns
        selected = []

        (0...max_y).each do |i|
          col = @rows.map { |row| row[i] }
          selected.unshift(i) unless yield col
        end

        selected.each do |pos|
          delete_column(pos)
        end
      end
    end

We've completed all the requirements for the assignment and you may find this simple implementation complete with tests [here](https://github.com/rmu/learning-series/tree/master/issues/01-The-Table-Assignment/source).

This implementation is somewhat similar to that submitted by the majority of students in this session but it's not without its weaknesses. These drawbacks are the subject of the next chapter.
