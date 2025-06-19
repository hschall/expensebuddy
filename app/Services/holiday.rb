# app/services/holiday.rb
class Holiday
  def self.business_day?(date)
    !weekend?(date) && !holiday?(date)
  end

  def self.weekend?(date)
    date.saturday? || date.sunday?
  end

  def self.holiday?(date)
    Holidays.on(date, :mx).any?
  end

  def self.adjust_to_business_day(date)
    while weekend?(date) || holiday?(date)
      date += 1
    end
    date
  end
end
