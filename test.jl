using Holidays

# Generate once to improve speed
days = Holidays.Canada(region="MB", years=[2016])
println(days.dates)


#~ dates = Dict()

#~ function dateStr(d::Date)
    #~ return string(Dates.year(d)) * "-" * string(Dates.month(d)) * "-" * string(Dates.day(d))
#~ end

#~ function init_holidays(;years=[])
    #~ for year in years
        #~ println(year)
    #~ end
#~ end

#~ function is_holiday(d::Date)
    #~ haskey(dates, d)
#~ end

#~ julia> haskey(dates, Date(2016, 3, 22 ))
#~ julia> haskey(dates, Date(2016, 3, 21 ))


#~ issaturday = x->Dates.dayofweek(x) == Dates.Saturday
#~ x = Dates.tonext(issaturday, Date(2016, 3, 22))

#~ println(is_holiday(Date(2016, 7, 1)))

#~ init_holidays(years=[2016, 2017])

#~ print(dateStr(x))

#~ dates = Dict()
#~ dates[Date("2016-06-01")] = "Canada Day"

#~ print(dates[Date("2016-06-01")])
#~ print(dates[Date("2016-06-02")])

#~ print(dates)
print("\nDone")


