__precompile__()

module Holidays
export HolidayBase, country_regions, holiday_cache, day_name!

import Base.Dates: Mon, Tue, Wed, Thu, Fri, Sat, Sun, dayofweek, tonext, toprev

# Credits:
# This program closely borrows the logic for calculating most holidays from
# https://github.com/ryanss/holidays.py
# Calculating easter is done using a julia port of IanTaylorEasterJscr(year) from
# https://en.wikipedia.org/wiki/Computus#Algorithms

const WEEKEND = [Sat, Sun]

const regions = Dict(
    "CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"],
    "US"=>["AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "GU",
            "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MH", "MA", "MI",
            "FM", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND",
            "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT",
            "VT", "VA", "VI", "WA", "WV", "WI", "WY"],
    "MX"=>[""],
    "NZ"=>["NTL", "AUK", "TKI", "HKB", "WGN", "MBH", "NSN", "CAN",
            "STC", "WTL", "OTA", "STL", "CIT"],
    "AU" => ["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"],
    "AT" => ["B", "K", "N", "O", "S", "ST", "T", "V", "W"],
    "DE" => ["BW", "BY", "BE", "BB", "HB", "HH", "HE", "MV", "NI", "NW", "RP",
            "SL", "SN", "ST", "SH", "TH"],
)

"""
`HolidayBase`: stores cached information about holidays to speed up future lookups,
as well as the current locale information.
"""
type HolidayBase
    """dates::Dict{Date,AbstractString}: Maps dates to holidays. If multiple holidays
    coincide then names will be concatenated with commas"""
    dates::Dict{Date,AbstractString}

    """years::Set{Int}: All years for which cached holiday names exist."""
    years::Set{Int}

    """expand::Bool: New cache entries will be created when an uncached year is requested
    if and only if expand is true (Allows constant memory use)"""
    expand::Bool

    """observed::Bool: Whether to add a name(Observed) date when a holiday conflicting with
    the weekend or another holiday is observed on another date"""
    observed::Bool

    country::AbstractString
    region::AbstractString
end


"""
`sub_day(date::Date, weekday::Int, count::Int)`: counts backwards from the given date one
week at a time, and returns a date `count` weeks in the past where day of week == weekday.
If the day of week of the start date is the same as the specified weekday, this will
count back one week less.

Returns:
- `Date`: the resulting date after subtraction of `count` weeks.
"""
function sub_day(date::Date, weekday::Int, count::Int)
    if dayofweek(date) == weekday
        count = count -1
    end

    for i in range(0, count)
        date = Dates.toprev(date, weekday, same=false)
    end

    return date
end


"""
`add_day(date::Date, weekday::Int, count::Int)`: counts forwards from the given date one
week at a time, and returns a date `count` weeks in the future where day of week == weekday.
If the day of week of the start date is the same as the specified weekday, this will
count forwards one week less.

Returns:
- `Date`: the resulting date after addition of `count` weeks.
"""
function add_day(date::Date, weekday::Int, count::Int)
    if dayofweek(date) == weekday
        count = count -1
    end

    for i in range(0, count)
        date = Dates.tonext(date, weekday, same=false)
    end

    return date
end

"""
`nearest(date::Date, weekday::Int)`: finds the closest date value where
dayofweek(value) == `weekday` to the provided date.
Will return the provided date if dayofweek(date) == `weekday`

Returns:
- `Date`: the nearest matching date
"""
function nearest(date::Date, weekday::Int)
    dt1 = toprev(date, weekday; same=true)
    dt2 = tonext(date, weekday; same=true)

    if dt2 - date <= date - dt1
        return dt2
    else
        return dt1
    end
end

"""
`easter(year::Int)`: Calculates easter for the given year, according to the western calendar.
Dates for the eastern calendar differ, so verify what format you expect before use.

Returns:
- `Date`: The date of easter in the provided year
"""
function easter(year::Int)
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

"""
`title(holidays::Dict{Date,AbstractString}, date::Date, day::AbstractString)`:
Maps a date to the name of a holiday in the cache. If a key already has a holiday name
attached, this will prepend the new date with a comma and space between.

Returns:
- Nothing
"""
function title(holidays::Dict{Date,AbstractString}, date::Date, day::AbstractString)
    # If holiday already has a name, prepend the new one with a ,
    if haskey(holidays, date)
        holidays[date] = day * ", " * holidays[date]
    else
        holidays[date] = day
    end
end

