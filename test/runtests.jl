using Base.Test
using PyCall
using Holidays
using Compat

import Base.Dates: Mon, Tue, Wed, Thu, Fri, Sat, Sun, dayofweek, tonext, toprev

#Force load of python module in current directory
unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport pyholiday

# Constants

# Add regions to test here
regions = Dict(
    # Working Regions
    "CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"],
    "US"=>["AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "GU",
            "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MH", "MA", "MI",
            "FM", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND",
            "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT",
            "VT", "VA", "VI", "WA", "WV", "WI", "WY"],
    "MX"=>[""],
    "NZ"=>["NTL", "AUK", "TKI", "HKB", "WGN", "MBH", "NSN",
           "CAN", "STC", "WTL", "OTA", "STL", "CIT"],
    "AU" => ["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"],
    "AT" => ["B", "K", "N", "O", "S", "ST", "T", "V", "W"],
    "DE" => ["BW", "BY", "BE", "BB", "HB", "HH", "HE", "MV", "NI",
             "NW", "RP", "SL", "SN", "ST", "SH", "TH"],
)

function day_names_equal(x, y)
    if isa(x, AbstractString) && isa(y, AbstractString)
        return x == y
    elseif !isa(x, AbstractString) && !isa(y, AbstractString)
        return true
    else
        return false
    end
end

function expected_difference(country, province, date, python_name, julia_name)
    """
    Whenever you wish to allow a difference between the python and julia results, add it here.
    """
    if country == "CA" && province == "QC" && date >= Date(1953) &&
            python_name == "National Patriotes Day" &&
            julia_name == "National Patriots' Day"
        return true
    else
        return false
    end
end

function compare_holidays(country, province, observed, start_date, end_date)
    success = true

    dates = holiday_cache(country=country, region=province, observed=observed,
                          expand=true, years=[2016])
    pyholiday.load(country, province, observed, true, [2016])

    date = start_date
    x = 0
    y = 0

    try
        while date < end_date
            x = pyholiday.get(date)
            y = day_name!(date, dates)

            if !day_names_equal(x, y)
                # For dates where holidays.py is wrong / uses a different name, no error.
                if expected_difference(country, province, date, x, y)

                else
                    println("       Failure on ",date, " - Python: \"",x,"\", Julia: \"",y,"\"")
                    success = false
                end

            # If you want a record of successfully matched holidays as well, uncomment this.
            #elseif isa(x, AbstractString) && isa(y, AbstractString)
            #    println("       Success on ",date, " - Python: \"",x,"\", Julia: \"",y,"\"")
            end

            date = date + Dates.Day(1)
        end

    catch e
        success = false
        whos()
        println("Error",e)
        println("Value of X",x)
        println("Value of Y",y)
        println("Last date tried:",date)

        x = pyholiday.get(date)
        y = day_name!(date, dates)

        println("Value of X",x)
        println("Value of Y",y)

    end

    return success
end

function verify_all_holidays()
    println("Looping the following regions:", regions)

    # Set first and last date in loop
    # 1890 to 2030 will ensure high test coverage for all lines of code
    #~ start_date = Date(1890, 1, 1)
    start_date = Date(1890, 1, 1)
    end_date = Date(2030, 1, 1)

    println("Start Date:",start_date)
    println("Last Date:",end_date)

    for (country, provinces) in regions
        println("Testing ",country)
        for province in provinces
            println("   Country: ",country, ", Province: ",province)
            @test compare_holidays(country, province, true, start_date, end_date)
            @test compare_holidays(country, province, false, start_date, end_date)
        end
    end
end

function compare_holidays_no_expand(country, province, observed, start_date, end_date)
    success = true

    dates = holiday_cache(country=country, region=province, observed=observed,
                          expand=false, years=[2001, 2002, 2004])
    pyholiday.load(country, province, observed, false, [2001, 2002, 2004])

    date = start_date
    x = 0
    y = 0

    try
        while date < end_date
            x = pyholiday.get(date)
            y = day_name!(date, dates)

            if !day_names_equal(x, y)
                # For dates where holidays.py is wrong / uses a different name, no error
                if expected_difference(country, province, date, x, y)

                else
#~                     println("       Failure on ",date, " - Python: \"",x,"\", Julia: \"",y,"\"")
                    println("       Failure on $date - Python '$x', Julia '$y'")
                    success = false
                end
            #elseif isa(x, AbstractString) && isa(y, AbstractString)
            #    println("       Success on ",date, " - Python: \"",x,"\", Julia: \"",y,"\"")
            end

            date = date + Dates.Day(1)
        end

    catch e
        success = false
        whos()
        println("Error",e)
        println("Value of X",x)
        println("Value of Y",y)
        println("Last date tried:",date)

        x = pyholiday.get(date)
        y = day_name!(date, dates)

        println("Value of X",x)
        println("Value of Y",y)

    end

    return success
end

