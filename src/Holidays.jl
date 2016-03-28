VERSION >= v"0.4-" && __precompile__()

module Holidays

# Credits:

# This program closely borrows the logic for calculating most holidays from
# https://github.com/ryanss/holidays.py
# Calculating easter is done using a julia port of IanTaylorEasterJscr(year) from
# https://en.wikipedia.org/wiki/Computus#Algorithms

observed = true

# Shorthand

weekend = [Dates.Saturday, Dates.Sunday]
dayofweek = Dates.dayofweek
(Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday) = (Dates.Monday, Dates.Tuesday, Dates.Wednesday, Dates.Thursday, Dates.Friday, Dates.Saturday, Dates.Sunday)

type HolidayBase
    country::AbstractString
    region::AbstractString
    years::Set{Int}
    dates::Dict{Date,AbstractString}
end

function nthWeekday(start, weekday, count)
    Dates.tonext(start) do x
        dayofweek(x) == weekday &&
        Dates.dayofweekofmonth(x) == count
    end
end

function sub_day(date, weekday, count)
    if dayofweek(date) == weekday
        count = count -1
    end

    for i in range (0, count)
        date = Dates.toprev(x->Dates.dayofweek(x) == weekday, date)
    end

    return date
end

# Returns same date if this is is 'weekday'
function add_day(date, weekday, count)
    if dayofweek(date) == weekday
        count = count -1
    end

    for i in range (0, count)
        date = Dates.tonext(x->Dates.dayofweek(x) == weekday, date)
    end

    return date
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