"""
`populate_ca!(days::Dict{Date,AbstractString}, region::AbstractString,
              observed::Bool, year::Int)`:
for each holiday, sets days[holidayDate] = holiday_name, for all holidays in the given year
and region. For canada, regions are provinces / territories.
If observed is true, then when a holiday conflicts with a weekend and is legally observed on
another date, a seperate entry will be created for the observed date.

Returns:
- Nothing
"""
function populate_ca!(days::Dict{Date,AbstractString}, region::AbstractString,
                      observed::Bool, year::Int)
    # New Year's Day
    if year >= 1867
        name = "New Year's Day"
        date = Date(year, 1, 1)
        title(days, date, name)

        if observed
            if dayofweek(date) == Sun
                title(days, date + Dates.Day(1), name * " (Observed)")
            elseif dayofweek(date) == Sat
                title(days, date + Dates.Day(-1), name * " (Observed)")
            end
        end

        # The next year's observed New Year's Day can be in this year
        # when it falls on a Friday (Jan 1st is a Saturday)
        if observed && dayofweek(Date(year, 12, 31)) == Fri
            title(days, Date(year, 12, 31), name * " (Observed)")
        end
    end

    # Islander Day
    if region == "PE" && year >= 2010
        title(days, add_day(Date(year, 2), Mon, 3) , "Islander Day")
    elseif region == "PE" && year == 2009
        title(days, add_day(Date(year, 2), Mon, 2) , "Islander Day")
    end

    # Family Day / Louis Riel Day (MB)
    feb1 = Date(year, 2, 1)
    if region in ("AB", "SK", "ON") && year >= 2008
        title(days, add_day(feb1, Mon, 3) , "Family Day")
    elseif region in ("AB", "SK") && year >= 2007
        title(days, add_day(feb1, Mon, 3) , "Family Day")
    elseif region == "AB" && year >= 1990
        title(days, add_day(feb1, Mon, 3) , "Family Day")
    elseif region == "BC" && year >= 2013
        title(days, add_day(feb1, Mon, 2) , "Family Day")
    elseif region == "MB" && year >= 2008
        title(days, add_day(feb1, Mon, 3) , "Louis Riel Day")
    end

    # St. Patrick's Day
    if region == "NL" && year >= 1900
        title(days, nearest(Date(year, 3, 17), Mon), "St. Patrick's Day")
    end

    # Good Friday
    if region != "QC" && year >= 1867
        title(days,  Dates.toprev(x->Dates.dayofweek(x) == Fri, easter(year)) , "Good Friday")
    end

    # Easter Monday
    if region == "QC" && year >= 1867
        title(days, easter(year) + Dates.Day(1), "Easter Monday")
    end

    # St. George's Day
    if region == "NL" && year == 2010
        # 4/26 is the Monday closer to 4/23 in 2010
        # but the holiday was observed on 4/19? Crazy Newfies!
        title(days, Date(2010, 4, 19), "St. George's Day")
    elseif region == "NL" && year >= 1990
        title(days, nearest(Date(year, 4, 23), Mon), "St. George's Day")
    end

    # Victoria Day / National Patriots' Day (QC)
    if !(region in ("NB", "NS", "PE", "NL", "QC")) && year >= 1953
        date = toprev(Date(year, 5, 24), Mon; same=true)
        title(days, date, "Victoria Day")
    elseif region == "QC" && year >= 1953
        date = toprev(Date(year, 5, 24), Mon; same=true)
        title(days, date, "National Patriots' Day")
    end

    # National Aboriginal Day
    if region == "NT" && year >= 1996
        title(days, Date(year, 6, 21), "National Aboriginal Day")
    end

    # St. Jean Baptiste Day
    if region == "QC" && year >= 1925
        title(days, Date(year, 6, 24), "St. Jean Baptiste Day")
        if observed && dayofweek(Date(year, 6, 24)) == Sun
            title(days, Date(year, 6, 25), "St. Jean Baptiste Day (Observed)")
        end
    end

    # Discovery Day
    if region == "NL" && year >= 1997
        title(days,  nearest(Date(year, 6, 24), Mon) , "Discovery Day")

    elseif region == "YU" && year >= 1912
        title(days, add_day(Date(year, 8, 1), Mon, 3) , "Discovery Day")
    end

    # Canada Day / Memorial Day (NL)
    if region != "NL" && year >= 1867
        date = Date(year, 7, 1)
        name = "Canada Day"
        title(days, date, name)
        if observed && dayofweek(date) in WEEKEND
            title(days, tonext(date, Mon; same=true), name * " (Observed)")
        end
    elseif year >= 1867
        name = "Memorial Day"
        date = Date(year, 7, 1)
        title(days, date, name)

        if observed && dayofweek(date) in WEEKEND
            title(days, tonext(date, Mon; same=true), name * " (Observed)")
        end
    end

    # Nunavut Day
    if region == "NU" && year >= 2001
        title(days, Date(year, 7, 9), "Nunavut Day")
        if observed && dayofweek(Date(year, 7, 9)) == Sun
            title(days, Date(year, 7, 10), "Nunavut Day (Observed)")
        end
    elseif region == "NU" && year == 2000
        title(days, Date(2000, 4, 1), "Nunavut Day")
    end

    # Civic Holiday / British Columbia Day
    if region in ("SK", "ON", "MB", "NT") && year >= 1900
        title(days, tonext(Date(year, 8, 1), Mon; same=true), "Civic Holiday")
    elseif region == "BC" && year >= 1974
        title(days, tonext(Date(year, 8, 1), Mon; same=true), "British Columbia Day")
    end

     # Labour Day
    if year >= 1894
        title(days, tonext(Date(year, 9, 1), Mon; same=true), "Labour Day")
    end

    # Thanksgiving
    if !(region in ("NB", "NS", "PE", "NL")) && year >= 1931
        title(days, add_day(Date(year, 10, 1), Mon, 2) , "Thanksgiving")
    end

     # Remembrance Day
    name = "Remembrance Day"
    provinces = ("ON", "QC", "NS", "NL", "NT", "PE", "SK")
    if !(region in provinces) && year >= 1931
        title(days, Date(year, 11, 11), name)
    elseif region in ("NS", "NL", "NT", "PE", "SK") && year >= 1931
        title(days, Date(year, 11, 11), name)
        if observed && dayofweek(Date(year, 11, 11)) == Sun
            name = name * " (Observed)"
            title(days, tonext(Date(year, 11, 11), Mon; same=true), name)
        end
    end

     # Christmas Day
    if year >= 1867
        title(days, Date(year, 12, 25), "Christmas Day")
        if observed && dayofweek(Date(year, 12, 25)) == Sat
            title(days, Date(year, 12, 24), "Christmas Day (Observed)")
        elseif observed && dayofweek(Date(year, 12, 25)) == Sun
            title(days, Date(year, 12, 26), "Christmas Day (Observed)")
        end
    end

    # Boxing Day
    if year >= 1867
        name = "Boxing Day"
        name_observed = name * " (Observed)"
        if observed && dayofweek(Date(year, 12, 26)) in WEEKEND
            title(days, tonext(Date(year, 12, 26), Mon; same=true), name_observed)
        elseif observed && dayofweek(Date(year, 12, 26)) == Mon
            title(days, Date(year, 12, 27), name_observed)
        else
            title(days, Date(year, 12, 26), name)
        end
    end
end

