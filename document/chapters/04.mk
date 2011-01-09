04 Column Manipulations
=======================

By modeling the table data as a two-dimensional array, we were able to easily access and manipulate rows using common Array methods . However, as we shall see now that we turn our attention to implementing column functionality, this "row-centric" representation is not without limitation. For example to retrieving the contents of a particular column, would require iterating through each row, extracting each data cell of that column and map it into a new array. 

At this point you might be tempted to use a convenient array method, such as Array#transpose to temporarily remap the rows as columns. Here is a quick demonstration of what this method accomplishes:

    >> @simple_data.transpose
    => [["name", "Tom", "Beth", "George", "Laura", "Marilyn"],
        ["age", 32, 12, 45, 23, 84],
        ["occupation", "engineer", "student", "photographer", "aviator", "retiree"]]
      
This would allow us to essentially duplicate all the row methods, re-purposed for column manipulation. So what exactly are the disadvantages of using #transpose? The most obvious is that it creates a new array, so it effectively doubles the data held in memory. Suppose you want to use tranpose to easily insert a column. Something like:

    def insert_column(pos)
      columns = @rows.transpose
      columns.insert_at(pos)
      @rows = columns.transpose
    end

As you can see in the code above, we have to use transpose twice, once to map the rows to columns and a second time to update the rows. Extra steps and processing time are required.

Another, less obvious drawback is that transpose is quite picky about its input. Consider the following:

    >> table = [[1, 2, 3], [4,  5], [6]]    # rows with different lengths 
    >> table.transpose
    => IndexError: element size differs (2 should be 3)

Now that we have seen that there is no shortcut to remapping the rows to columns, we have two choices: resign ourselves to extract columns from rows as needed or re-think the entire approach to this problem altogether. We'll continue exploring the code for the first option now and afterwards look at alternate design patterns for table representation.

So here then is test that demonstrates retrieving a column (both by name and index):

    test "can access a column by its name" do
      assert_equal ["Tom", "Beth", "George", "Laura", "Marilyn"],   @simple_table.column("name")
    end
    
    test "can access a column by its index" do
      assert_equal ["Tom", "Beth", "George", "Laura", "Marilyn"],   @simple_table.column(0)
    end

To implement this we map the rows by the index of the column in question:

    class Table
    
      def column_index(pos)
          i = headers.index(pos)
          i.nil? ? pos : i
      end
  
      def column(pos)
        i = column_index(pos)
        @rows.map {|row| row[i] }
      end
    end 
 
Since we have already implemented column names and are saving a reference to them in a separate variable - @headers -, adding support for renaming a column simply requires replacing one item in the @headers array:
 
    test "can rename a column" do
      @simple_table.rename_column("name", "first name")
      assert_equal ["first name", "age", "occupation"], @simple_table.headers
    end

    
    class Table

      def rename_column(old_name, new_name)
        i = @headers.index(old_name)
        @headers[i] = new_name
      end
    end
 
As with rows, we want to be able to expand our data set by appending or inserting a new column. We will implement adding a column similarly to the equivalent row method. Again we want to support a position argument for insertion and a default behavior of appending the column at the end. However, we have to remember to take into account the column names along with the fact that they are optional.
 
    test "can append a column" do
      to_append = ["location", "Italy", "Mexico", "USA", "Finland", "China"]
      @simple_table.add_column(to_append)
      assert_equal ["name", "age", "occupation", "location"], @simple_table.headers
      assert_equal 4, @simple_table.rows.first.length
    end
    
    test "can insert a column at any position" do
      to_append = ["last name", "Brown", "Crimson", "Denim", "Ecru", "Fawn"]
      @simple_table.add_column(to_append, 1)
      assert_equal ["name", "last name", "age", "occupation"], @simple_table.headers
      assert_equal "Brown", @simple_table[0,1]
    end
    
The #add_column method needs to know whether headers are being used or not. As such, we store that option in a boolean variable, @header_support. Of course this is a matter of taste. We could just as easily have checked whether @headers is empty.
    
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
          headers.insert(i, col.shift)
        end
        @rows.each do |row|
          row.insert(i, col.shift)
        end
      end
    end


A similar procedure is needed for deleting a column, namely deleting the column item in each row.

    test "can delete a column from any position" do
      @simple_table.delete_column(1)
      assert_equal ["name", "occupation"], @simple_table.headers
      assert_equal ["Tom", "engineer"], @simple_table.row(0)
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

Finally, we want to be able to transform the values of a column one by one. For example we would like to "age" everyone in our table by five years.

    test "can run a transformation on a column which changes its content" do
      expected_ages = @simple_table.column("age").map {|a| a+= 5 }
      @simple_table.transform_columns("age") do |col|
        col += 5
      end
      assert_equal expected_ages, @simple_table.column("age")
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

Last but not least, we also want to filter out columns that don't meet a particular condition. As a somewhat contrived example, we want to select only columns that have numeric data:

    test "can select columns by some criteria" do
      @simple_table.select_columns do |col|
        col.all? {|c| Numeric === c } 
      end
      assert_equal 1, @simple_table.row(0).length
      assert_equal ["age"], @simple_table.headers
    end
  
Given our current, row-biased approach there is simply no easy way of doing this. We have to temporarily create each column and check it against the condition defined in the block sent to the select_columns() method. Since we expect the block to return true or false we can take that as an indication for whether we should delete or keep the column, the execution of which we will delegate to the existing delete_column() method.      
    
    class Table

      def max_y
        rows[0].length
      end

      def select_columns
        selected = []
        (0..(max_y - 1)).each do |i|
          col = @rows.map {|row| row[i] }
          delete_column(i) unless yield col
        end
      end
    end
