require "google_drive"

session = GoogleDrive::Session.from_config("config.json")
$ws = session.spreadsheet_by_key("1Ap9Z_GFctqPeueD39k-cbnxRwJRJjh5UMQMZUut9Utg").worksheets[0]

class Tabelica
  include Enumerable
  attr_accessor :table_values, :headers

  def initialize
    @worksheet = $ws
    @table_values = @worksheet.rows.map { |row| row.map(&:dup) }
    @headers = @table_values.shift if @table_values&.any?
  end

  def row(index)
    numeric_index = index.to_i
    row_to_update = @table_values[numeric_index - 1].dup if numeric_index.between?(1, @table_values.length)
    row_to_update
  end

  def [](index)
    row(index)
  end

  def column(name)
    col_index = @headers.index { |header| header.downcase == name.downcase }
    if col_index.nil?
      puts "Column '#{name}' not found."
      return []
    end
    @table_values.map { |row| row[col_index] }
  end

  def []=(index, header_index, value)
    @worksheet[index + 1, header_index + 1] = value
    @table_values[index][header_index] = value
  end

  def kolona(naziv_kolone)
    column(naziv_kolone)
  end

  def subtotal_kolone(naziv_kolone)
    col = column(naziv_kolone)
    return 0 unless col
    col.compact.map(&:to_i).sum
  end

  def average_kolone(naziv_kolone)
    col = column(naziv_kolone)
    if col.nil?
      puts "Column '#{naziv_kolone}' is nil."
      return 0
    end
    col_sum = col.map(&:to_i).sum
    col_length = col.length.to_f
    if col_length.zero?
      puts "Column '#{naziv_kolone}' has zero length."
      return 0
    end
    col_sum / col_length
  end

  def red_za_vrednost_kolone(naziv_kolone, vrednost)
    col = column(naziv_kolone)
    if col.nil?
      puts "Column '#{naziv_kolone}' is nil."
      return nil
    end
    index = col.index(vrednost)
    return nil unless index
    @table_values[index]
  end

  def map_kolone(naziv_kolone, &block)
    col = column(naziv_kolone)
    if col.nil?
      puts "Column '#{naziv_kolone}' is nil."
      return []
    end
    col.map(&block)
  end

  def select_kolone(naziv_kolone, &block)
    col = column(naziv_kolone)
    if col.nil?
      puts "Column '#{naziv_kolone}' is nil."
      return []
    end
    col.select(&block)
  end

  def reduce_kolone(naziv_kolone, initial, &block)
    col = column(naziv_kolone)
    col.reduce(initial, &block)
  end

  def print_table
    puts "Headers: #{@headers}"
    @table_values.each { |row| puts "Row: #{row}" }
  end

  def ignore_total_rows
    @table_values.reject! { |row| row.any? { |cell| cell.to_s.downcase.include?('total') || cell.to_s.downcase.include?('subtotal') } }
  end

  def self.add_tables(table1, table2)
    if table1.headers == table2.headers
      new_table = Tabelica.new
      new_table.headers = table1.headers
      new_table.table_values = table1.table_values + table2.table_values
      new_table
    else
      puts "Tables have different headers and cannot be added."
      nil
    end
  end

  def self.subtract_tables(table1, table2)
    if table1.headers == table2.headers
      new_table = Tabelica.new
      new_table.headers = table1.headers
      new_table.table_values = table1.table_values - table2.table_values
      new_table
    else
      puts "Tables have different headers and cannot be subtracted."
      nil
    end
  end

  def empty_rows
    @table_values.select { |row| row.all?(&:nil?) }
  end
end

def main
  my_table = Tabelica.new
  my_table.print_table

  puts "Row 1: #{my_table.row(1)}"
  puts "Element at position 1,2: #{my_table[1][2]}"
  puts "Column 'Prva kolona': #{my_table.column('Prva kolona')}"

  my_table[1, 2] = 2556
  puts "Updated value at position 1 in 'Prva kolona': #{my_table[1][2]}"

  puts my_table.kolona('Prva kolona')
  puts my_table.kolona('Druga kolona')

  puts my_table.subtotal_kolone('Prva kolona')
  puts my_table.average_kolone('Prva kolona')

  puts my_table.red_za_vrednost_kolone('Indeks', 'rn2310')

  puts my_table.map_kolone('Prva kolona') { |cell| cell.to_i + 1 }

  puts my_table.select_kolone('Prva kolona') { |cell| cell.to_i > 10 }
  puts my_table.reduce_kolone('Prva kolona', 0) { |sum, cell| sum + cell.to_i }

  # Dodajemo pozive novih funkcionalnosti
  my_table.ignore_total_rows
  puts "Empty Rows: #{my_table.empty_rows}"

  # Primer sabiranja tabela
  table1 = Tabelica.new
  table2 = Tabelica.new

  # Dodajte podatke u tabelu1 i tabelu2 pre nego što ih sabirate...

  result_table = Tabelica.add_tables(table1, table2)

  if result_table
    puts "Result Table After Addition:"
    result_table.print_table
  end

  # Primer oduzimanja tabela
  result_subtraction_table = Tabelica.subtract_tables(table1, table2)

  if result_subtraction_table
    puts "Result Table After Subtraction:"
    result_subtraction_table.print_table
  end
end

main