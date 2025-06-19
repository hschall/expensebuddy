require "roo"

class StatementParser
  def initialize(file)
    @file = file
  end

  def parse
  spreadsheet = Roo::Spreadsheet.open(@file.path, extension: :xlsx)
  sheet = spreadsheet.sheet(0)

  transactions = []
  balance_payments = []

  # Step 1: Find the header row dynamically
  header_row_index = nil
  header_keys = {}

  sheet.each_with_index do |row, i|
    next unless row.compact.any?

    if row.map(&:to_s).any? { |cell| cell.strip.downcase == "fecha" }
      header_row_index = i
      row.each_with_index do |cell, idx|
        case cell.to_s.strip
        when "Fecha de Compra" then header_keys[:fecha_de_compra] = idx
        when "Fecha" then header_keys[:fecha_col1] = idx
        when "Descripción" then header_keys[:descripcion] = idx
        when "Titular de la Tarjeta" then header_keys[:titular] = idx
        when "Importe" then header_keys[:importe] = idx
        when "Información Adicional" then header_keys[:info_adicional] = idx
        when "País" then header_keys[:pais] = idx
        end
      end
      break
    end
  end

  raise "Header row not found" unless header_row_index

  # Step 2: Loop through rows after the header
  ((header_row_index + 2)..sheet.last_row).each do |i|
    row = sheet.row(i)
    next if row.compact.empty?

    # Fetch fields using mapped indexes
    fecha_de_compra = row[header_keys[:fecha_de_compra]]
    fecha_col1 = row[header_keys[:fecha_col1]]
    descripcion = row[header_keys[:descripcion]].to_s
    record_date = descripcion.downcase.include?("gracias por su pago en") ? fecha_col1 : fecha_de_compra
    next if record_date.blank?

    cycle_month_str = cycle_month_for_date(record_date)
    record = {
      date: record_date,
      description: descripcion,
      person: row[header_keys[:titular]],
      amount: row[header_keys[:importe]],
      company_code: extract_company_code(row[header_keys[:info_adicional]]),
      country: row[header_keys[:pais]],
      cycle_month: cycle_month_str
    }

    if record[:amount].to_f < 0 && balance_payment_window?(record_date)
      if descripcion.downcase.include?("gracias por su pago en")
        record[:category] = "Pago de saldo"
      else
        record[:category] = "Reembolso"
      end
      balance_payments << record
    else
      transactions << record
    end
  end

  { transactions: transactions, balance_payments: balance_payments }
end







  private

  def safe_parse_date(value)
  Date.parse(value.to_s) rescue nil
end

  def cycle_month_for_date(date)
  return nil if date.blank?

  # If it's already a Date or Time object, skip parsing
  parsed = date.is_a?(Date) || date.is_a?(Time) ? date : safe_parse_date(date)
  return nil unless parsed

  day = parsed.day
  cycle_end_day = Setting.cycle_end_day

  if day > cycle_end_day
    safe_day = [cycle_end_day + 1, parsed.end_of_month.day].min
    cycle_start = parsed.change(day: safe_day)
  else
    previous_month = parsed - 1.month
    safe_day = [cycle_end_day + 1, previous_month.end_of_month.day].min
    cycle_start = previous_month.change(day: safe_day)
  end

  cycle_start.strftime("%Y-%m")
end


  def extract_company_code(info)
    return nil if info.blank?

    first_part = info.to_s.split("/").first.to_s.strip

    if first_part =~ /(RFC\w+)/
      $1
    else
      nil
    end
  end

  def balance_payment_window?(date)
  return false if date.blank?

  parsed_date = Date.parse(date.to_s) rescue nil
  return false unless parsed_date

  cycle_end_day = Setting.cycle_end_day
  # If the transaction date is after the cycle end, it's part of this month; else previous
  reference_month = parsed_date.day > cycle_end_day ? parsed_date.month : (parsed_date - 1.month).month
  cycle_end_date = Date.new(parsed_date.year, reference_month, cycle_end_day) rescue nil
  return false unless cycle_end_date

  due_date = Setting.payment_due_date_for(cycle_end_date)

  parsed_date.between?(cycle_end_date, due_date)
end



end
