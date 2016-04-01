using Holidays

country = "CA"
province = "MB"
dates = Holidays.Cache(country=country, region=province)

print(Holidays.countryRegions(country))
