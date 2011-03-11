# encoding: utf-8

class Table
  
  NoRowError = Class.new(StandardError)
  NoColumnError = Class.new(StandardError)
  
  attr_reader :rows, :headers, :header_support
  def initialize(data = [], options = {})
    check_type(data)
    data.each do |row|
      check_type(row)
      check_length(row, data.first.length, "Inconsistent rows length")
    end
    
    @header_support = options[:headers] 
    
    @rows = Marshal.load(Marshal.dump(data))
    set_headers(@rows.shift) if @header_support
  end
  
  def set_headers(header_names)
    @headers = {}
    header_names.each_with_index do |item, index|
      @headers[item] = index
    end
  end

  def column_index(pos)
    pos = @headers[pos] || pos
    check_column_index(pos)
    pos
  end

  def [](row, col)
    check_row_index(row)
    col = column_index(col)
    rows[row][col]
  end
  
  def max_x
    @rows.length
  end

  def max_y
    rows.first and rows.first.length
  end
  
  def check_row_index(pos)
    unless (-max_x..max_x).include?(pos)
      raise NoRowError, "The row index is out of range"
    end
  end

  # Row Manipulations

  def add_row(new_row, pos=nil)
    check_type(new_row)
    check_length(new_row, max_y, "Inconsistent row length") unless @rows.empty?
    
    i = pos.nil? ? max_x : pos
    rows.insert(i, Marshal.load(Marshal.dump(new_row)))
  end

  def row(i)
    rows[i]
  end

  def delete_row(pos)
    @rows.delete_at(pos)
  end

  def transform_row(pos, &block)
    @rows[pos].map!(&block)
  end

  def select_rows(&block)
    @rows.select!(&block)
  end

  # Column Manipulations

  def column(pos)
    i = column_index(pos)
    @rows.map { |row| row[i] }
  end

  def rename_column(old_name, new_name)
    check_header_names(new_name)
    @headers[new_name] = @headers[old_name]
    @headers.delete(old_name)
  end

  def add_column(col, pos=nil)
    check_type(col)
    check_length(col, max_x+1, "Inconsistent column length")
    
    col = Marshal.load(Marshal.dump(col))
    
    i = pos.nil? ? rows.first.length : pos
    
    if header_support
      header_name = col.shift
      check_header_names(header_name)
      @headers.each { |k,v| @headers[k] += 1 if v >= i }
      @headers[header_name]  = i
    end
    
    @rows.each do |row|
      row.insert(i, col.shift)
    end
  end

  def delete_column(pos)
    pos = column_index(pos)
    
    if header_support
      header_name = @headers.key(pos)
      @headers.each { |k,v| @headers[k] -= 1 if v > pos }
      @headers.delete(header_name)
    end
    
    @rows.map {|row| row.delete_at(pos) }
  end

  def transform_columns(pos, &block)
    pos = column_index(pos)
    @rows.each do |row|
      row[pos] = yield row[pos]
    end
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
  
  private
    def check_header_names(name)
      raise ArgumentError, "Name already taken" if @headers[name]
    end
    
    def check_column_index(pos)
      unless (-max_y..max_y).include?(pos)
        raise NoColumnError,
              "The column does not exist or the index is out of range"
      end
    end
    
    def check_type(data)
      raise(ArgumentError, "Input is not an array") unless Array === data
    end

    def check_length(data, expected, msg="Input length is inconsistent")
      raise(ArgumentError, msg) unless data.length == expected
    end
end
