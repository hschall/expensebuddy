class Setting < ApplicationRecord
	belongs_to :user
	validates :cycle_end_day, presence: true


  def payment_due_date_for(cycle_end_date)
  adjusted_due_date = cycle_end_date + 13.days

  while adjusted_due_date.saturday? || adjusted_due_date.sunday? || Holidays.on(adjusted_due_date, :mx).any?
    adjusted_due_date += 1.day
  end

  adjusted_due_date
end

end

