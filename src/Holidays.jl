VERSION >= v"0.4-" #&& __precompile__()

module Holidays

if VERSION < v"0.4-dev"
    using Dates
end

# Credits:

# This program closely borrows the logic for calculating most holidays from
# https://github.com/ryanss/holidays.py
# Calculating easter is done using a julia port of IanTaylorEasterJscr(year) from
# https://en.wikipedia.org/wiki/Computus#Algorithms

observed = true

weekend = [Dates.Saturday, Dates.Sunday]

# Shorthand
dayofweek = Dates.dayofweek

# Functions

type HolidayBase
    country::AbstractString
    region::AbstractString
    years::Set{Int}
    dates::Dict{Date,AbstractString}
end

function dayName(date::Date, holidays::HolidayBase)
    # Expand dict
    if !(Dates.year(date) in holidays.years)
        populate_canadian(holidays.dates, holidays.region, Dates.year(date))
        push!(holidays.years, Dates.year(date))
    end

    if haskey(holidays.dates, date)
        return holidays.dates[date]
    else
        return Void
    end
end

function nthWeekday(start, weekday, count)
    Dates.tonext(start) do x
        dayofweek(x) == weekday &&
        Dates.dayofweekofmonth(x) == count
    end
end

# Returns same date if this is is 'weekday'
function next_weekday(date, weekday)
    if dayofweek(date) == weekday
        return date
    end

    Dates.tonext(x->Dates.dayofweek(x) == weekday, date)
end

function prev_weekday(date, weekday)
    if dayofweek(date) == weekday
        return date
    end

    Dates.toprev(x->Dates.dayofweek(x) == weekday, date)
end

function nearest(date, weekday)
    dt1 = prev_weekday(date, weekday)
    dt2 = next_weekday(date, weekday)

    if dt2 - date <= date - dt1
        return dt2
    else
        return dt1
    end
end

#Returns the 'western' easter listed in https://en.wikipedia.org/wiki/List_of_dates_for_Easter
function easter(year)
    a = year % 19
    b = year >> 2
    c = fld(b, 25) + 1
    d = (c * 3) >> 2
    e = ((a * 19) - fld((c * 8 + 5), 25) + d + 15) % 30
    e = e + (29578 - a - e * 32) >> 10
    e = e - ((year % 7) + b - d + e + 2) % 7
    d = e >> 5
    day = e - d * 31
    month = d + 3
    return Date(year, month, day)
end

# Adapted from https://en.wikipedia.org/wiki/Computus#Algorithms
# def IanTaylorEasterJscr(year):
#     a = year % 19
#     b = year >> 2
#     c = b // 25 + 1
#     d = (c * 3) >> 2
#     e = ((a * 19) - ((c * 8 + 5) // 25) + d + 15) % 30
#     e += (29578 - a - e * 32) >> 10
#     e -= ((year % 7) + b - d + e + 2) % 7
#     d = e >> 5
#     day = e - d * 31
#     month = d + 3
#     return year, month, day

