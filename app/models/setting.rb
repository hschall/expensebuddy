class Setting < ApplicationRecord
	belongs_to :user
	validates :cycle_end_day, presence: true


  def self.payment_due_date_for(cycle_end_date)
    raw_due = cycle_end_date + 13
    adjusted_due = Holiday.adjust_to_business_day(raw_due)
    adjusted_due
  end
end

