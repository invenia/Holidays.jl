from datetime import date
import holidays

dates = None

def get(julia_date):
    #~ return date(year, month, day) in us_holidays
    return dates.get(julia_date)

def load(country, region):
    global dates

    if country == "US":
        dates = holidays.US(state=region)
    elif country == "CA":
        dates = holidays.CA(prov=region)
    elif country == "MX":
        dates = holidays.MX()
    elif country == "NZ":
        dates = holidays.NZ(prov=region)
    else:
        print "UNKNOWN COUNTRY ",country