"""
`populate_us!(days::Dict{Date,AbstractString}, region::AbstractString,
              observed::Bool, year::Int)`:
for each holiday, sets days[holidayDate] = holiday_name, for all holidays in the given year
and region. For the USA, regions are states.
If observed is true, then when a holiday conflicts with a weekend and is legally observed on
another date, a seperate entry will be created for the observed date.

Returns:
- Nothing
"""
function populate_us!(days::Dict{Date,AbstractString}, region::AbstractString,
                      observed::Bool, year::Int)
    # New Year's Day
    if year > 1870
        name = "New Year's Day"
        date = Date(year, 1, 1)
        title(days, date, name)

        if observed
            if dayofweek(date) == Sun
                title(days, date + Dates.Day(1), name * " (Observed)")
            elseif dayofweek(date) == Sat
                title(days, date + Dates.Day(-1), name * " (Observed)")
            end
        end

        # The next year's observed New Year's Day can be in this year
        # when it falls on a Friday (Jan 1st is a Saturday)
        if observed && dayofweek(Date(year, 12, 31)) == Fri
            title(days, Date(year, 12, 31), name * " (Observed)")
        end
    end

    # Epiphany
    if region == "PR"
        title(days, Date(year, 1, 6), "Epiphany")
    end

    # Three King's Day
    if region == "VI"
        title(days, Date(year, 1, 6), "Three King's Day")
    end

    # Lee Jackson Day
    name = "Lee Jackson Day"
    if region == "VA" && year >= 2000
        # Third monday, then back to previous friday.
        date = Date(year, 1, 1)
        date = add_day(date, Mon, 3)
        date = sub_day(date, Fri, 1)
        title(days, date, name)
    elseif region == "VA" && year >= 1983
        date = Date(year, 1, 1)
        date = add_day(date, Mon, 3)
        title(days, date, name)
    elseif region == "VA" && year >= 1889
        title(days, Date(year, 1, 19), name)
    end

    # Inauguration Day
    if region in ("DC", "LA", "MD", "VA") && year >= 1789
        name = "Inauguration Day"
        if (year - 1789) % 4 == 0 && year >= 1937
            title(days, Date(year, 1, 20), name)
            if dayofweek(Date(year, 1, 20)) == Sun
                title(days, Date(year, 1, 21), name * " (Observed)")
            end
        elseif (year - 1789) % 4 == 0
            title(days, Date(year, 3, 4), name)
            if dayofweek(Date(year, 3, 4)) == Sun
                title(days, Date(year, 3, 5), name * " (Observed)")
            end
        end
    end

    # Martin Luther King, Jr. Day
    if year >= 1986
        name = "Martin Luther King, Jr. Day"
        if region == "AL"
            name = "Robert E. Lee/Martin Luther King Birthday"
        elseif region in ("AS", "MS")
            name = ("Dr. Martin Luther King Jr. and Robert E. Lee's Birthdays")
        elseif region in ("AZ", "NH")
            name = "Dr. Martin Luther King Jr./Civil Rights Day"
        elseif region == "GA" && year < 2012
            name = "Robert E. Lee's Birthday"
        elseif region == "ID" && year >= 2006
            name = "Martin Luther King, Jr. - Idaho Human Rights Day"
        end

        if region != "GA" || year < 2012
            title(days, add_day(Date(year), Mon, 3), name)
        end
    end

    # Lincoln's Birthday
    name = "Lincoln's Birthday"
    if (region in ("CT", "IL", "IA", "NJ", "NY") && year >= 1971) ||
            (region == "CA" && year >= 1971 && year <= 2009)

        title(days, Date(year, 2, 12), name)

        if observed && dayofweek(Date(year, 2, 12)) == Sat
            title(days, Date(year, 2, 11), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 2, 12)) == Sun
            title(days, Date(year, 2, 13), name * " (Observed)")
        end
    end

    # Susan B. Anthony Day
    if (region == "CA" && year >= 2014) ||
            (region == "FL" && year >= 2011) ||
            (region == "NY" && year >= 2004) ||
            (region == "WI" && year >= 1976)

        title(days, Date(year, 2, 15), "Susan B. Anthony Day")
    end

    # Washington's Birthday
    name = "Washington's Birthday"
    if region == "AL"
        name = "George Washington/Thomas Jefferson Birthday"
    elseif region == "AS"
        name = "George Washington's Birthday and Daisy Gatson Bates Day"
    elseif region in ("PR", "VI")
        name = "Presidents' Day"
    end

    if !(region in ("DE", "FL", "GA", "NM", "PR"))
        if year > 1970
            title(days, add_day(Date(year, 2), Mon, 3), name)
        elseif year >= 1879
            title(days, Date(year, 2, 22), name)
        end
    elseif region == "GA"
        if dayofweek(Date(year, 12, 24)) != Wed
            title(days, Date(year, 12, 24), name)
        else
            title(days, Date(year, 12, 26), name)
        end
    elseif region in ("PR", "VI")
        title(days, add_day(Date(year, 2), Mon, 3), name)
    end

    # Mardi Gras
    if region == "LA" && year >= 1857
        title(days, easter(year) + Dates.Day(-47), "Mardi Gras")
    end

    # Guam Discovery Day
    if region == "GU" && year >= 1970
        title(days, add_day(Date(year, 3, 1), Mon, 1), "Guam Discovery Day")
    end

    # Casimir Pulaski Day
    if region == "IL" && year >= 1978
        title(days, add_day(Date(year, 3), Mon, 1), "Casimir Pulaski Day")
    end

    # Texas Independence Day
    if region == "TX" && year >= 1874
        title(days, Date(year, 3, 2), "Texas Independence Day")
    end

    # Town Meeting Day
    if region == "VT" && year >= 1800
        title(days, add_day(Date(year, 3), Tue, 1), "Town Meeting Day")
    end

    # Evacuation Day
    if region == "MA" && year >= 1901
        name = "Evacuation Day"
        title(days, Date(year, 3, 17), name)
        if dayofweek(Date(year, 3, 17)) in WEEKEND
            title(days, add_day(Date(year, 3, 17), Mon, 1), name * " (Observed)")
        end
    end

    # Emancipation Day
    if region == "PR"
        title(days, Date(year, 3, 22), "Emancipation Day")
        if observed && dayofweek(Date(year, 3, 22)) == Sun
            title(days, Date(year, 3, 23), "Emancipation Day (Observed)")
        end
    end

    # Prince Jonah Kuhio Kalanianaole Day
    if region == "HI" && year >= 1949
        name = "Prince Jonah Kuhio Kalanianaole Day"
        title(days, Date(year, 3, 26), name)
        if observed && dayofweek(Date(year, 3, 26)) == Sat
            title(days, Date(year, 3, 25), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 3, 26)) == Sun
            title(days, Date(year, 3, 27), name * " (Observed)")
        end
    end

    # Steward's Day
    name = "Steward's Day"
    if region == "AK" && year >= 1955
        date = Date(year, 4, 1) + Dates.Day(-1)
        title(days, sub_day(date, Mon, 1), name)
    elseif region == "AK" && year >= 1918
        title(days, Date(year, 3, 30), name)
    end

    # César Chávez Day
    name = "César Chávez Day"
    if region == "CA" && year >= 1995
        title(days, Date(year, 3, 31), name)
        if observed && dayofweek(Date(year, 3, 31)) == Sun
            title(days, Date(year, 4, 1), name * " (Observed)")
        end
    elseif region == "TX" && year >= 2000
        title(days, Date(year, 3, 31), name)
    end

    # Transfer Day
    if region == "VI"
        title(days, Date(year, 3, 31), "Transfer Day")
    end

    # Emancipation Day
    if region == "DC" && year >= 2005
        name = "Emancipation Day"
        title(days, Date(year, 4, 16), name)
        if observed && dayofweek(Date(year, 4, 16)) == Sat
            title(days, Date(year, 4, 15), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 4, 16)) == Sun
            title(days, Date(year, 4, 17), name * " (Observed)")
        end
    end

    # Patriots' Day
    if region in ("ME", "MA") && year >= 1969
        title(days, add_day(Date(year, 4, 1), Mon, 3), "Patriots' Day")
    elseif region in ("ME", "MA") && year >= 1894
        title(days, Date(year, 4, 19), "Patriots' Day")
    end

    # Holy Thursday
    if region == "VI"
        title(days, sub_day(easter(year), Thu, 1), "Holy Thursday")
    end

    # Good Friday
    if region in ("CT", "DE", "GU", "IN", "KY", "LA",
                  "NJ", "NC", "PR", "TN", "TX", "VI")
        title(days, sub_day(easter(year), Fri, 1), "Good Friday")
    end

    # Easter Monday
    if region == "VI"
        title(days, add_day(easter(year), Mon, 1), "Easter Monday")
    end

    # Confederate Memorial Day
    name = "Confederate Memorial Day"
    if region in ("AL", "GA", "MS", "SC") && year >= 1866
        title(days, add_day(Date(year, 4), Mon, 4), name)
    elseif region == "TX" && year >= 1931
        title(days, Date(year, 1, 19), name)
    end

    # San Jacinto Day
    if region == "TX" && year >= 1875
        title(days, Date(year, 4, 21), "San Jacinto Day")
    end

    # Arbor Day
    if region == "NE" && year >= 1989
        title(days, sub_day(Date(year, 4, 30), Fri, 1), "Arbor Day")
    elseif region == "NE" && year >= 1875
        title(days, Date(year, 4, 22), "Arbor Day")
    end

    # Primary Election Day
    if region == "IN" && ((year >= 2006 && year % 2 == 0) || year >= 2015)
        date = add_day(Date(year, 5), Mon, 1)
        title(days, date + Dates.Day(1), "Primary Election Day")
    end

    # Truman Day
    if region == "MO" && year >= 1949
        name = "Truman Day"
        title(days, Date(year, 5, 8), name)
        if observed && dayofweek(Date(year, 5, 8)) == Sat
            title(days, Date(year, 5, 7), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 5, 8)) == Sun
            title(days, Date(year, 5, 10), name * " (Observed)")
        end
    end

    # Memorial Day
    if year > 1970
        title(days, sub_day(Date(year, 5, 31), Mon, 1), "Memorial Day")
    elseif year >= 1888
        title(days, Date(year, 5, 30), "Memorial Day")
    end

    # Jefferson Davis Birthday
    name = "Jefferson Davis Birthday"
    if region == "AL" && year >= 1890
        title(days, add_day(Date(year, 6), Mon, 1), name)
    end

    # Kamehameha Day
    if region == "HI" && year >= 1872
        title(days, Date(year, 6, 11), "Kamehameha Day")
        if observed && year >= 2011
            if dayofweek(Date(year, 6, 11)) == Sat
                title(days, Date(year, 6, 10), "Kamehameha Day (Observed)")
            elseif dayofweek(Date(year, 6, 11)) == Sun
                title(days, Date(year, 6, 12), "Kamehameha Day (Observed)")
            end
        end
    end

    # Emancipation Day In Texas
    if region == "TX" && year >= 1980
        title(days, Date(year, 6, 19), "Emancipation Day In Texas")
    end

    # West Virginia Day
    name = "West Virginia Day"
    if region == "WV" && year >= 1927
        title(days, Date(year, 6, 20), name)
        if observed && dayofweek(Date(year, 6, 20)) == Sat
            title(days, Date(year, 6, 19), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 6, 20)) == Sun
            title(days, Date(year, 6, 21), name * " (Observed)")
        end
    end

    # Emancipation Day in US Virgin Isl&&s
    if region == "VI"
        title(days, Date(year, 7, 3), "Emancipation Day")
    end

    # Independence Day
    if year > 1870
        name = "Independence Day"
        title(days, Date(year, 7, 4), name)
        if observed && dayofweek(Date(year, 7, 4)) == Sat
            title(days, Date(year, 7, 3), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 7, 4)) == Sun
            title(days, Date(year, 7, 5), name * " (Observed)")
        end
    end

    # Liberation Day (Guam)
    if region == "GU" && year >= 1945
        title(days, Date(year, 7, 21), "Liberation Day (Guam)")
    end

    # Pioneer Day
    if region == "UT" && year >= 1849
        name = "Pioneer Day"
        title(days, Date(year, 7, 24), name)
        if observed && dayofweek(Date(year, 7, 24)) == Sat
            title(days, Date(year, 7, 23), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 7, 24)) == Sun
            title(days, Date(year, 7, 25), name * " (Observed)")
        end
    end

    # Constitution Day
    if region == "PR"
        title(days, Date(year, 7, 25), "Constitution Day")
        if observed && dayofweek(Date(year, 7, 25)) == Sun
            title(days, Date(year, 7, 26), "Constitution Day (Observed)")
        end
    end

    # Victory Day
    if region == "RI" && year >= 1948
        title(days, add_day(Date(year, 8), Mon, 2), "Victory Day")
    end

    # Statehood Day (Hawaii)
    if region == "HI" && year >= 1959
        title(days, add_day(Date(year, 8), Fri, 3), "Statehood Day")
    end

    # Bennington Battle Day
    if region == "VT" && year >= 1778
        name = "Bennington Battle Day"
        title(days, Date(year, 8, 16), name)
        if observed && dayofweek(Date(year, 8, 16)) == Sat
            title(days, Date(year, 8, 15), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 8, 16)) == Sun
            title(days, Date(year, 8, 17), name * " (Observed)")
        end
    end

    # Lyndon Baines Johnson Day
    if region == "TX" && year >= 1973
        title(days, Date(year, 8, 27), "Lyndon Baines Johnson Day")
    end

    # Labor Day
    if year >= 1894
        title(days, add_day(Date(year, 9, 1), Mon, 1), "Labor Day")
    end

    # Columbus Day
    if !(region in ("AK", "DE", "FL", "HI", "NV"))
        if region == "SD"
            name = "Native American Day"
        elseif region == "VI"
            name = "Columbus Day and Puerto Rico Friendship Day"
        else
            name = "Columbus Day"
        end

        if year >= 1970
            title(days, add_day(Date(year, 10), Mon, 2), name)
        elseif year >= 1937
            title(days, Date(year, 10, 12), name)
        end
    end

    # Alaska Day
    if region == "AK" && year >= 1867
        title(days, Date(year, 10, 18), "Alaska Day")
        if observed && dayofweek(Date(year, 10, 18)) == Sat
            title(days, Date(year, 10, 17), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 10, 18)) == Sun
            title(days, Date(year, 10, 19), name * " (Observed)")
        end
    end

    # Nevada Day
    if region == "NV" && year >= 1933
        date = Date(year, 10, 31)
        if year >= 2000
            # date += rd(weekday=FR(-1))
            date = sub_day(date, Fri, 1)
        end

        title(days, date, "Nevada Day")
        if observed && dayofweek(date) == Sat
            title(days, date + Dates.Day(-1), "Nevada Day (Observed)")
        elseif observed && dayofweek(date) == Sun
            title(days, date + Dates.Day(1), "Nevada Day (Observed)")
        end
    end

    # Liberty Day
    if region == "VI"
        title(days, Date(year, 11, 1), "Liberty Day")
    end

    # Election Day
    if (region in ("DE", "HI", "IL", "IN", "LA", "MT", "NH", "NJ", "NY", "WV") &&
                year >= 2008 && year % 2 == 0) || (region in ("IN", "NY") && year >= 2015)

        # date = Date(year, 11, 1) + rd(weekday=MO)
        date = add_day(Date(year, 11), Mon, 1)
        title(days, date + Dates.Day(1), "Election Day")
    end

    # All Souls' Day
    if region == "GU"
        title(days, Date(year, 11, 2), "All Souls' Day")
    end

    # Veterans Day
    if year > 1953
        name = "Veterans Day"
    else
        name = "Armistice Day"
    end

    if 1978 > year > 1970
        # title(days, Date(year, 10, 1) + rd(weekday=MO(+4)), name)
        title(days, add_day(Date(year, 10), Mon, 4), name)
    elseif year >= 1938
        title(days, Date(year, 11, 11), name)

        if observed && dayofweek(Date(year, 11, 11)) == Sat
            title(days, Date(year, 11, 10), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 11, 11)) == Sun
            title(days, Date(year, 11, 12), name * " (Observed)")
        end
    end

    # Discovery Day
    if region == "PR"
        title(days, Date(year, 11, 19), "Discovery Day")
        if observed && dayofweek(Date(year, 11, 19)) == Sun
            title(days, Date(year, 11, 20), "Discovery Day (Observed)")
        end
    end

    # Thanksgiving
    if year > 1870
        # title(days, Date(year, 11, 1) + rd(weekday=TH(+4)), "Thanksgiving")
        title(days, add_day(Date(year, 11), Thu, 4), "Thanksgiving")
    end

    # Day After Thanksgiving
    # Friday After Thanksgiving
    # Lincoln's Birthday
    # American Indian Heritage Day
    # Family Day
    # New Mexico Presidents' Day
    if (region in ("DE", "FL", "NH", "NC", "OK", "TX", "WV") && year >= 1975) ||
            (region == "IN" && year >= 2010) || (region == "MD" && year >= 2008) ||
            region in ("NV", "NM")

        if region in ("DE", "NH", "NC", "OK", "WV")
            name = "Day After Thanksgiving"
        elseif region in ("FL", "TX")
            name = "Friday After Thanksgiving"
        elseif region == "IN"
            name = "Lincoln's Birthday"
        elseif region == "MD" && year >= 2008
            name = "American Indian Heritage Day"
        elseif region == "NV"
            name = "Family Day"
        elseif region == "NM"
            name = "Presidents' Day"
        end

        # date = Date(year, 11, 1) + rd(weekday=TH(+4))
        date = add_day(Date(year, 11, 1), Thu, 4)
        # title(days, date + rd(days=+1), name)
        title(days, date + Dates.Day(1), name)
    end

    # Robert E. Lee's Birthday
    if region == "GA" && year >= 2012
        name = "Robert E. Lee's Birthday"
        # title(days, Date(year, 11, 29) + rd(weekday=FR(-1)), name)
        title(days, sub_day( Date(year, 11, 29), Fri, 1), name)
    end

    # Lady of Camarin Day
    if region == "GU"
        title(days, Date(year, 12, 8), "Lady of Camarin Day")
    end

    # Christmas Eve
    if region == "AS" || (region in ("KS", "MI", "NC") && year >= 2013) ||
            (region == "TX" && year >= 1981) || (region == "WI" && year >= 2012)

        name = "Christmas Eve"
        title(days, Date(year, 12, 24), name)
        name = name * " (Observed)"
        # If on Friday, observed on Thursday
        if observed && dayofweek(Date(year, 12, 24)) == Fri
            title(days, Date(year, 12, 23), name)
        elseif observed && dayofweek(Date(year, 12, 24)) in WEEKEND
            title(days, sub_day(Date(year, 12, 24), Fri, 1), name)
        end
    end

    # Christmas Day
    if year > 1870
        name = "Christmas Day"
        title(days, Date(year, 12, 25), "Christmas Day")
        if observed && dayofweek(Date(year, 12, 25)) == Sat
            title(days, Date(year, 12, 24), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 12, 25)) == Sun
            title(days, Date(year, 12, 26), name * " (Observed)")
        end
    end

    # Day After Christmas
    if region == "NC" && year >= 2013
        name = "Day After Christmas"
        title(days, Date(year, 12, 26), name)
        name = name * " (Observed)"
        # If on Saturday or Sunday, observed on Monday
        if observed && dayofweek(Date(year, 12, 26)) in WEEKEND
            title(days, add_day(Date(year, 12, 26), Mon, 1), name)
        elseif observed && dayofweek(Date(year, 12, 26)) == Mon
            title(days, Date(year, 12, 27), name)
        end
    elseif region == "TX" && year >= 1981
        title(days, Date(year, 12, 26), "Day After Christmas")
    elseif region == "VI"
        title(days, Date(year, 12, 26), "Christmas Second Day")
    end

    # New Year's Eve
    if (region in ("KY", "MI") && year >= 2013) || (region == "WI" && year >= 2012)
        name = "New Year's Eve"
        title(days, Date(year, 12, 31), name)
        if observed && dayofweek(Date(year, 12, 31)) == Sat
            title(days, Date(year, 12, 30), name * " (Observed)")
        end
    end
