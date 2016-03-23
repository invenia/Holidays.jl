from datetime import date
import holidays

us_holidays = holidays.UnitedStates()  # or holidays.US()

def get(julia_date):
    #~ return date(year, month, day) in us_holidays
    return us_holidays.get(julia_date)


