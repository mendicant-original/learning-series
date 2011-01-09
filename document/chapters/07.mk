07 Other Interesting Submissions
=================================

This  chapter is about other concerns and considerations when tackling this  problem. Eric G. for example tried to optimize memory usage, which is a valid concern when dealing with large data sets. He also had a unique idea regarding data storage.

Wojciech P. attempted to clearly separate concerns in an object oriented way. We will discuss the particulars of his solution a bit.

Eric G.'s Submission
---------------------

The complete code can be found at: https://github.com/ericgj/s1-final

From the data storage point of view, we've looked at the solution from Chapter 4, which simply stores an array of rows as provided by the user, and Lucas Efe's approach from the last chapter that has a collection of  Cell objects indexed by rows and columns. There are still other ways of storing the data that one could think of.

Eric's idea was to store the data as a single flattened array instead of sticking with a two-dimensional array. That entails that the data is not contained in  traditional "rows" or "columns", which in the previous two solutions used to be the internal arrays.  

If you stop and think about the  implications of using a flattened array for a moment,  you'll realize that quite a bit will have to change in the way rows and columns are appended, inserted, deleted or changed. 

A "row" therefore is a merely a virtual sequence in the array. It can be sliced out of the main array by calculating at which index it begins and ends at - calculations which are based on the row index and length. Similarly, a column would need to be assembled based on its calculated indices throughout the main array.

Here are some of Eric's thoughts on this way of storing the data:

  *The  path I took was initially motivated by two related issues of  encapsulation.  First of all, you're going to be doing operations on  both rows and columns which have some state in common with each other  and with the table as a whole.  If rows  and columns are basically  arrays, you immediately run into the problem  that state can't really be  shared between them.  If you slice columns out of rows, how are you  going to be able to "Run a transformation on a column which changes its  content based on the return value of a block" ?  You'd be changing the  sliced array elements but not the row array elements.* 
  
Of course this could be addressed by making the appropriate updates in the other storage option, but Eric was opposed to what he called "*a lot of messy double changes*". He continues:

  *That was one problem. The second issue was that even as it looked like you  need row, column, and column header arrays (or enumerables of some kind) to manipulate, you don't want to actually expose these as arrays with direct access to table data, because then you could easily corrupt the table.*
  
He also mentions a third and relatively serious concern:

  *The  other thing running through my mind when I started thinking about  the  problem was that the memory overhead should be kept as low as possible.   I know the Ruby community tends to downplay this kind of  concern up  front, but I think it's legitimate here given that we are already  loading an arbitrary sized file into memory.  That is -- you  have n  rows * m cols objects before you even talk about a Table class and  whatever else you need.* 

Mulling  over potential memory issues, he came up with a way to memoize or  "lazily load" rows and columns. Check out his ScopedCollection class to get a better picture:

 *Storing  everything in a single array made things like inserting and  deleting a  column quite complicated. I found myself wanting some variant of  Array#zip that inserts from one array into every nth element  of  another.  In the end, my col insert and delete methods end up rebuilding the entire table - not very efficient. On the other hand, having one array saves memory compared to an array of arrays,   particularly for large numbers of rows.*

In retrospect, though, he voiced some doubts regarding his initial choice of storage, the flattened array.

  *Storing  everything in a single array made things like inserting and  deleting a  column quite complicated. I found myself wanting some variant of  Array#zip that inserts from one array into every nth element  of  another.  In the end, my col insert and delete methods end up rebuilding the entire table - not very efficient. On the other hand, having one array saves memory compared to an array of arrays,   particularly for large numbers of rows.*

This is how he would change things for future incarnations of the Table class:

  *It would be relatively easy to change to storing the data as an array of  arrays.  I would just have to re-implement the row/cell access and manipulation methods in Table -- there would be no changes needed to Row and Column and Cell classes. And the problem of sharing references  between row and column arrays would not come up,  since cells would  always access the same underlying element, whether they belong to a column or to a row.*

Wojciech Piekutowski's (W.P.) submission
----------------------------------------

The complete code can be found at: https://github.com/wpiekutowski/s1-final

