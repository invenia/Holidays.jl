# Determine which is faster -the julia version, or python version.

using PyCall
using Holidays

#Force load of python module in current directory
unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport pyholiday

start_date = Date(2000, 1, 1)
#~ last_date = Date(2001, 1, 1)
last_date = Date(2005, 1, 1)

regions = Dict(
    "CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]
)

function julia_test()
    println("\n\nTesting julia version")
    for (country, provinces) in regions
        println("Testing country ",country)
        for province in provinces
            println("Country: ",country, ", Province: ",province)
            dates = Holidays.Canada(region=province)

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


