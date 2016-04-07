from datetime import date
import holidays

dates = None

def get(julia_date):
    return dates.get(julia_date)

def load(country, region, observed, expand, years):
    # Erases existing holiday cache and makes a new one...
    global dates

    if country == "US":
        dates = holidays.US(state=region, observed=observed, expand=expand, years=years)
    elif country == "CA":
        dates = holidays.CA(prov=region, observed=observed, expand=expand, years=years)
    elif country == "MX":
        dates = holidays.MX(observed=observed, expand=expand, years=years)
    elif country == "NZ":
        dates = holidays.NZ(prov=region, observed=observed, expand=expand, years=years)
    elif country == "AU":
        dates = holidays.AU(prov=region, observed=observed, expand=expand, years=years)
    elif country == "AT":
        dates = holidays.AT(prov=region, observed=observed, expand=expand, years=years)
    elif country == "DE":
        dates = holidays.DE(prov=region, observed=observed, expand=expand, years=years)
    else:
        print "UNKNOWN COUNTRY ",country



