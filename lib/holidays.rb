class Holiday
  def self.adjust_to_business_day(date)
    while date.saturday? || date.sunday? || Holidays.on(date, :mx).any?
      date += 1.day
    end
    date
  end
end