function test_no_expand()
    """
    When expand is off, all years passed at the start should be populated.
    All years NOT passed should return nothing.
    """

    println("Testing disabled expansion")

    start_date = Date(2000, 1, 1)
    end_date = Date(2005, 1, 1)

    println("Start Date:",start_date)
    println("Last Date:",end_date)

    for (country, provinces) in regions
        println("Testing ",country)
        for province in provinces
            println("   Country: ",country, ", Province: ",province)
            @test compare_holidays_no_expand(country, province, true, start_date, end_date)
            @test compare_holidays_no_expand(country, province, false, start_date, end_date)
        end
    end
end

function test_easter()
    println("Testing easter")
    success = true

    # Hard coded known correct dates for easter - Will be compared to my calculated version.
    # Taken from https://en.wikipedia.org/wiki/List_of_dates_for_Easter
    # Only tests western gregorian calendar at present. Function does not support eastern yet.
    # Format:
    # Year  Western_month Western_day Eastern_month Eastern_day
    easter_table = """
    1996    04 7     04 14
    1997    03 30    04 27
    1998    04 12    04 19
    1999    04 4     04 11
    2000    04 23    04 30
    2001    04 15    04 15
    2002    03 31    05 5
    2003    04 20    04 27
    2004    04 11    04 11
    2005    03 27    05 1
    2006    04 16    04 23
    2007    04 8     04 8
    2008    03 23    04 27
    2009    04 12    04 19
    2010    04 4     04 4
    2011    04 24    04 24
    2012    04 8     04 15
    2013    03 31    05 5
    2014    04 20    04 20
    2015    04 5     04 12
    2016    03 27    05 1
    2017    04 16    04 16
    2018    04 1     04 8
    2019    04 21    04 28
    2020    04 12    04 19
    2021    04 4     05 2
    2022    04 17    04 24
    2023    04 9     04 16
    2024    03 31    05 5
    2025    04 20    04 20
    2026    04 5     04 12
    2027    03 28    05 2
    2028    04 16    04 16
    2029    04 1     04 8
    2030    04 21    04 28
    2031    04 13    04 13
    2032    03 28    05 2
    2033    04 17    04 24
    2034    04 9     04 9
    2035    03 25    04 29
    2036    04 13    04 20
    """

    easter_strs = split(strip(easter_table), "\n")

    for line in easter_strs
        (year, west_month, west_day, east_month, east_day) = split(strip(line), r"\s+")
        west_string = "$year-$west_month-$west_day"
        west_date = Date(west_string)

        calculated_easter = Holidays.easter(Dates.year(west_date))

        if west_date != calculated_easter
            success = false
            println("Errror calculating western easter date")
            println("  Wikipedia's value: ",Dates.format(west_date, "yyyy u dd"))
            println("  Estimated value  : ",Dates.format(calculated_easter, "yyyy u dd"))
        end
    end

    @test success == true
end

function test_date_functions()
    println("Testing date functions")
    ## Test 1: Adding mondays to monday
    date = Date(1990)
    #This should be a monday, testing just in case.
    @test dayofweek(date) == Mon
    # This should resolve to the same date
    next_monday = Holidays.add_day(date, Mon, 1)
    @test next_monday - date == Base.Dates.Day(0)
    #If count is 1, goes ahead a week
    next_week_monday = Holidays.add_day(date, Mon, 2)
    @test next_week_monday - date == Base.Dates.Day(7)

    ## Test 2: Subtracting mondays from monday
    # This should resolve to the same date
    prev_monday = Holidays.sub_day(date, Mon, 1)
    @test date - prev_monday == Base.Dates.Day(0)
    #If count is 2, goes back a week
    prev_week_monday = Holidays.sub_day(date, Mon, 2)
    @test date - prev_week_monday == Base.Dates.Day(7)

    ## Test 3: Adding tuesdays to monday
    next_tuesday = Holidays.add_day(date, Tue, 1)
    @test next_tuesday - date == Base.Dates.Day(1)
    #If count is 2, goes ahead a week and a day
    next_week_tuesday = Holidays.add_day(date, Tue, 2)
    @test next_week_tuesday - date == Base.Dates.Day(8)

    ## Test 2: Subtracting tuesdays from monday
    # This should resolve to the same date
    prev_tuesday = Holidays.sub_day(date, Tue, 1)
    @test date - prev_tuesday == Base.Dates.Day(6)
    # If count is 2, goes back another week
    prev_week_tuesday = Holidays.sub_day(date, Tue, 2)
    @test date - prev_week_tuesday == Base.Dates.Day(13)
end

function test_region_list()
    println("Testing region list")
    country = "CA"
    expected = ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]
    @test country_regions(country) == expected
end

function test_exceptions()
    """Verifies that exceptions are thrown for common bad arguments.
    More can be added and tested later."""

    println("Testing raising exceptions")
    success = true

    # Requestiong absent country must fail
    country = "doesn't exist"
    try
        country_regions(country)
        println("ERROR: No exception thrown")
        success = false
    catch e
    end

    @test success == true

    success = true

    # Requestiong absent country must fail
    country = "doesn't exist"
    try
        dates = holiday_cache(country=country, region="MB", observed=true,
                              expand=true, years=[2016])
        println("ERROR: No exception thrown")
        success = false
    catch e
    end

    @test success == true
end

test_easter()
test_date_functions()
test_no_expand()
test_exceptions()
test_region_list()
verify_all_holidays()
