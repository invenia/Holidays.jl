using StackTraces

function datebreaker()
    # date = Date(2018, 1, 1)
    date = Date(2018, 1, 1)
    last_weekday = Dates.Monday

    x = UInt64(0)

    try
        # Loop until failure.
        while true
            weekday = rand(0:6)

            last_weekday = weekday

            date = Date(1990, 12, 1)
            last_date = Date(2999, 1, 9)

            while date < last_date
                temp = Dates.tonext(x->Dates.dayofweek(x) == weekday, date)

                x = x + 1

                date = date + Dates.Day(1)
            end
        end
    catch e
        # Help diagnose the error by printing as much stuff as possible.
        whos()
        println(stacktrace())
        println("Error",e)
        println("Last date tried:",date)
        println("Last weekday tried:",last_weekday)
        println("Successful Runs:",x)
        return false
    end

    return true
end

# Loop this until the error happens...
@time datebreaker()