What makes his solution interesting is the way the code is organized. W.P. identified five classes that together make up the functionality necessary to have a working Ruby table implementation. Besides the Table class, there are classes representing the collection of rows and columns (Table::RowsProxy and Table::ColumnsProxy), as well as a class for an individual row and an individual column (Table::Row and Table::Column). 

Here is an overview of the responsibility and and features of each:

**Table**:

* Accepts 2-dimensional arrays as input and assigns that data to an @matrix instance variable
* Has a #rows and #columns method that return the respective proxy objects
* doesn't actually manipulate the data in any way

    class Table
      # code omitted

      # Returns ColumnsProxy object capable of columns operations
      def columns
        @columns_proxy ||= Table::ColumnsProxy.new(@matrix, self)
      end

      # Returns RowsProxy object capable of rows operations
      def rows
        @rows_proxy ||= Table::RowsProxy.new(@matrix, self)
      end

    end

**Table::RowsProxy and Table::ColumnsProxy**:

* have an instance of @matrix, which holds the data and @table, their "parent" object
* include the Enumerable module
* take care of inserting and appending a new row or column
* index method (#[]) returns Table::Row or Table::Column object

**Table::Row and Table::Column**:

* references the table's @matrix and the collection of rows or columns @proxy
* also keeps track of its rows or columns @index within the @proxy collection
* Take care of operations within an individual row or column like:
  * mapping the row or column values
  * deleting the row or column
  * accessing row or column elements
  * renaming or accessing the column name
  
You might have noticed that all classes have a reference to the same instance variable @matrix that is initialized in the Table class and which is basically the equivalent to @rows in the first solution. So one could say that the data is essentially stored in a 2-dimensional array representing the rows. That same instance variable is manipulated by all classes. In fact, even the classes representing a single column or row have a reference and manipulate it.

In that sense there are some striking similarities between this solution and the one we introduced as the first approach. View for example how you would change the values of all cells in a particular column:

This is the API of W.P.'s solution:

    table.columns['PROCEDURE_DATE'].map! do |date|
      parse_date(date).to_s
    end

And this is the equivalent method class in the first, single-class solution:

    table.transform_columns("PROCEDURE_DATE") do |col|
      parse_date(col).to_s
    end

And now to the implementation details. As a reminder, here is how we accomplished this in the first solution:

    class Table

      def transform_columns(pos, &block)
        pos = column_index(pos)
        @rows.each do |row|
          row[pos] = yield row[pos]
        end
      end

    end

This is how W.P.'s classes work together to accomplish the same:

    class Table

      def columns
        @columns_proxy ||= Table::ColumnsProxy.new(@matrix, self)
      end

    end

    class Table::ColumsProxy

      def [](column)
        index = position_to_index(column)
        return unless index

        Table::Column.new(@matrix, self, index)
      end

    end

    class Table::Column

      def map!
        @matrix.each do |row|
          row[@index] = yield(row[@index])
        end
      end

    end

The solutions are very similar in that they both iterate through the row data and yield the element at the column index to an arbitrary block. However, the API that W.P.'s solution exposes is in some ways cleaner and more attractive. To be able to write table.columns["some_col"].map! &block is much more familiar than table.transform_columns["some_col"] &block.

A noteworthy feature of the code is including the Enumerable module in the proxy objects. By overriding the each() method in the classes that include Enumerable, we essentially (re)define what we consider to be the unit that we would like to be handled by iterator methods. This is an incredibly powerful feature, since many other methods, that rely on the particular implementation of each() in the background (e.g. select(), map() and inject()), will automatically work as expected. 

page_break

<h6 title="The PracticingRubyQuote">
From [Practicing Ruby] Issue #9: Uses For Modules, Part 2 of 4 by Gregory Brown:

(....), there is surprising power in having a primitive built into your programming language which trivializes the implementation of the Template Method design pattern.  If you look at Ruby's Enumerable module and the powerful features it offers, you might think it would be a much more complicated example to study.  But it too hinges on Template Method and requires only an each() method to give you all sorts of complex functionality including things like select(), map(), and inject(). If you haven't tried it before, you should certainly try to roll your own Enumerable module to get a sense of just how useful mixins can be.
</h6>