function populate_canadian(days::Dict{Date,AbstractString}, region::AbstractString, year::Int)
    # New Year's Day
    if year >= 1867
        name = "New Year's Day"
        date = Date(year, 1, 1)
        days[date] = name

        if observed
            if dayofweek(date) == Dates.Sunday
                days[date + Dates.Day(1)] = name * " (Observed)"
            elseif dayofweek(date) == Dates.Saturday
                days[date + Dates.Day(-1)] = name * " (Observed)"
            end
        end

        # The next year's observed New Year's Day can be in this year
        # when it falls on a Friday (Jan 1st is a Saturday)
        if observed && dayofweek(Date(year, 12, 31)) == Dates.Friday
            days[Date(year, 12, 31)] = name * " (Observed)"
        end
    end

    # Islander Day
    if region == "PE" && year >= 2010
        # third monday of february
        days[nthWeekday(Date(year, 2, 1), Dates.Monday, 3) ] = "Islander Day"

    elseif region == "PE" && year == 2009
        # 2nd monday of february
        days[nthWeekday(Date(year, 2, 1), Dates.Monday, 2) ] = "Islander Day"
    end

    # Family Day / Louis Riel Day (MB)
    feb1 = Date(year, 2, 1)
    if region in ["AB", "SK", "ON"] && year >= 2008
        days[nthWeekday(feb1, Dates.Monday, 3) ] = "Family Day"
    elseif region in ["AB", "SK"] && year >= 2007
        days[nthWeekday(feb1, Dates.Monday, 3) ] = "Family Day"
    elseif region == "AB" && year >= 1990
        days[nthWeekday(feb1, Dates.Monday, 3) ] = "Family Day"
    elseif region == "BC" && year >= 2013
        days[nthWeekday(feb1, Dates.Monday, 2) ] = "Family Day"
    elseif region == "MB" && year >= 2008
        days[nthWeekday(feb1, Dates.Monday, 3) ] = "Louis Riel Day"
    end

    # St. Patrick's Day
    if region == "NL" && year >= 1900
        days[nearest(Date(year, 3, 17), Dates.Monday)] = "St. Patrick's Day"
    end

    # Good Friday
    if region != "QC" && year >= 1867
        days[ Dates.toprev(x->Dates.dayofweek(x) == Dates.Friday, easter(year)) ] = "Good Friday"
    end

    # Easter Monday
    if region == "QC" && year >= 1867
        days[easter(year) + Dates.Day(1)] = "Easter Monday"
    end

    # St. George's Day
    if region == "NL" && year == 2010
        # 4/26 is the Monday closer to 4/23 in 2010
        # but the holiday was observed on 4/19? Crazy Newfies!
        days[Date(2010, 4, 19)] = "St. George's Day"

    elseif region == "NL" && year >= 1990
        days[nearest(Date(year, 4, 23), Dates.Monday)] = "St. George's Day"
    end

    # Victoria Day / National Patriotes Day (QC)
    if !(region in ["NB", "NS", "PE", "NL", "QC"]) && year >= 1953
        date = prev_weekday(Date(year, 5, 24), Dates.Monday)
        days[date] = "Victoria Day"

    elseif region == "QC" && year >= 1953
        date = prev_weekday(Date(year, 5, 24), Dates.Monday)
        days[date] = "National Patriotes Day"
    end


    # Victoria Day / National Patriotes Day (QC)
    if !(region in ["NB", "NS", "PE", "NL", "QC"]) && year >= 1953
        days[prev_weekday(Date(year, 5, 24), Dates.Monday)] = "Victoria Day"

    elseif region == "QC" && year >= 1953
        name = "National Patriotes Day"
        days[prev_weekday(Date(year, 5, 24), Dates.Monday)] = name
    end

    # National Aboriginal Day
    if region == "NT" && year >= 1996
        days[Date(year, 6, 21)] = "National Aboriginal Day"
    end

    # St. Jean Baptiste Day
    if region == "QC" && year >= 1925
        days[Date(year, 6, 24)] = "St. Jean Baptiste Day"
        if observed && dayofweek(Date(year, 6, 24)) == Dates.Sunday
            days[Date(year, 6, 25)] = "St. Jean Baptiste Day (Observed)"
        end
    end

    # Discovery Day
    if region == "NL" && year >= 1997
        days[ nearest(Date(year, 6, 24), Dates.Monday) ] = "Discovery Day"

    elseif region == "YU" && year >= 1912
        days[nthWeekday(Date(year, 8, 1), Dates.Monday, 3) ] = "Discovery Day"
    end

    # Canada Day / Memorial Day (NL)
    if region != "NL" && year >= 1867
        date = Date(year, 7, 1)
        name = "Canada Day"
        days[date] = name
        if observed && dayofweek(date) in weekend
            days[next_weekday(date, Dates.Monday)] = name * " (Observed)"
        end

    elseif year >= 1867
        name = "Memorial Day"
        date = Date(year, 7, 1)

        days[date] = name
        if observed && dayofweek(date) in weekend
            days[next_weekday(date, Dates.Monday)] = name * " (Observed)"
        end
    end

    # Nunavut Day
    if region == "NU" && year >= 2001
        days[Date(year, 7, 9)] = "Nunavut Day"
        if observed && dayofweek(Date(year, 7, 9)) == Dates.Sunday
            days[Date(year, 7, 10)] = "Nunavut Day (Observed)"
        end
    elseif region == "NU" && year == 2000
        days[Date(2000, 4, 1)] = "Nunavut Day"
    end

    # Civic Holiday / British Columbia Day
    if region in ["SK", "ON", "MB", "NT"] && year >= 1900
        days[next_weekday(Date(year, 8, 1), Dates.Monday)] = "Civic Holiday"

    elseif region == "BC" && year >= 1974
        days[next_weekday(Date(year, 8, 1), Dates.Monday)] = "British Columbia Day"
    end

     # Labour Day
    if year >= 1894
        days[next_weekday(Date(year, 9, 1), Dates.Monday)] = "Labour Day"
    end

    # Thanksgiving
    if !(region in ["NB", "NS", "PE", "NL"]) && year >= 1931
        days[nthWeekday(Date(year, 10, 1), Dates.Monday, 2) ] = "Thanksgiving"
    end

     # Remembrance Day
    name = "Remembrance Day"
    provinces = ["ON", "QC", "NS", "NL", "NT", "PE", "SK"]
    if ! (region in provinces) && year >= 1931
        days[Date(year, 11, 11)] = name

    elseif region in ["NS", "NL", "NT", "PE", "SK"] && year >= 1931
        days[Date(year, 11, 11)] = name
        if observed && dayofweek(Date(year, 11, 11)) == Dates.Sunday
            name = name * " (Observed)"
            days[next_weekday(Date(year, 11, 11), Dates.Monday)] = name
        end
    end

     # Christmas Day
    if year >= 1867
        days[Date(year, 12, 25)] = "Christmas Day"
        if observed && dayofweek(Date(year, 12, 25)) == Dates.Saturday
            days[Date(year, 12, 24)] = "Christmas Day (Observed)"

        elseif observed && dayofweek(Date(year, 12, 25)) == Dates.Sunday
            days[Date(year, 12, 26)] = "Christmas Day (Observed)"
        end
    end

    # Boxing Day
    if year >= 1867
        name = "Boxing Day"
        name_observed = name * " (Observed)"
        if observed && dayofweek(Date(year, 12, 26)) in weekend
            days[next_weekday(Date(year, 12, 26), Dates.Monday)] = name_observed

        elseif observed && dayofweek(Date(year, 12, 26)) == Dates.Monday
            days[Date(year, 12, 27)] = name_observed
        else
            days[Date(year, 12, 26)] = name
        end
    end
end

function Canada( ; region="", years::Array{Int}=Int[])
    years = Set(years)

    holidays = Dict{Date,AbstractString}()

    for year in years
        populate_canadian(holidays, region, year)
    end

    x = HolidayBase("CA", region, years, holidays)
    x
end

end

