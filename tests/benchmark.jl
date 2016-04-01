# Determine which is faster -the julia version, or python version.

using PyCall
using Holidays

#Force load of python module in current directory
unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport pyholiday

start_date = Date(1900, 1, 1)
last_date = Date(2005, 1, 1)

regions = Dict(
    #"CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]
    "US"=>["AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "GU", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MH", "MA", "MI", "FM", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "VI", "WA", "WV", "WI", "WY"]
)

function julia_test()
    println("\n\nTesting julia version")
    for (country, provinces) in regions
        println("Testing country ",country)
        for province in provinces
            println("Country: ",country, ", Province: ",province)
            dates = Holidays.Cache(country=country, region=province)

            date = start_date

            while date < last_date
                y = Holidays.dayName(date, dates)
                date = date + Dates.Day(1)
            end
        end
    end
end

function python_test()
    println("Testing python version")
    for (country, provinces) in regions
        println("Testing country ",country)
        for province in provinces
            println("Country: ",country, ", Province: ",province)
            pyholiday.load(country, province)

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
    @time python_test()
end

compare_versions()

println("Done")


