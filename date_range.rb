module DateRange
  def week_range(date)
    first = date - (date.cwday - 1)
    last = first + 6
    first..last
  end

  def month_range(date)
    first = date - (date.mday - 1)
    last = date.next_month - date.next_month.mday
    first..last
  end
end