function title(cache, date, day)
    # If holiday already has a name, prepend the new one with a ,
    if haskey(cache, date)
        cache[date] = day * ", " * cache[date]
    else
        cache[date] = day
    end
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
        title(days, date, name)

        if observed
            if dayofweek(date) == Dates.Sunday
                title(days, date + Dates.Day(1), name * " (Observed)")
            elseif dayofweek(date) == Dates.Saturday
                title(days, date + Dates.Day(-1), name * " (Observed)")
            end
        end

        # The next year's observed New Year's Day can be in this year
        # when it falls on a Friday (Jan 1st is a Saturday)
        if observed && dayofweek(Date(year, 12, 31)) == Dates.Friday
            title(days, Date(year, 12, 31), name * " (Observed)")
        end
    end

    # Islander Day
    if region == "PE" && year >= 2010
        # third monday of february
        # title(days, nthWeekday(Date(year, 2, 1), Dates.Monday, 3) , "Islander Day")
        title(days, add_day(Date(year, 2), Monday, 3) , "Islander Day")

    elseif region == "PE" && year == 2009
        # 2nd monday of february
        # title(days, nthWeekday(Date(year, 2, 1), Dates.Monday, 2) , "Islander Day")
        title(days, add_day(Date(year, 2), Monday, 2) , "Islander Day")
    end

    # Family Day / Louis Riel Day (MB)
    feb1 = Date(year, 2, 1)
    if region in ["AB", "SK", "ON"] && year >= 2008
        title(days, nthWeekday(feb1, Dates.Monday, 3) , "Family Day")
    elseif region in ["AB", "SK"] && year >= 2007
        title(days, nthWeekday(feb1, Dates.Monday, 3) , "Family Day")
    elseif region == "AB" && year >= 1990
        title(days, nthWeekday(feb1, Dates.Monday, 3) , "Family Day")
    elseif region == "BC" && year >= 2013
        title(days, nthWeekday(feb1, Dates.Monday, 2) , "Family Day")
    elseif region == "MB" && year >= 2008
        title(days, nthWeekday(feb1, Dates.Monday, 3) , "Louis Riel Day")
    end

    # St. Patrick's Day
    if region == "NL" && year >= 1900
        title(days, nearest(Date(year, 3, 17), Dates.Monday), "St. Patrick's Day")
    end

    # Good Friday
    if region != "QC" && year >= 1867
        title(days,  Dates.toprev(x->Dates.dayofweek(x) == Dates.Friday, easter(year)) , "Good Friday")
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
        title(days, nearest(Date(year, 4, 23), Dates.Monday), "St. George's Day")
    end

    # Victoria Day / National Patriotes Day (QC)
    if !(region in ["NB", "NS", "PE", "NL", "QC"]) && year >= 1953
        date = prev_weekday(Date(year, 5, 24), Dates.Monday)
        title(days, date, "Victoria Day")

    elseif region == "QC" && year >= 1953
        date = prev_weekday(Date(year, 5, 24), Dates.Monday)
        title(days, date, "National Patriotes Day")
    end

    # National Aboriginal Day
    if region == "NT" && year >= 1996
        title(days, Date(year, 6, 21), "National Aboriginal Day")
    end

    # St. Jean Baptiste Day
    if region == "QC" && year >= 1925
        title(days, Date(year, 6, 24), "St. Jean Baptiste Day")
        if observed && dayofweek(Date(year, 6, 24)) == Dates.Sunday
            title(days, Date(year, 6, 25), "St. Jean Baptiste Day (Observed)")
        end
    end

    # Discovery Day
    if region == "NL" && year >= 1997
        title(days,  nearest(Date(year, 6, 24), Dates.Monday) , "Discovery Day")

    elseif region == "YU" && year >= 1912
        title(days, nthWeekday(Date(year, 8, 1), Dates.Monday, 3) , "Discovery Day")
    end

    # Canada Day / Memorial Day (NL)
    if region != "NL" && year >= 1867
        date = Date(year, 7, 1)
        name = "Canada Day"
        title(days, date, name)
        if observed && dayofweek(date) in weekend
            title(days, next_weekday(date, Dates.Monday), name * " (Observed)")
        end

    elseif year >= 1867
        name = "Memorial Day"
        date = Date(year, 7, 1)

        title(days, date, name)
        if observed && dayofweek(date) in weekend
            title(days, next_weekday(date, Dates.Monday), name * " (Observed)")
        end
    end

    # Nunavut Day
    if region == "NU" && year >= 2001
        title(days, Date(year, 7, 9), "Nunavut Day")
        if observed && dayofweek(Date(year, 7, 9)) == Dates.Sunday
            title(days, Date(year, 7, 10), "Nunavut Day (Observed)")
        end
    elseif region == "NU" && year == 2000
        title(days, Date(2000, 4, 1), "Nunavut Day")
    end

    # Civic Holiday / British Columbia Day
    if region in ["SK", "ON", "MB", "NT"] && year >= 1900
        title(days, next_weekday(Date(year, 8, 1), Dates.Monday), "Civic Holiday")

    elseif region == "BC" && year >= 1974
        title(days, next_weekday(Date(year, 8, 1), Dates.Monday), "British Columbia Day")
    end

     # Labour Day
    if year >= 1894
        title(days, next_weekday(Date(year, 9, 1), Dates.Monday), "Labour Day")
    end

    # Thanksgiving
    if !(region in ["NB", "NS", "PE", "NL"]) && year >= 1931
        title(days, nthWeekday(Date(year, 10, 1), Dates.Monday, 2) , "Thanksgiving")
    end

     # Remembrance Day
    name = "Remembrance Day"
    provinces = ["ON", "QC", "NS", "NL", "NT", "PE", "SK"]
    if ! (region in provinces) && year >= 1931
        title(days, Date(year, 11, 11), name)

    elseif region in ["NS", "NL", "NT", "PE", "SK"] && year >= 1931
        title(days, Date(year, 11, 11), name)
        if observed && dayofweek(Date(year, 11, 11)) == Dates.Sunday
            name = name * " (Observed)"
            title(days, next_weekday(Date(year, 11, 11), Dates.Monday), name)
        end
    end

     # Christmas Day
    if year >= 1867
        title(days, Date(year, 12, 25), "Christmas Day")
        if observed && dayofweek(Date(year, 12, 25)) == Dates.Saturday
            title(days, Date(year, 12, 24), "Christmas Day (Observed)")

        elseif observed && dayofweek(Date(year, 12, 25)) == Dates.Sunday
            title(days, Date(year, 12, 26), "Christmas Day (Observed)")
        end
    end

    # Boxing Day
    if year >= 1867
        name = "Boxing Day"
        name_observed = name * " (Observed)"
        if observed && dayofweek(Date(year, 12, 26)) in weekend
            title(days, next_weekday(Date(year, 12, 26), Dates.Monday), name_observed)

        elseif observed && dayofweek(Date(year, 12, 26)) == Dates.Monday
            title(days, Date(year, 12, 27), name_observed)
        else
            title(days, Date(year, 12, 26), name)
        end
    end
