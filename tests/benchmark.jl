# Determine which is faster -the julia version, or python version.

using PyCall
using Holidays
using ProfileView

#Force load of python module in current directory
unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport pyholiday

start_date = Date(2000, 1, 1)
last_date = Date(2001, 1, 1)

function julia_test()
    # Add regions to test here
    regions = Dict(
        "CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]
    )

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
    # Add regions to test here
    regions = Dict(
        "CA"=>["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YU"]
    )

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
    println("Initial")
    # Constants
    julia_test()

    println("Second")
    Profile.init(delay=0.0001)
    Profile.clear()
    @profile @time julia_test()

    println("Viewing")
    ProfileView.view()
    #~ python_test()
end

compare_versions()
#~ compare_dicts()


