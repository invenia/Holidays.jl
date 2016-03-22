VERSION >= v"0.4-" && __precompile__()

module Holidays
import Base: start, next, done, isempty, length, show
import Codecs
using Compat

if VERSION < v"0.4-dev"
    using Dates
end

dates = Dict()

function load()
    print("Done\n")
end
end