end

"""
`populate_mx!(days::Dict{Date,AbstractString}, region::AbstractString,
              observed::Bool, year::Int)`:
for each holiday, sets days[holidayDate] = holiday_name, for all holidays in the given year.
Mexico has no regions relevant for holiday calculation.

If observed is true, then when a holiday conflicts with a weekend and is legally observed on
another date, a seperate entry will be created for the observed date.

Returns:
- Nothing
"""
function populate_mx!(days::Dict{Date,AbstractString}, region::AbstractString,
                      observed::Bool, year::Int)
    # New Year's Day
    name = "Año Nuevo [New Year's Day]"
    title(days, Date(year, 1, 1), name)
    if observed && dayofweek(Date(year, 1, 1)) == Sun
        title(days, Date(year, 1, 2), name * " (Observed)")
    elseif observed && dayofweek(Date(year, 1, 1)) == Sat
        # Add Dec 31st from the previous year without triggering
        # the entire year to be added
        title(days, Date(year, 1, 1) + Dates.Day(-1), name * " (Observed)")
    end
    # The next year's observed New Year's Day can be in this year
    # when it falls on a Friday (Jan 1st is a Saturday)
    if observed && dayofweek(Date(year, 12, 31)) == Fri
        title(days, Date(year, 12, 31), name * " (Observed)")
    end

    # Constitution Day
    name = "Día de la Constitución [Constitution Day]"
    if 2006 >= year >= 1917
        title(days, Date(year, 2, 5), name)
    elseif year >= 2007
        title(days, add_day(Date(year, 2, 1), Mon, 1), name)
    end

    # Benito Juárez's birthday
    name = "Natalicio de Benito Juárez [Benito Juárez's birthday]"
    if 2006 >= year >= 1917
        title(days, Date(year, 3, 21), name)
    elseif year >= 2007
        title(days, add_day(Date(year, 3), Mon, 3), name)
    end
    # Labor Day
    if year >= 1923
        title(days, Date(year, 5, 1), "Día del Trabajo [Labour Day]")

        if observed && dayofweek(Date(year, 5, 1)) == Sat
            title(days, Date(year, 5, 1) + Dates.Day(-1), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 5, 1)) == Sun
            title(days, Date(year, 5, 1) + Dates.Day(1), name * " (Observed)")
        end
    end

    # Independence Day
    name = "Día de la Independencia [Independence Day]"
    title(days, Date(year, 9, 16), name)
    if observed && dayofweek(Date(year, 9, 16)) == Sat
        title(days, Date(year, 9, 16) + Dates.Day(-1), name * " (Observed)")
    elseif observed && dayofweek(Date(year, 9, 16)) == Sun
        title(days, Date(year, 9, 16) + Dates.Day(1), name * " (Observed)")
    end

    # Revolution Day
    name = "Día de la Revolución [Revolution Day]"
    if 2006 >= year >= 1917
        title(days, Date(year, 11, 20), name)
    elseif year >= 2007
        title(days, add_day(Date(year, 11, 1), Mon, 3), name)
    end

    # Change of Federal Government
    # Every six years--next observance 2018
    name = "Transmisión del Poder Ejecutivo Federal"
    name = name * " [Change of Federal Government]"
    if (2018 - year) % 6 == 0
        title(days, Date(year, 12, 1), name)

        if observed && dayofweek(Date(year, 12, 1)) == Sat
            title(days, Date(year, 12, 1) + Dates.Day(-1), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 12, 1)) == Sun
            title(days, Date(year, 12, 2), name * " (Observed)")
        end
    end

    # Christmas
    title(days, Date(year, 12, 25), "Navidad [Christmas]")
    if observed && dayofweek(Date(year, 12, 25)) == Sat
        title(days, Date(year, 12, 24), name * " (Observed)")
    elseif observed && dayofweek(Date(year, 12, 25)) == Sun
        title(days, Date(year, 12, 26), name * " (Observed)")
    end
