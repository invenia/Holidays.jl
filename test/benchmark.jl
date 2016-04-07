# Determine which is faster -the julia version, or python version.

using PyCall
using Holidays

#Force load of python module in current directory
unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport pyholiday

start_date = Date(1970, 1, 1)
last_date = Date(2020, 1, 1)

regions = Dict(
    # Working Regions
    "CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"],
    "US"=>["AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "GU", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MH", "MA", "MI", "FM", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "VI", "WA", "WV", "WI", "WY"],
    "MX"=>[""],
    "NZ"=>["NTL", "AUK", "TKI", "HKB", "WGN", "MBH", "NSN", "CAN", "STC", "WTL", "OTA", "STL", "CIT"],
    "AU" => ["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"],
    "AT" => ["B", "K", "N", "O", "S", "ST", "T", "V", "W"],
    "DE" => ["BW", "BY", "BE", "BB", "HB", "HH", "HE", "MV", "NI", "NW", "RP", "SL", "SN", "ST", "SH", "TH"],
)

function julia_test()
    println("\n\nTesting julia version")
    for (country, provinces) in regions
        println("   Testing country ",country)
        for province in provinces
            println("       Country: ",country, ", Province: ",province)
            dates = holiday_cache(country=country, region=province)

            date = start_date

            while date < last_date
                y = day_name!(date, dates)
                date = date + Dates.Day(1)
            end
        end
    end
end

function python_test()
    println("Testing python version")
    for (country, provinces) in regions
        println("   Testing country ",country)
        for province in provinces
            println("       Country: ",country, ", Province: ",province)
            pyholiday.load(country, province, true, true, [])

            date = start_date

            while date < last_date
                x = pyholiday.get(date)
                date = date + Dates.Day(1)
            end
        end
    end
end

function compare_versions()
    @time julia_test()
    println("Time for Julia Version, run 1")

    @time python_test()
    println("Time for Python Version")
    @time julia_test()
    println("Time for Julia Version, run 2")
end

compare_versions()

# When running this with all regions, and Date(1800, 1, 1) to Date(2050, 1, 1)
# Julia:
#   6.000520 seconds (37.84 M allocations: 665.069 MB, 0.76% gc time)
# Python:
#   413.954948 seconds (227.87 M allocations: 5.193 GB, 0.56% gc time)

# When running this with all regions, and Date(2000, 1, 1) to Date(2020, 1, 1)
# Julia:
#   1.964405 seconds (4.62 M allocations: 121.134 MB, 0.84% gc time)
# Python:
#   31.457441 seconds (18.31 M allocations: 430.068 MB, 0.56% gc time)

println("Done")


