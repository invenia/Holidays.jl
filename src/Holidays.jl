VERSION >= v"0.4-" && __precompile__()

module Holidays

if VERSION < v"0.4-dev"
    using Dates
end

type HolidayBase
    country::AbstractString
    region::AbstractString
    years::Set{Int}
    dates::Dict{Date,AbstractString}
end

function dayName(date::Date, holidays::HolidayBase)
    if haskey(holidays.dates, date)
        return holidays.dates[date]
    else
        return Void
    end
end

function nthWeekday(start, weekday, count)
    Dates.tonext(start) do x
        Dates.dayofweek(x) == weekday &&
        Dates.dayofweekofmonth(x) == count
    end
end

# Adapted from https://en.wikipedia.org/wiki/Computus#Algorithms -- this should be tested for non-gregorian years
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

function populate_canadian(days::Dict{Date,AbstractString}, region::AbstractString, year::Int)
    # New Year's Day
    if year >= 1867
        name = "New Year's Day"
        date = Date(year, 1, 1)
        days[date] = name

        if Dates.dayofweek(date) == Dates.Sunday
            days[date + Dates.Day(1)] = name * " (Observed)"
        elseif Dates.dayofweek(date) == Dates.Saturday
            days[date + Dates.Day(-1)] = name * " (Observed)"
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
        date = Date(year, 3, 17)

        dt1 = Dates.toprev(x->Dates.dayofweek(x) == Dates.Monday, date)
        dt2 = Dates.tonext(x->Dates.dayofweek(x) == Dates.Monday, date)

        if dt2 - date <= date - dt1
            days[dt2] = "St. Patrick's Day"
        else
            days[dt1] = "St. Patrick's Day"
        end
    end

    # Good Friday
    if region != "QC" && year >= 1867
        easter_day = easter(year)
        good_friday = Dates.toprev(x->Dates.dayofweek(x) == Dates.Friday, easter_day)
        days[good_friday] = "Good Friday"
    end
end

function Canada(;region="", years::Union{Int, Array{Int}, Set{Int}}=Set([]))
    if isa(years, Int) || isa(years, Array)
        years = Set(years)
    end

    holidays = Dict{Date,AbstractString}()

    for year in years
        populate_canadian(holidays, region, year)
    end

    x = HolidayBase("CA", region, years, holidays)
    x
end

end

