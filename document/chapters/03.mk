03 Row Manipulations
====================

We have already set up a method to retrieve the collection of rows. We can also append a new row at the end (see the add_row() method in Chapter One). But what if we want to insert a new row in a particular position and not at the end? 

    context "row manipulations" do
      setup do
        @simple_table = Table.new(@simple_data, :headers => true)
      end

      test "can insert a row at any position" do
        @simple_table.add_row(["Jane", 19, "shop assistant"], 2)
        assert_equal ["Jane", 19, "shop assistant"], @simple_table.row(2)
      end
    end  
 
Instead of creating a brand new method for inserting a row at a particular position, we simply change the existing add_row() method to take an optional second argument representing the position where the new row should be inserted. If we don't send in a position, the new row will be appended at the end by default.
 
    class Table
    
      def add_row(new_row, pos=nil)
          i = pos.nil? ? rows.length : pos
          rows.insert(i, new_row)
      end
    end   

Now we want to be able to retrieve a single row in order to delete it or to transform its values. Here is a failing test to retrieve the contents of a particular row:

    context "row manipulations" do
      setup do
        @simple_table = Table.new(@simple_data, :headers => true)
      end

      test "should be able to retrieve a row" do
        assert_equal ["George", 45,"photographer"], @simple_table.row(2)
      end
    end     

       
    class Table
    
      def row(i)
        rows[i]
      end
    end

To delete a particular row from our table, we set up our test to check that a deleted row has actually been replaced:

    test "should be able to delete a row" do
      to_be_deleted = @simple_table.row(2)
      @simple_table.delete_row(2)  
      assert_not_equal to_be_deleted, @simple_table.row(2)
    end


    class Table
    
      def delete_row(pos)   
        @rows.delete_at(pos)
      end
    end

Next we need to write a method to triggers a row-level transformation that affects all data cells of that row in a user-defined way. In other words, we have to design our API in such a way it can accept the transformation code as an argument. This is where blocks come into play.

    test "should update the transformed row cells" do
      @simple_table.transform_row(0) do |cell| 
        cell.is_a?(String) ? cell.upcase : cell
      end
      
      assert_equal "TOM", @simple_table[0,"name"]
    end


    class Table
    
      def transform_row(pos, &block)
        @rows[pos].map!(&block)
      end
    end

Here we take advantage of the Array#map! method which natively accepts a block as an argument and delegate the heavy lifting over to it.

There are other use cases where the API would need to respond to user-defined blocks. Say we want to reduce our table data to only contain records of people under 30. That would mean that we'd have to check every row for that condition (age under 30) and only keep those rows that pass the condition. 

    test "reduce the rows to those that meet a particular conditon" do
      @simple_table.select_rows do |row|
        row[1] < 30
      end
      assert  !@simple_table.rows.include?(["George", 45,"photographer"])
    end

Again, there's a handy Array method to accomplish this, namely Array#select!

    class Table
    
      def select_rows(&block)
        @rows.select!(&block)
      end
    end