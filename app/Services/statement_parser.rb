require "roo"

class StatementParser
  def initialize(file, user)
    @file = file
    @user = user
  end

  def parse
    Rails.logger.info "🔍 File class: #{@file.class}"
    Rails.logger.info "🔍 File responds to path? #{@file.respond_to?(:path)}"
    Rails.logger.info "🔍 File path: #{@file.path if @file.respond_to?(:path)}"
    Rails.logger.info "🔍 File original_filename: #{@file.original_filename if @file.respond_to?(:original_filename)}"

    begin
      file_path = @file.respond_to?(:tempfile) ? @file.tempfile.path : @file.path
      extension = File.extname(@file.original_filename).delete(".").downcase.to_sym

      Rails.logger.info "📂 Parsing file: #{@file.original_filename}, content_type: #{@file.content_type}, path: #{file_path}"
      spreadsheet = Roo::Spreadsheet.open(file_path, extension: extension)
      sheet = spreadsheet.sheet(0)
    rescue => e
      Rails.logger.error "❌ Roo open failed: #{e.class} - #{e.message}"
      raise e
    end

    transactions = []
    balance_payments = []

    # Step 1: Find header row dynamically
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

      fecha_de_compra = row[header_keys[:fecha_de_compra]]
      fecha_col1 = row[header_keys[:fecha_col1]]
      descripcion = row[header_keys[:descripcion]].to_s
      record_date = descripcion.downcase.include?("gracias por su pago en") ? fecha_col1 : fecha_de_compra
      next if record_date.blank?

      cycle_month_str = cycle_month_for_date(record_date)
      company_code = extract_company_code(row[header_keys[:info_adicional]])

      record = {
        date: record_date,
        description: descripcion,
        person: row[header_keys[:titular]],
        amount: row[header_keys[:importe]],
        company_code: company_code,
        country: row[header_keys[:pais]],
        cycle_month: cycle_month_str
      }

      if record[:amount].to_f < 0 && balance_payment_window?(record_date)
        record[:category] = descripcion.downcase.include?("gracias por su pago en") ? "Pago de saldo" : "Reembolso"
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

    parsed = date.is_a?(Date) || date.is_a?(Time) ? date : safe_parse_date(date)
    return nil unless parsed

    day = parsed.day
    cycle_end_day = @user.setting&.cycle_end_day
    return nil unless cycle_end_day

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
    first_part =~ /(RFC\w+)/ ? $1 : nil
  end

  def balance_payment_window?(date)
    return false if date.blank?

    parsed_date = Date.parse(date.to_s) rescue nil
    return false unless parsed_date

    cycle_end_day = @user.setting&.cycle_end_day
    raise "Falta configurar el día de corte de tarjeta." unless cycle_end_day

    reference_month = parsed_date.day > cycle_end_day ? parsed_date.month : (parsed_date - 1.month).month
    cycle_end_date = Date.new(parsed_date.year, reference_month, cycle_end_day) rescue nil
    return false unless cycle_end_date

    due_date = @user.setting.payment_due_date_for(cycle_end_date)
    parsed_date.between?(cycle_end_date, due_date)
  end
end