end

"""
`populate_nz!(days::Dict{Date,AbstractString}, region::AbstractString, observed::Bool, year::Int)`:
for each holiday, sets days[holidayDate] = holiday_name, for all holidays in the given year.
For new zealand, regions are provinces.

If observed is true, then when a holiday conflicts with a weekend and is legally observed on
another date, a seperate entry will be created for the observed date.

Returns:
- Nothing
"""
function populate_nz!(days::Dict{Date,AbstractString}, region::AbstractString,
                      observed::Bool, year::Int)
    # Holidays to research:
    # Bank Holidays Act 1873
    # The Employment of Females Act 1873
    # Factories Act 1894
    # Industrial Conciliation and Arbitration Act 1894
    # Labour Day Act 1899
    # Anzac Day Act 1920, 1949, 1956
    # New Zealand Day Act 1973
    # Waitangi Day Act 1960, 1976
    # Sovereign's Birthday Observance Act 1937, 1952
    # Holidays Act 1981, 2003
    if year < 1894
        return
    end

    # New Year's Day
    name = "New Year's Day"
    jan1 = Date(year, 1, 1)
    title(days, jan1, name)
    if observed && dayofweek(jan1) in WEEKEND
        title(days, Date(year, 1, 3), name * " (Observed)")
    end

    name = "Day after New Year's Day"
    jan2 = Date(year, 1, 2)
    title(days, jan2, name)
    if observed && dayofweek(jan2) in WEEKEND
        title(days, Date(year, 1, 4), name * " (Observed)")
    end

    # Waitangi Day
    if year > 1973
        name = "New Zealand Day"
        if year > 1976
            name = "Waitangi Day"
        end
        feb6 = Date(year, 2, 6)
        title(days, feb6, name)
        if observed && year >= 2014 && dayofweek(feb6) in WEEKEND
            title(days, add_day(feb6, Mon, 1), name * " (Observed)")
        end
    end

    # Easter
    title(days, sub_day(easter(year), Fri, 1), "Good Friday")
    title(days, add_day(easter(year), Mon, 1), "Easter Monday")

    # Anzac Day
    if year > 1920
        name = "Anzac Day"
        apr25 = Date(year, 4, 25)
        title(days, apr25, name)
        if observed && year >= 2014 && dayofweek(apr25) in WEEKEND
            title(days, add_day(apr25, Mon, 1), name * " (Observed)")
        end
    end

    # Sovereign's Birthday
    if year >= 1952
        name = "Queen's Birthday"
    elseif year > 1901
        name = "King's Birthday"
    end

    if year == 1952
        title(days, Date(year, 6, 2), name) # Elizabeth II
    elseif year > 1937
        title(days, add_day(Date(year, 6, 1), Mon, 1), name  ) # EII & GVI
    elseif year == 1937
        title(days, Date(year, 6, 9), name) # George VI
    elseif year == 1936
        title(days, Date(year, 6, 23), name) # Edward VIII
    elseif year > 1911
        title(days, Date(year, 6, 3), name) # George V
    elseif year > 1901
        # http://paperspast.natlib.govt.nz/cgi-bin/paperspast?a=d&d=NZH19091110.2.67
        title(days, Date(year, 11, 9), name) # Edward VII
    end

    # Labour Day
    name = "Labour Day"
    if year >= 1910
        title(days, add_day(Date(year, 10, 1),Mon,4), name)
    elseif year > 1899
        title(days, add_day(Date(year, 10, 1), Wed, 2), name)
    end

    # Christmas Day
    name = "Christmas Day"
    dec25 = Date(year, 12, 25)
    title(days, dec25, name)
    if observed && dayofweek(dec25) in WEEKEND
        title(days, Date(year, 12, 27), name * " (Observed)")
    end

    # Boxing Day
    name = "Boxing Day"
    dec26 = Date(year, 12, 26)
    title(days, dec26, name)
    if observed && dayofweek(dec26) in WEEKEND
        title(days, Date(year, 12, 28), name * " (Observed)")
    end

    # Province Anniversary Day
    if region in ("NTL", "Northland", "AUK", "Auckland")
        if 1963 < year <= 1973 && region in ("NTL", "Northland")
            name = "Waitangi Day"
            date = Date(year, 2, 6)
        else
            name = "Auckland Anniversary Day"
            date = Date(year, 1, 29)
        end

        title(days, nearest(date, Mon), name)
    elseif region in ("TKI", "Taranaki", "New Plymouth")
        name = "Taranaki Anniversary Day"
        title(days, add_day(Date(year, 3, 1), Mon, 2), name)
    elseif region in ("HKB", "Hawke's Bay")
        name = "Hawke's Bay Anniversary Day"
        labour_day = add_day(Date(year, 10, 1), Mon, 4)
        title(days, sub_day(labour_day, Fri, 1), name)

    elseif region in ("WGN", "Wellington")
        name = "Wellington Anniversary Day"
        jan22 = Date(year, 1, 22)
        title(days, nearest(jan22, Mon), name)

    elseif region in ("MBH", "Marlborough")
        name = "Marlborough Anniversary Day"
        date = add_day(Date(year, 10, 1), Mon, 5)
        title(days, date, name)
    elseif region in ("NSN", "Nelson")
        name = "Nelson Anniversary Day"
        feb1 = Date(year, 2, 1)
        title(days, nearest(feb1, Mon), name)
    elseif region in ("CAN", "Canterbury")
        name = "Canterbury Anniversary Day"
        showday = add_day(Date(year, 11, 1), Tue, 1)
        showday = add_day(showday, Fri, 2)
        title(days, showday, name)

    elseif region in ("STC", "South Canterbury")
        name = "South Canterbury Anniversary Day"
        dominion_day = add_day(Date(year, 9, 1), Mon, 4)
        title(days, dominion_day, name)
    elseif region in ("WTL", "Westland")
        name = "Westland Anniversary Day"
        dec1 = Date(year, 12, 1)
        # Observance varies?!?!
        if year == 2005     # special case?!?!
            title(days, Date(year, 12, 5), name)
        else
            title(days, nearest(dec1, Mon), name)
        end
    elseif region in ("OTA", "Otago")
        name = "Otago Anniversary Day"
        mar23 = Date(year, 3, 23)
        date = nearest(mar23, Mon)

        if date == add_day(easter(year), Mon, 1) # Avoid Easter Monday
            date = date + Dates.Day(1)
        end
        title(days, date, name)
    elseif region in ("STL", "Southland")
        name = "Southland Anniversary Day"
        jan17 = Date(year, 1, 17)
        if year > 2011
            title(days, add_day(easter(year), Tue, 1), name)
        else
            title(days, nearest(jan17, Mon), name)
        end
    elseif region in ("CIT", "Chatham Islands")
        name = "Chatham Islands Anniversary Day"
        nov30 = Date(year, 11, 30)
        title(days, nearest(nov30, Mon), name)
    end
