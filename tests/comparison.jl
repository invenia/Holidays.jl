using PyCall
using Holidays

#Force load of python module in current directory
unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport pyholiday

# Add regions to test here
regions = Dict(
    "CA"=>["MB", "NL", "QC", "NU"]
)

# Set first and last date in loop
start_date = Date(2016, 1, 1)
last_date = Date(2017, 1, 1)

function day_names_equal(x, y)
    if isa(x, AbstractString) && isa(y, AbstractString)
        return x == y
    elseif !isa(x, AbstractString) && !isa(y, AbstractString)
        return true
    else
        return false
    end
end

function compareHolidays(country, province)
    dates = Holidays.Canada(region=province, years=2016)
    pyholiday.load(country, province)

    date = start_date

    @time while date < last_date
        x = pyholiday.get(date)
        y = Holidays.dayName(date, dates)

        # Record holidays that failed:
        if !day_names_equal(x, y)
            println("Failure on ",date, " - Python: ",x,", Julia: ",y)

        # Record holidays that matched:
        elseif isa(x, AbstractString) && isa(y, AbstractString)
            println("Success on ",date, " - Python: ",x,", Julia: ",y)
        end

        date = date + Dates.Day(1)
    end
end

function loop_regions()
    for (country, provinces) in regions
        println("Testing country ",country)
        for province in provinces
            println("Country: ",country, ", Province: ",province)
            compareHolidays(country, province)
        end
    end
end


function test_easter()
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

    # Split into lines
    easter_strs = split(strip(easter_table), "\n")

    for line in easter_strs
        (year, west_month, west_day, east_month, east_day) = split(strip(line), r"\s+")
        west_string = "$year-$west_month-$west_day"
        west_date = Date(west_string)

        calculated_easter = Holidays.easter(Dates.year(west_date))

        if west_date != calculated_easter
            println("Errror calculating western easter date")
            println("  Wikipedia's value: ",Dates.format(west_date, "yyyy u dd"))
            println("  Estimated value  : ",Dates.format(calculated_easter, "yyyy u dd"))
        end
    end
end

loop_regions()
# test_easter()
