from datetime import date
import holidays

dates = None

def get(julia_date):
    return dates.get(julia_date)

def load(country, region, observed, expand):
    # Erases existing holiday cache and makes a new one...
    global dates

    if country == "US":
        dates = holidays.US(state=region, observed=observed, expand=expand)
    elif country == "CA":
        dates = holidays.CA(prov=region, observed=observed, expand=expand)
    elif country == "MX":
        dates = holidays.MX(observed=observed, expand=expand)
    elif country == "NZ":
        dates = holidays.NZ(prov=region, observed=observed, expand=expand)
    elif country == "AU":
        dates = holidays.AU(prov=region, observed=observed, expand=expand)
    elif country == "AT":
        dates = holidays.AT(prov=region, observed=observed, expand=expand)
    elif country == "DE":
        dates = holidays.DE(prov=region, observed=observed, expand=expand)
    else:
        print "UNKNOWN COUNTRY ",country