end

"""
`populate_au!(days::Dict{Date,AbstractString}, region::AbstractString,
              observed::Bool, year::Int)`:
for each holiday, sets days[holidayDate] = holiday_name, for all holidays in the given year.
For Australia, regions are provinces.

If observed is true, then when a holiday conflicts with a weekend and is legally observed on
another date, a seperate entry will be created for the observed date.

Returns:
- Nothing
"""
function populate_au!(days::Dict{Date,AbstractString}, region::AbstractString,
                      observed::Bool, year::Int)
    # Holidays to research:
    # ACT:  Holidays Act 1958
    # NSW:  Public Holidays Act 2010
    # NT:   Public Holidays Act 2013
    # QLD:  Holidays Act 1983
    # SA:   Holidays Act 1910
    # TAS:  Statutory Holidays Act 2000
    # VIC:  Public Holidays Act 1993
    # WA:   Public and Bank Holidays Act 1972

    # TODO do more research on history of Aus holidays

    # New Year's Day
    name = "New Year's Day"
    jan1 = Date(year, 1, 1)
    title(days, jan1, name)
    if observed && dayofweek(jan1) in WEEKEND
        title(days, add_day(jan1, Mon, 1), name * " (Observed)")
    end

    # Australia Day
    jan26 = Date(year, 1, 26)
    if year >= 1935
        if region == "NSW" && year < 1946
            name = "Anniversary Day"
        else
            name = "Australia Day"
        end

        title(days, jan26, name)
        if observed && year >= 1946 && dayofweek(jan26) in WEEKEND
            title(days, add_day(jan26, Mon, 1), name * " (Observed)")
        end
    elseif year >= 1888 && region != "SA"
        name = "Anniversary Day"
        title(days, jan26, name)
    end

    # Adelaide Cup
    if region == "SA"
        name = "Adelaide Cup"
        if year >= 2006
            # subject to proclamation ?!?!
            title(days, add_day(Date(year, 3, 1), Mon, 2), name)
        else
            title(days, add_day(Date(year, 3, 1), Mon, 3), name)
        end
    end

    # Canberra Day
    if region == "ACT"
        name = "Canberra Day"
        title(days, add_day(Date(year, 3, 1), Mon, 1), name)
    end

    # Easter
    title(days, sub_day(easter(year), Fri, 1), "Good Friday")
    if region in ("ACT", "NSW", "NT", "QLD", "SA", "VIC")
        title(days, sub_day(easter(year), Sat, 1), "Easter Saturday")
    end

    if region == "NSW"
        title(days, easter(year), "Easter Sunday")
    end
    title(days, add_day(easter(year), Mon, 1), "Easter Monday")

    # Anzac Day
    if year > 1920
        name = "Anzac Day"
        apr25 = Date(year, 4, 25)
        title(days, apr25, name)
        if observed
            if dayofweek(apr25) == Sat && region in ("WA", "NT")
                title(days, add_day(apr25, Mon, 1), name * " (Observed)")
            elseif dayofweek(apr25) == Sun && region in ("ACT", "QLD", "SA", "WA", "NT")
                title(days, add_day(apr25, Mon, 1), name * " (Observed)")
            end
        end
    end

    # Western Australia Day
    if region == "WA" && year > 1832
        name = year >= 2015? "Western Australia Day" : "Foundation Day"
        title(days, add_day(Date(year, 6, 1), Mon, 1), name)
    end

    # Sovereign's Birthday
    if year >= 1952
        name = "Queen's Birthday"
    elseif year > 1901
        name = "King's Birthday"
    end
    if year >= 1936
        name = "Queen's Birthday"
        if region == "QLD"
            if year == 2012
                title(days, Date(year, 10, 1), name)
                title(days, Date(year, 6, 11), "Queen's Diamond Jubilee")
            else
                title(days, add_day(Date(year, 6, 1), Mon, 2), name)
            end
        elseif region == "WA"
            # by proclamation ?!?!
            title(days, sub_day(Date(year, 10, 1), Mon, 1), name)
        else
            title(days, add_day(Date(year, 6, 1), Mon, 2), name)
        end
    elseif year > 1911
        title(days, Date(year, 6, 3), name) # George V
    elseif year > 1901
        title(days, Date(year, 11, 9), name) # Edward VII
    end

    # Picnic Day
    if region == "NT"
        name = "Picnic Day"
        title(days, add_day(Date(year, 8, 1), Mon, 1), name)
    end

    # Labour Day
    name = "Labour Day"
    if region in ("NSW", "ACT", "SA")
        title(days, add_day(Date(year, 10, 1), Mon, 1), name)
    elseif region == "WA"
        title(days, add_day(Date(year, 3, 1), Mon, 1), name)
    elseif region == "VIC"
        title(days, add_day(Date(year, 3, 1), Mon, 2), name)
    elseif region == "QLD"
        if 2013 <= year <= 2015
            title(days, add_day(Date(year, 10, 1), Mon, 1), name)
        else
            title(days, add_day(Date(year, 5, 1), Mon, 1), name)
        end
    elseif region == "NT"
        name = "May Day"
        title(days, add_day(Date(year, 5, 1), Mon, 1), name)
    elseif region == "TAS"
        name = "Eight Hours Day"
        title(days, add_day(Date(year, 3, 1), Mon, 2), name)
    end

    # Family & Community Day
    if region == "ACT"
        name = "Family & Community Day"
        if 2007 <= year <= 2009
            title(days, add_day(Date(year, 11, 1), Tue, 1), name)
        elseif year == 2010
            # first Monday of the September/October school holidays
            # moved to the second Monday if this falls on Labour day
            # TODO need a formula for the ACT school holidays then
            # http://www.cmd.act.gov.au/communication/holidays
            title(days, Date(year, 9, 26), name)
        elseif year == 2011
            title(days, Date(year, 10, 10), name)
        elseif year == 2012
            title(days, Date(year, 10, 8), name)
        elseif year == 2013
            title(days, Date(year, 9, 30), name)
        elseif year == 2014
            title(days, Date(year, 9, 29), name)
        elseif year == 2015
            title(days, Date(year, 9, 28), name)
        elseif year == 2016
            title(days, Date(year, 9, 26), name)
        elseif 2017 <= year <= 2020
            labour_day = add_day(Date(year, 10, 1), Mon, 1)
            if year == 2017
                dt = add_day(Date(year, 9, 23), Mon, 1)
            elseif year == 2018
                dt = add_day(Date(year, 9, 29), Mon, 1)
            elseif year == 2019
                dt = add_day(Date(year, 9, 28), Mon, 1)
            elseif year == 2020
                dt = add_day(Date(year, 9, 26), Mon, 1)
            end
            if dt == labour_day
                dt = add_day(dt, Mon, 1)
            end
            title(days, Date(year, 9, 26), name)
        end
    end

    # Melbourne Cup
    if region == "VIC"
        name = "Melbourne Cup"
        title(days, add_day(Date(year, 11, 1), Tue, 1), name)
    end

    # Christmas Day
    name = "Christmas Day"
    dec25 = Date(year, 12, 25)
    title(days, dec25, name)
    if observed && dayofweek(dec25) in WEEKEND
        title(days, Date(year, 12, 27), name * " (Observed)")
    end

    # Boxing Day
    if region == "SA"
        name = "Proclamation Day"
    else
        name = "Boxing Day"
    end

    dec26 = Date(year, 12, 26)
    title(days, dec26, name)
    if observed && dayofweek(dec26) in WEEKEND
        title(days, Date(year, 12, 28), name * " (Observed)")
    end