end

function populate_us(days::Dict{Date,AbstractString}, region::AbstractString, year::Int)
    # New Year's Day
    if year > 1870
        name = "New Year's Day"
        date = Date(year, 1, 1)
        title(days, date, name)

        if observed
            if dayofweek(date) == Dates.Sunday
                title(days, date + Dates.Day(1), name * " (Observed)")
            elseif dayofweek(date) == Dates.Saturday
                title(days, date + Dates.Day(-1), name * " (Observed)")
            end
        end

        # The next year's observed New Year's Day can be in this year
        # when it falls on a Friday (Jan 1st is a Saturday)
        if observed && dayofweek(Date(year, 12, 31)) == Dates.Friday
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
        date = add_day(date, Dates.Monday, 3)
        date = sub_day(date, Dates.Friday, 1)
        title(days, date, name)
    elseif region == "VA" && year >= 1983
        date = Date(year, 1, 1)
        date = add_day(date, Dates.Monday, 3)
        title(days, date, name)

    elseif region == "VA" && year >= 1889
        title(days, Date(year, 1, 19), name)
    end

    # Inauguration Day
    if region in ("DC", "LA", "MD", "VA") && year >= 1789
        name = "Inauguration Day"
        if (year - 1789) % 4 == 0 && year >= 1937
            title(days, Date(year, 1, 20), name)
            if dayofweek(Date(year, 1, 20)) == Sunday
                title(days, Date(year, 1, 21), name * " (Observed)")
            end
        elseif (year - 1789) % 4 == 0
            title(days, Date(year, 3, 4), name)
            if dayofweek(Date(year, 3, 4)) == Sunday
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
            title(days, add_day(Date(year), Dates.Monday, 3), name)
        end
    end

    # Lincoln's Birthday
    name = "Lincoln's Birthday"
    if (region in ("CT", "IL", "IA", "NJ", "NY") && year >= 1971) ||
            (region == "CA" && year >= 1971 && year <= 2009)

        title(days, Date(year, 2, 12), name)

        if observed && dayofweek(Date(year, 2, 12)) == Saturday
            title(days, Date(year, 2, 11), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 2, 12)) == Sunday
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
            # title(days, Date(year, 2, 1) + rd(weekday=MO(+3)), name)
            title(days, add_day(Date(year, 2), Monday, 3), name)
        elseif year >= 1879
            title(days, Date(year, 2, 22), name)
        end
    elseif region == "GA"
        if dayofweek(Date(year, 12, 24)) != Wednesday
            title(days, Date(year, 12, 24), name)
        else
            title(days, Date(year, 12, 26), name)
        end
    elseif region in ("PR", "VI")
        # title(days, Date(year, 2, 1) + rd(weekday=MO(+3)), name)
        title(days, add_day(Date(year, 2), Dates.Monday, 3), name)
    end

    # Mardi Gras
    if region == "LA" && year >= 1857
        # title(days, easter(year) + rd(days=-47), "Mardi Gras")
        title(days, easter(year) + Dates.Day(-47), "Mardi Gras")
    end

    # Guam Discovery Day
    if region == "GU" && year >= 1970
        # title(days, Date(year, 3, 1) + rd(weekday=MO), "Guam Discovery Day")
        title(days, add_day(Date(year, 3, 1), Dates.Monday, 1), "Guam Discovery Day")
    end

    # Casimir Pulaski Day
    if region == "IL" && year >= 1978
        title(days, add_day(Date(year, 3), Monday, 1), "Casimir Pulaski Day")
    end

    # Texas Independence Day
    if region == "TX" && year >= 1874
        title(days, Date(year, 3, 2), "Texas Independence Day")
    end

    # Town Meeting Day
    if region == "VT" && year >= 1800
        # title(days, Date(year, 3, 1) + rd(weekday=TU), "Town Meeting Day")
        title(days, add_day(Date(year, 3), Dates.Tuesday, 1), "Town Meeting Day")
    end

    # Evacuation Day
    if region == "MA" && year >= 1901
        name = "Evacuation Day"
        title(days, Date(year, 3, 17), name)
        if dayofweek(Date(year, 3, 17)) in weekend
            # title(days, Date(year, 3, 17) + rd(weekday=MO), name * " (Observed)")
            title(days, add_day(Date(year, 3, 17), Monday, 1), name * " (Observed)")
        end
    end

    # Emancipation Day
    if region == "PR"
        title(days, Date(year, 3, 22), "Emancipation Day")
        if observed && dayofweek(Date(year, 3, 22)) == Dates.Sunday
            title(days, Date(year, 3, 23), "Emancipation Day (Observed)")
        end
    end

    # Prince Jonah Kuhio Kalanianaole Day
    if region == "HI" && year >= 1949
        name = "Prince Jonah Kuhio Kalanianaole Day"
        title(days, Date(year, 3, 26), name)
        if observed && dayofweek(Date(year, 3, 26)) == Dates.Saturday
            title(days, Date(year, 3, 25), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 3, 26)) == Dates.Sunday
            title(days, Date(year, 3, 27), name * " (Observed)")
        end
    end

    # Steward's Day
    name = "Steward's Day"
    if region == "AK" && year >= 1955
        # title(days, Date(year, 4, 1) + rd(days=-1, weekday=MO(-1)), name)
        date = Date(year, 4, 1) + Dates.Day(-1)
        title(days, sub_day(date, Monday, 1), name)
    elseif region == "AK" && year >= 1918
        title(days, Date(year, 3, 30), name)
    end

    # César Chávez Day
    name = "César Chávez Day"
    if region == "CA" && year >= 1995
        title(days, Date(year, 3, 31), name)
        if observed && dayofweek(Date(year, 3, 31)) == Dates.Sunday
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
        if observed && dayofweek(Date(year, 4, 16)) == Dates.Saturday
            title(days, Date(year, 4, 15), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 4, 16)) == Dates.Sunday
            title(days, Date(year, 4, 17), name * " (Observed)")
        end
    end

    # Patriots' Day
    if region in ("ME", "MA") && year >= 1969
        # title(days, Date(year, 4, 1) + rd(weekday=MO(+3)), "Patriots' Day")
        title(days, add_day(Date(year, 4, 1), Monday, 3), "Patriots' Day")
    elseif region in ("ME", "MA") && year >= 1894
        title(days, Date(year, 4, 19), "Patriots' Day")
    end

    # Holy Thursday
    if region == "VI"
        # title(days, easter(year) + rd(weekday=TH(-1)), "Holy Thursday")
        title(days, sub_day(easter(year), Thursday, 1), "Holy Thursday")
    end

    # Good Friday
    if region in ("CT", "DE", "GU", "IN", "KY", "LA",
                  "NJ", "NC", "PR", "TN", "TX", "VI")
        # title(days, easter(year) + rd(weekday=FR(-1)), "Good Friday")
        title(days, sub_day(easter(year), Friday, 1), "Good Friday")
    end

    # Easter Monday
    if region == "VI"
        # title(days, easter(year) + rd(weekday=MO), "Easter Monday")
        title(days, add_day(easter(year), Monday, 1), "Easter Monday")
    end

    # Confederate Memorial Day
    name = "Confederate Memorial Day"
    if region in ("AL", "GA", "MS", "SC") && year >= 1866
        # title(days, Date(year, 4, 1) + rd(weekday=MO(+4)), name)
        title(days, add_day(Date(year, 4), Monday, 4), name)
    elseif region == "TX" && year >= 1931
        title(days, Date(year, 1, 19), name)
    end

    # San Jacinto Day
    if region == "TX" && year >= 1875
        title(days, Date(year, 4, 21), "San Jacinto Day")
    end

    # Arbor Day
    if region == "NE" && year >= 1989
        # title(days, Date(year, 4, 30) + rd(weekday=FR(-1)), "Arbor Day")
        title(days, sub_day(Date(year, 4, 30), Friday, 1), "Arbor Day")
    elseif region == "NE" && year >= 1875
        title(days, Date(year, 4, 22), "Arbor Day")
    end

    # Primary Election Day
    if region == "IN" && ((year >= 2006 && year % 2 == 0) ||
                           year >= 2015)
        # dt = Date(year, 5, 1) + rd(weekday=MO)
        dt = add_day(Date(year, 5), Monday, 1)
        title(days, dt + Dates.Day(1), "Primary Election Day")
    end

    # Truman Day
    if region == "MO" && year >= 1949
        name = "Truman Day"
        title(days, Date(year, 5, 8), name)
        if observed && dayofweek(Date(year, 5, 8)) == Dates.Saturday
            title(days, Date(year, 5, 7), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 5, 8)) == Dates.Sunday
            title(days, Date(year, 5, 10), name * " (Observed)")
        end
    end

    # Memorial Day
    if year > 1970
        # title(days, Date(year, 5, 31) + rd(weekday=MO(-1)), "Memorial Day")
        title(days, sub_day(Date(year, 5, 31), Monday, 1), "Memorial Day")
    elseif year >= 1888
        title(days, Date(year, 5, 30), "Memorial Day")
    end

    # Jefferson Davis Birthday
    name = "Jefferson Davis Birthday"
    if region == "AL" && year >= 1890
        # title(days, Date(year, 6, 1) + rd(weekday=MO), name)
        title(days, add_day(Date(year, 6), Monday, 1), name)
    end

    # Kamehameha Day
    if region == "HI" && year >= 1872
        title(days, Date(year, 6, 11), "Kamehameha Day")
        if observed && year >= 2011
            if dayofweek(Date(year, 6, 11)) == Dates.Saturday
                title(days, Date(year, 6, 10), "Kamehameha Day (Observed)")
            elseif dayofweek(Date(year, 6, 11)) == Dates.Sunday
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
        if observed && dayofweek(Date(year, 6, 20)) == Dates.Saturday
            title(days, Date(year, 6, 19), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 6, 20)) == Dates.Sunday
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
        if observed && dayofweek(Date(year, 7, 4)) == Dates.Saturday
            # title(days, Date(year, 7, 4) + rd(days=-1), name * " (Observed)")
            title(days, Date(year, 7, 3), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 7, 4)) == Dates.Sunday
            # title(days, Date(year, 7, 4) + rd(days=+1), name * " (Observed)")
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
        if observed && dayofweek(Date(year, 7, 24)) == Dates.Saturday
            # title(days, Date(year, 7, 24) + rd(days=-1), name * " (Observed)")
            title(days, Date(year, 7, 23), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 7, 24)) == Dates.Sunday
            # title(days, Date(year, 7, 24) + rd(days=+1), name * " (Observed)")
            title(days, Date(year, 7, 25), name * " (Observed)")
        end
    end

    # Constitution Day
    if region == "PR"
        title(days, Date(year, 7, 25), "Constitution Day")
        if observed && dayofweek(Date(year, 7, 25)) == Dates.Sunday
            title(days, Date(year, 7, 26), "Constitution Day (Observed)")
        end
    end

    # Victory Day
    if region == "RI" && year >= 1948
        # title(days, Date(year, 8, 1) + rd(weekday=MO(+2)), "Victory Day")
        title(days, add_day(Date(year, 8), Monday, 2), "Victory Day")
    end

    # Statehood Day (Hawaii)
    if region == "HI" && year >= 1959
        # title(days, Date(year, 8, 1) + rd(weekday=FR(+3)), "Statehood Day")
        title(days, add_day(Date(year, 8), Friday, 3), "Statehood Day")
    end

    # Bennington Battle Day
    if region == "VT" && year >= 1778
        name = "Bennington Battle Day"
        title(days, Date(year, 8, 16), name)
        if observed && dayofweek(Date(year, 8, 16)) == Dates.Saturday
            title(days, Date(year, 8, 15), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 8, 16)) == Dates.Sunday
            title(days, Date(year, 8, 17), name * " (Observed)")
        end
    end

    # Lyndon Baines Johnson Day
    if region == "TX" && year >= 1973
        title(days, Date(year, 8, 27), "Lyndon Baines Johnson Day")
    end

    # Labor Day
    if year >= 1894
        # title(days, Date(year, 9, 1) + rd(weekday=MO), "Labor Day")
        title(days, add_day(Date(year, 9, 1), Monday, 1), "Labor Day")
    end

    # Columbus Day
    if ! (region in ("AK", "DE", "FL", "HI", "NV"))
        if region == "SD"
            name = "Native American Day"
        elseif region == "VI"
            name = "Columbus Day and Puerto Rico Friendship Day"
        else
            name = "Columbus Day"
        end

        if year >= 1970
            # title(days, Date(year, 10, 1) + rd(weekday=MO(+2)), name)
            title(days, add_day(Date(year, 10), Monday, 2), name)
        elseif year >= 1937
            title(days, Date(year, 10, 12), name)
        end
    end

    # Alaska Day
    if region == "AK" && year >= 1867
        title(days, Date(year, 10, 18), "Alaska Day")
        if observed && dayofweek(Date(year, 10, 18)) == Dates.Saturday
            title(days, Date(year, 10, 17), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 10, 18)) == Dates.Sunday
            title(days, Date(year, 10, 19), name * " (Observed)")
        end
    end

    # Nevada Day
    if region == "NV" && year >= 1933
        date = Date(year, 10, 31)
        if year >= 2000
            # dt += rd(weekday=FR(-1))
            date = sub_day(date, Friday, 1)
        end

        title(days, date, "Nevada Day")
        if observed && dayofweek(date) == Saturday
            title(days, date + Dates.Day(-1), "Nevada Day (Observed)")
        elseif observed && dayofweek(date) == Sunday
            title(days, date + Dates.Day(1), "Nevada Day (Observed)")
        end
    end

    # Liberty Day
    if region == "VI"
        title(days, Date(year, 11, 1), "Liberty Day")
    end

    # Election Day
    if (region in ("DE", "HI", "IL", "IN", "LA",
                        "MT", "NH", "NJ", "NY", "WV") &&
                year >= 2008 && year % 2 == 0) ||
            (region in ("IN", "NY") && year >= 2015)

        # dt = Date(year, 11, 1) + rd(weekday=MO)
        dt = add_day(Date(year, 11), Monday, 1)
        title(days, dt + Dates.Day(1), "Election Day")
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
        title(days, add_day(Date(year, 10), Monday, 4), name)
    elseif year >= 1938
        title(days, Date(year, 11, 11), name)

        if observed && dayofweek(Date(year, 11, 11)) == Dates.Saturday
            title(days, Date(year, 11, 10), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 11, 11)) == Dates.Sunday
            title(days, Date(year, 11, 12), name * " (Observed)")
        end
    end

    # Discovery Day
    if region == "PR"
        title(days, Date(year, 11, 19), "Discovery Day")
        if observed && dayofweek(Date(year, 11, 19)) == Dates.Sunday
            title(days, Date(year, 11, 20), "Discovery Day (Observed)")
        end
    end

    # Thanksgiving
    if year > 1870
        # title(days, Date(year, 11, 1) + rd(weekday=TH(+4)), "Thanksgiving")
        title(days, add_day(Date(year, 11), Thursday, 4), "Thanksgiving")
    end

    # Day After Thanksgiving
    # Friday After Thanksgiving
    # Lincoln's Birthday
    # American Indian Heritage Day
    # Family Day
    # New Mexico Presidents' Day
    if (region in ("DE", "FL", "NH", "NC", "OK", "TX", "WV") && year >= 1975) ||
            (region == "IN" && year >= 2010) ||
            (region == "MD" && year >= 2008) ||
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

        # dt = Date(year, 11, 1) + rd(weekday=TH(+4))
        dt = add_day(Date(year, 11, 1), Thursday, 4)
        # title(days, dt + rd(days=+1), name)
        title(days, dt + Dates.Day(1), name)
    end

    # Robert E. Lee's Birthday
    if region == "GA" && year >= 2012
        name = "Robert E. Lee's Birthday"
        # title(days, Date(year, 11, 29) + rd(weekday=FR(-1)), name)
        title(days, sub_day( Date(year, 11, 29), Friday, 1), name)
    end

    # Lady of Camarin Day
    if region == "GU"
        title(days, Date(year, 12, 8), "Lady of Camarin Day")
    end

    # Christmas Eve
    if region == "AS" ||
            (region in ("KS", "MI", "NC") && year >= 2013) ||
            (region == "TX" && year >= 1981) ||
            (region == "WI" && year >= 2012)

        name = "Christmas Eve"
        title(days, Date(year, 12, 24), name)
        name = name * " (Observed)"
        # If on Friday, observed on Thursday
        if observed && dayofweek(Date(year, 12, 24)) == Dates.Friday
            title(days, Date(year, 12, 23), name)
        # If on Saturday or Sunday, observed on Friday
        elseif observed && dayofweek(Date(year, 12, 24)) in weekend
            # title(days, Date(year, 12, 24) + rd(weekday=FR(-1)), name)
            title(days, sub_day(Date(year, 12, 24), Friday, 1), name)
        end
    end

    # Christmas Day
    if year > 1870
        name = "Christmas Day"
        title(days, Date(year, 12, 25), "Christmas Day")
        if observed && dayofweek(Date(year, 12, 25)) == Dates.Saturday
            title(days, Date(year, 12, 24), name * " (Observed)")
        elseif observed && dayofweek(Date(year, 12, 25)) == Dates.Sunday
            title(days, Date(year, 12, 26), name * " (Observed)")
        end
    end

    # Day After Christmas
    if region == "NC" && year >= 2013
        name = "Day After Christmas"
        title(days, Date(year, 12, 26), name)
        name = name * " (Observed)"
        # If on Saturday or Sunday, observed on Monday
        if observed && dayofweek(Date(year, 12, 26)) in weekend
            # title(days, Date(year, 12, 26) + rd(weekday=MO), name)
            title(days, add_day(Date(year, 12, 26), Monday, 1), name)

        # If on Monday, observed on Tuesday
        elseif observed && dayofweek(Date(year, 12, 26)) == Dates.Monday
            title(days, Date(year, 12, 27), name)
        end
    elseif region == "TX" && year >= 1981
        title(days, Date(year, 12, 26), "Day After Christmas")
    elseif region == "VI"
        title(days, Date(year, 12, 26), "Christmas Second Day")
    end

    # New Year's Eve
    if (region in ("KY", "MI") && year >= 2013) ||
            (region == "WI" && year >= 2012)

        name = "New Year's Eve"
        title(days, Date(year, 12, 31), name)
        if observed && dayofweek(Date(year, 12, 31)) == Dates.Saturday
            title(days, Date(year, 12, 30), name * " (Observed)")
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

populators =  Dict{AbstractString, Function}(
    "US"=>populate_us,
    "CA"=>populate_canadian
)

function Cache(; country="CA", region="MB", years::Array{Int}=Int[])
    years = Set(years)

    holidays = Dict{Date,AbstractString}()
    populate = populators[country]

    for year in years
        populate(holidays, region, year)
    end

    HolidayBase(country, region, years, holidays)
end

function dayName(date::Date, holidays::HolidayBase)
    # Exp&& dict
    if !(Dates.year(date) in holidays.years)
        populate = populators[holidays.country]

        # populate_canadian(holidays.dates, holidays.region, Dates.year(date))
        populate(holidays.dates, holidays.region, Dates.year(date))
        push!(holidays.years, Dates.year(date))
    end

    if haskey(holidays.dates, date)
        return holidays.dates[date]
    else
        return Void
    end
end

end

