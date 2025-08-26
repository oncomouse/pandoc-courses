function Para(el)
    local _, _, fn = string.find(pandoc.utils.stringify(el), "{%%%s*include (%S+)%s*%%}")
    if not fn or fn == "schedule.html" then
        return el
    end
    local fp = io.open("./includes/" .. fn)
    if not fp then
        io.close(fp)
        return el
    end
    local new_el = pandoc.CodeBlock("includes/" .. fn)
    new_el.classes = {"include"}
    return new_el
end