end

"""
`populate_at!(days::Dict{Date,AbstractString}, region::AbstractString, observed::Bool, year::Int)`:
for each holiday, sets days[holidayDate] = holiday_name, for all holidays in the given year.
For Austria, regions are provinces.

Conflicting holidays are not observed on different dates in Austria, so the value of observed
has no effect.

Returns:
- Nothing
"""
function populate_at!(days::Dict{Date,AbstractString}, region::AbstractString, observed::Bool, year::Int)
    title(days, Date(year, 1, 1), "Neujahr")
    title(days, Date(year, 1, 6), "Heilige Drei Könige")
    title(days, add_day(easter(year), Mon, 1), "Ostermontag")
    title(days, Date(year, 5, 1), "Staatsfeiertag")

    title(days, easter(year) + Dates.Day(39), "Christi Himmelfahrt")
    title(days, easter(year) + Dates.Day(50), "Pfingstmontag")
    title(days, easter(year) + Dates.Day(60), "Fronleichnam")

    title(days, Date(year, 8, 15), "Maria Himmelfahrt")
    if 1919 <= year <= 1934
        title(days, Date(year, 11, 12), "Nationalfeiertag")
    end
    if year >= 1967
        title(days, Date(year, 10, 26), "Nationalfeiertag")
    end
    title(days, Date(year, 11, 1), "Allerheiligen")
    title(days, Date(year, 12, 8),  "Maria Empfängnis")
    title(days, Date(year, 12, 25), "Christtag")
    title(days, Date(year, 12, 26), "Stefanitag")

