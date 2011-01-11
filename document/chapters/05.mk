05 Handling Exceptions and Bad Input
======================

In a perfect world, we could probably be done at this point. However, we have so far completely ignored an important aspect, namely dealing with potential errors.

We start with mimicking errors that could occur when accessing table data if non-existent rows or columns are being referenced. We could call them "out of bounds" errors. Consider the following scenario:

    >> @data = [[1,2,3], [4,5,6]]
    >> my_table = Table.new(@data)
    >> my_table[99, 99]
    => NoMethodError: undefined method `[]' for nil:NilClass

As a reminder, here is the code that is for now unprepared to handle such a case:

    class Table

      def [](row, col)
        col = column_index(col)
        rows[row][col]
      end
      
    end

If the referenced row is out of bounds (rows[row]) then nil gets returned. This is in itself something that you might want to handle with either an error or a warning (or else accept that nil gets returned in such cases). If we attempt to retrieve a particular column in that non-existent row, however, we have an unhandled NoMethodError on our hands.

A simple fix could involve checking the requested index before attempting to retrieve the cell. The code below also demonstrates setting up and using custom error classes.

    class Table
    
      NoRowError = Class.new(StandardError)

      def max_x
        @rows.length
      end

      def [](row, col)
        check_row_index
        col = column_index(col)
        rows[row][col]
      end

      def check_row_index
        raise NoRowError, "The row index is out of range" unless (-max_x..max_x).include?(pos) 
      end
    end

Column names
------------

Since columns can be referenced either by their index or by their name we could encounter nonexistent column names, as in:

    >> my_table[2, "bad_column"]
    => TypeError: can't convert String into Integer

Or what if we were to insert or rename a column using a name that is already taken:

    >> my_table.add_column(["age", 10, 11, 12, 13, 14])
    >> my_table.headers
    => ["name", "age", "occupation", "age"]
    >> my_table[2, "age"]
    => 45

    >> my_table.rename_column("name", "age")
    >> my_table.headers.inspect 
    => ["age", "age", "occupation", "age"]
    >> my_table[2, "age"]
    => George

To handle the case of referencing a column that doesn't exist, we can apply a similar strategy as for the rows. We can intercept the method that determines the numeric index of the column based on either a string or an integer. 

To avoid duplicate column names, we could just opt to check the @headers array when appropriate. There might however be a more elegant way of tackling this problem. Changing the internal representation of @headers from an array to a hash facilitates avoiding duplicate names, since hashes don't allow for duplicate keys.

Here then is the code to guard against both potential sources of error:

    class Table
 
      def initialize(data = [], options = {})
        @header_support = options[:headers] 
        set_headers(data.shift) if @header_support
        @rows = data
      end

      def set_headers(header_names)
        @headers = {}
        header_names.each_with_index do |item, index|
          @headers[item] = index
        end
      end

      def max_y
        rows[0].length
      end

      def column_index(pos)
        pos = @headers[pos] || pos
        check_column_index(pos)
        return pos
      end

      def rename_column(old_name, new_name)
        check_header_names(new_name)
        @headers[new_name] = @headers[old_name]
        @headers.delete(old_name)
      end

      def add_column(col, pos=nil)
        i = pos.nil? ? rows.first.length : pos
        if header_support
          header_name = col.shift
          check_header_names(header_name)
          headers[header_name]  = i
        end
        @rows.each do |row|
          row.insert(i, col.shift)
        end
      end
      
page_break

      def delete_column(pos)
        pos = column_index(pos)
        if header_support
          header_name = @headers.key(pos)
          @headers.delete(header_name)
        end
        @rows.map {|row| row.delete_at(pos) }
      end

    private

      def check_header_names(name)
        raise ArgumentError, "Name already taken" if @headers[name]
      end

      def check_column_index(pos)
        raise NoColumnError, "The column does not exist or the index is out of  range" unless (-max_y..max_y).include?(pos)
      end
   
    end

Handling bad input
-------------------

In a table we expect all rows to have the same length and also all columns to have the same number of elements. Here we will focus on input that does not conform to this basic expectation.

Generally speaking, there are two main courses of action in dealing with bad input: either to reject it by raising an error or adapt the input by bringing it somehow back into the fold. 

One way to change rows and columns so that they have the expected length might be to pad the short ones and truncate the ones that are too long. When it comes to rows, we might get away with this strategy, but padding short columns could have some undesired side effects. In tables with header support, for instance, we assume the first element to be the header name. Should the header not be included in the new column, then the padding approach will cause a missing header to "fail silently": the first element will be appointed as the header, while the last element will be supplied by padding. 

Truncating rows/columns that are too long leaves one with an uneasy feeling, even if the truncation is accompanied by a warning. 

Considering all these issues with truncation/padding, we will instead raise an exceptions upon encountering rows or columns with unexpected lengths.

    class Table

      def initialize(data = [], options = {})
        @header_support = options[:headers]
        check_seed_data_row_length(data)
        set_headers(data.shift) if @header_support
        @rows = data
      end

      def add_row(new_row, pos=nil)
        check_consistent_length(:row, new_row)
        i = pos.nil? ? rows.length : pos
        rows.insert(i, new_row)
      end
   
   
      def add_column(col, pos=nil)
        check_consistent_length(:column, col)
        i = pos.nil? ? rows.first.length : pos
        if header_support
          headers.insert(i, col.shift)
        end
          @rows.each do |row|
          row.insert(i, col.shift)
        end
      end

    private

      def check_consistent_length(type, array)
        case type
        when :row
          raise ArgumentError, "Inconsistent row length" unless array.length == rows.first.length
        when :column
          raise ArgumentError, "Inconsistent column length" unless array.length == @rows.length
        else
          raise ArgumentError, "Unknown type"
        end
      end

      def check_seed_data_row_length(data)  
        first_row_length = data.first.length   
        begin
          unless data.all? {|row| row.length == first_row_length }
            raise ArgumentError, "Inconsistent row length in seed data" 
          end
        rescue NoMethodError
          raise ArgumentError, "table should be a nested array"
        end
      end  

    end

Data corruption
---------------

The user of our API can at any time inadvertently corrupt the table data by tinkering with the seed data. Conversely, changes initiated through the table will also affect the seed data. 

The root of the issue is that in Ruby variables hold references to objects, not the objects themselves. So if the same object is referenced by different variables, we need to keep in mind that changes made to the object will be visible no matter which variable we chose to reference the object by. Here's a simple example to illustrate the point:

    >> person1 = "Tim"
    >> person2 = person1 
    >> person1[0] = 'J' 

    >> puts "person1 is #{person1}" 
    => person1 is Jim
    >> puts "person2 is #{person2}" 
    => person2 is Jim 

So, in our case, when we initialize a new Table we are setting the @rows variable to reference the same two-dimensional array as @simple_data does. Here you can see that when we remove the first array as headers, we are also altering @simple_data:

    >> @simple_data = [["name",  "age", "occupation"],
                       ["Tom", 32,"engineer"], 
                       ["Beth", 12,"student"], 
                       ["George", 45,"photographer"],
                       ["Laura", 23, "aviator"],
                       ["Marilyn", 84, "retiree"]]
    >> my_table = Table.new(@simple_data, :headers => true)
    >> @simple_data
    => [["Tom", 32,"engineer"], 
        ["Beth", 12,"student"], 
        ["George", 45,"photographer"],
        ["Laura", 23, "aviator"],
        ["Marilyn", 84, "retiree"]]
      
Here is another example of how altering the seed data will be reflected when we access the data through the Table instance:

    >> @simple_data = [["name",  "age", "occupation"],
                       ["Tom", 32,"engineer"], 
                       ["Beth", 12,"student"], 
                       ["George", 45,"photographer"],
                       ["Laura", 23, "aviator"],
                       ["Marilyn", 84, "retiree"]]
    >> my_table = Table.new(@simple_data, :headers => true)
    >> @simple_data[2][2] = "king of the world"
    >> my_table[2, 2]
    => "king of the world"

Let's say that to prevent accidental data corruption we want to somehow duplicate the seed data when we initialize the table. We might try to use Object#dup to accomplish this.

    class Table

      def initialize(data = [], options = {})
        # code omited
        @rows = data.dup
      end
      
    end

Simple, isn't it? Except that this doesn't solve our problem. The behavior from the previous example remains.

    >> my_table = Table.new(@simple_data, :headers => true)
    >> @simple_data[2][2] = "king of the world"
    >> my_table[2, 2]
    => "king of the world"

Let's examine the dup() method a little closer:

<h6 title="From the Pickaxe book: dup()">
dup()

Produces a shallow copy of obj — the instance variables of obj are copied, but not the objects they reference. dup copies the tainted state of obj. See also the discussion under Object#clone.

In general, dup duplicates just the state of an object, while clone also copies the state, any associated singleton class, and any internal ﬂags (such as whether the object is frozen). The taint status is copied by both dup and clone. 
</h6>

So if we dup() the seed data that's passed to our initialize method and before we assign it to Table#rows, the outer array that @rows points to is indeed a different object from the outer array held in @simple_data. However, Table#rows and @simple_data are still both referencing the same internal arrays, meaning the actual rows. To prove the point:

    >> my_table = Table.new(@simple_data, :headers => true)
    >> my_table.rows.object_id    # note that the output is run specific
    => 2151823700  
    >> @simple_data.object_id
    => 2151823780

    >> my_table.row(0).object_id
    => 2151825160
    >> @simple_data[0].object_id
    => 2151825160


The only really reliable way to create a brand new object when we assign it to another variable is marshaling. 

From the Pickaxe book: *[Marshaling] is the ability to serialize objects, letting you store them somewhere and reconstitute them when needed. [.....] 
Saving an object and some or all of its components is done using the method Marshal.dump. Typically, you will dump an entire object tree starting with some given object. Later, you can reconstitute the object using Marshal.load.*

    class Table

      def initialize(data = [], options = {})
        @header_support = options[:headers]
        check_seed_data_row_length(data)
        @rows = Marshal.load(Marshal.dump(data))
        set_headers(@rows.shift) if @header_support
      end
      
    end
 
Now there is no cross-reference between @simple_data and the table @rows. We can also say that the Table.new method is side effect free:

    >> my_table = Table.new(@simple_data, :headers => true)
    >> @simple_data[2][2] = "king of the world"
    >> my_table[2, 2]
    => "photographer"
    >> @simple_data[0]
    => ["name", "age", "occupation"]

Unfortunately this method is also not without drawbacks. Apart from the time that it takes to marshall and unmarshall the seed data, we are temporarily storing two copies of the same nested array.