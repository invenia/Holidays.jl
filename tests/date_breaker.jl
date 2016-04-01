using PyCall
using StackTraces

(Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday) = (Dates.Monday, Dates.Tuesday, Dates.Wednesday, Dates.Thursday, Dates.Friday, Dates.Saturday, Dates.Sunday)

function datebreaker()
    date = Date(2018, 1, 1)
    date_name = ""

#~     try
        # Loop until failure.
        while true
            # Loop through dates and weekdays
            for weekday in (Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday)
                # Occasional print statements just so you can monitor how long this has been going mostly.
                println("Testing weekday",weekday)

                date = Date(2018, 1, 1)
                last_date = Date(2022, 1, 1)

                while date < last_date
                    # This call is where the error will be raised from first...
                    temp = Dates.tonext(x->Dates.dayofweek(x) == weekday, date)

                    date = date + Dates.Day(1)
                end
            end
        end
#~     catch e
#~         # Help diagnose the error by printing as much stuff as possible.
#~         whos()
#~         println(stacktrace())
#~         println("Error",e)
#~         println("Last date tried:",date)
#~         println("Date Name is currently",date_name)
#~         return false
#~     end

#~     return true
end

# Loop this until the error happens...
@time datebreaker()