end

"""
`populate_de!(days::Dict{Date,AbstractString}, region::AbstractString,
              observed::Bool, year::Int)`:

for each holiday, sets days[holidayDate] = holiday_name, for all holidays in the given year.
For Germany, regions are provinces.

If observed is true, then when a holiday conflicts with a weekend and is legally observed on
another date, a seperate entry will be created for the observed date.

Returns:

- Nothing

Notes:

This class doesn't return any holidays before 1990-10-03.

Before that date the current Germany was separated into the "German
Democratic Republic" and the "Federal Republic of Germany" which both had
somewhat different holidays. It doesn't really make sense to include the
days from the two former countries.

Note that Germany doesn't have rules for holidays that happen on a
Sunday. Those holidays are still holiday days but there is no additional
day to make up for the "lost" day.

Also note that German holidays are partly declared by each province there
are some weired edge cases:

    - "Mariä Himmelfahrt" is only a holiday in Bavaria (BY) if your
      municipality is mothly catholic which in term depends on census data.
      Since we don't have this data but most municipalities in Bavaria
      *are* mostly catholic, we count that as holiday for whole Bavaria.

    - There is an "Augsburger Friedensfest" which only exists in the town
      Augsburg. This is excluded for Bavaria.

    - "Gründonnerstag" (Thursday before easter) is not a holiday but pupil
       don't have to go to school (but only in Baden Württemberg) which is
       solved by adjusting school holidays to include this day. It is
       excluded from our list.

    - "Fronleichnam" is a holiday in certain, explicitly defined
      municipalities in Saxony (SN) and Thuringia (TH). We exclude it from
      both provinces.
"""
function populate_de!(days::Dict{Date,AbstractString}, region::AbstractString,
         observed::Bool, year::Int)
    if year <= 1989
        return
    end

    if year > 1990
        title(days, Date(year, 1, 1), "Neujahr")

        if region in ("BW", "BY", "ST")
            title(days, Date(year, 1, 6), "Heilige Drei Könige")
        end

        title(days, easter(year) + Dates.Day(-2), "Karfreitag")

        if region == "BB"
            # will always be a Sunday and we have no "observed" rule so
            # this is pretty pointless but it's nonetheless an official holiday by law
            title(days, easter(year), "Ostern")
        end

        title(days, easter(year) + Dates.Day(1), "Ostermontag")
        title(days, Date(year, 5, 1), "Maifeiertag")
        title(days, easter(year) + Dates.Day(39), "Christi Himmelfahrt")

        if region == "BB"
            # will always be a Sunday and we have no "observed" rule so
            # this is pretty pointless but it's nonetheless an official holiday by law
            title(days, easter(year) + Dates.Day(49), "Pfingsten")
        end

        title(days, easter(year) + Dates.Day(50), "Pfingstmontag")

        if region in ("BW", "BY", "HE", "NW", "RP", "SL")
            title(days, easter(year) + Dates.Day(60), "Fronleichnam")
        end

        if region in ("BY", "SL")
            title(days, Date(year, 8, 15), "Mariä Himmelfahrt")
        end

        title(days, Date(year, 10, 3), "Tag der Deutschen Einheit")
    end

    if region in ("BB", "MV", "SN", "ST", "TH")
        title(days, Date(year, 10, 31), "Reformationstag")
    end

    if region in ("BW", "BY", "NW", "RP", "SL")
        title(days, Date(year, 11, 1), "Allerheiligen")
    end

    if region == "SN"
        # can be calculated as "last wednesday before year-11-23" which is
        # why we need to go back two wednesdays if year-11-23 happens to be a wednesday
        date = Dates.toprev(x->Dates.dayofweek(x) == Wed, Date(year, 11, 23))
        title(days, date, "Buß- und Bettag")
    end

    title(days, Date(year, 12, 25), "Erster Weihnachtstag")
    title(days, Date(year, 12, 26), "Zweiter Weihnachtstag")
end

const populators =  Dict{AbstractString, Function}(
    "US"=>populate_us!,
    "CA"=>populate_ca!,
    "MX"=>populate_mx!,
    "NZ"=>populate_nz!,
    "AU"=>populate_au!,
    "AT"=>populate_at!,
    "DE"=>populate_de!
)

"""
`holiday_cache(; country::AbstractString="CA", region::AbstractString="MB",
               expand::Bool=true, observed::Bool=true, years::Array{Int}=Int[])`:

Populates holiday cache for the given years, country, and region. If observed is true, then
alternative observed dates will be set as well. If expand is true, then whenever a lookup
is made for a non cached date, that year of holidays will be populated in the cache.

Returns:
- `HolidayBase`: The cache for future calls to lookup dates.
"""
function holiday_cache(; country::AbstractString="CA", region::AbstractString="MB",
                       expand::Bool=true, observed::Bool=true, years::Array{Int}=Int[])
    if !haskey(populators, country)
        valid = join(keys(populators))
        throw(ArgumentError("Invalid country \"$country\"; valid countries are: ", valid))
    end

    years = Set(years)
    holidays = Dict{Date,AbstractString}()
    populate = populators[country]

    #Generate cache for all specified years
    for year in years
        populate(holidays, region, observed, year)
    end

    HolidayBase(holidays, years, expand, observed, country, region)
end

"""
`day_name!(date::Date, holidays::HolidayBase)`: Find corresponding holiday names for a date.
If the given date is in the holiday cache this is a simple lookup. If it is not in cache,
and expand is enabled, then the new year will be populated. Otherwise this will
just return nothing.

Returns:
- `AbstractString`: Holiday name for the given date, or Void if day has no name.
"""
function day_name!(date::Date, holidays::HolidayBase)
    if holidays.expand && !(Dates.year(date) in holidays.years)
        populate = populators[holidays.country]
        populate(holidays.dates, holidays.region, holidays.observed, Dates.year(date))
        push!(holidays.years, Dates.year(date))
    end

    if haskey(holidays.dates, date)
        return holidays.dates[date]
    else
        return Void
    end
end

"""
`country_regions(country::AbstractString)`: For lookup of regions in a country

Returns:
- `Array{AbstractString,N}`: Recognized regions within a given country
"""
function country_regions(country::AbstractString)
    if haskey(regions, country)
        return regions[country]
    else
        throw(ArgumentError("Unknown Country: ",country))
    end
end

end

