using PyCall
using Holidays

#Force load of python module in current directory
unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport pyholiday

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

    date = Date(2016, 1, 1)
    last_date = Date(2017, 1, 1)

    while date < last_date
        x = pyholiday.get(date)
        y = Holidays.dayName(date, dates)

        # Record holidays that failed:
        if !day_names_equal(x, y)
            println("Failure : ",date)
            println("   Python Date:",x)
            println("   Typeof Python Date == ",typeof(x))
            println("   Julia Date:", y)
            println("   Typeof Julia Date == ", typeof(y))

        # Record holidays that matched:
        elseif isa(x, AbstractString) && isa(y, AbstractString)
            println("Success : ",date)
            println("   Python Date:",x)
            println("   Julia Date:", y)
        end

        date = date + Dates.Day(1)
    end
end

regions = Dict(
    "CA"=>["MB"]
)

for (country, provinces) in regions
    println("Testing country ",country)
    for province in provinces
        println("Country: ",country, ", Province: ",province)
        compareHolidays(country, province)
    end
end
