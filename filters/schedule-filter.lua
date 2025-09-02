package.path = package.path .. ";" .. "/usr/local/share/lua/5.4/?.lua;/usr/local/share/lua/5.4/?/init.lua;/usr/share/lua/5.4/?.lua;/usr/share/lua/5.4/?/init.lua;/usr/local/lib/lua/5.4/?.lua;/usr/local/lib/lua/5.4/?/init.lua;/usr/lib/lua/5.4/?.lua;/usr/lib/lua/5.4/?/init.lua;./?.lua;./?/init.lua"

require "luarocks.loader"
local date = require("date")


local course_schedule = {}
local DATE_FORMAT = "%a %b %d %Y"
local ORG_FORMAT = "%Y-%b-%d %a"

function index_of(haystack, needle)
    for i, v in ipairs(haystack) do
        if v == needle then
            return i
        end
    end
    return nil
end

function is_holiday(holidays, d)
    for _,holiday in ipairs(holidays) do
        if d == date(pandoc.utils.stringify(holiday.date)) then
            return pandoc.utils.stringify(holiday.name)
        end
    end
    return nil
end

function is_redefined_day(redefined_days, day)
    for _,d in pairs(redefined_days) do
        if date(pandoc.utils.stringify(d.date)) == day then
            return index_of(weekdays, pandoc.utils.stringify(d.is_a))
        end
    end
    return nil
end

local function flatten (list)
  local result = {}
  for i, item in ipairs(list) do
    for j, block in ipairs(item) do
      result[#result + 1] = block
    end
  end
  return result
end

function get_week(meta, week_num)
    local week_str = "Week " .. week_num
    local unit = get_unit(meta, week_num)
    if meta.course.weeks and meta.course.weeks[pandoc.utils.stringify(week_num)] then
        week_str = week_str .. ": " .. pandoc.utils.stringify(meta.course.weeks[pandoc.utils.stringify(week_num)])
    end
    local week_header = pandoc.Header(meta.course.units and 3 or 2, week_str)
    local output = {}
    if unit then
        table.insert(output, unit)
    end
    table.insert(output, week_header)
    return output
end

function get_unit(meta, week_num)
    if not meta.course.units then
        return nil
    end
    for _, unit in pairs(meta.course.units) do
        if tonumber(pandoc.utils.stringify(unit.start)) == week_num then
            return pandoc.Header(2, unit.title)
        end
    end
    return nil
end

weekdays = {
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday'
}

function make_schedule(meta)
    local meeting_days = {}
    local meeting = 1
    local week = 1
    if not meta.course then
        return
    end
    local start_d = date(pandoc.utils.stringify(meta.course.start))
    local end_d = date(pandoc.utils.stringify(meta.course["end"]))
    for _,day in ipairs(meta.course.meets) do
        table.insert(meeting_days, index_of(weekdays, pandoc.utils.stringify(day)))
    end
    local class_d = start_d
    for _, item in pairs(get_week(meta, week)) do
        table.insert(course_schedule, item)
    end
    week = week + 1
    count_days = 1
    repeat
        local redefined_day = meta.course.redefined and is_redefined_day(meta.course.redefined, class_d)
        local day = pandoc.Para(pandoc.Strong(pandoc.Str(class_d:fmt(DATE_FORMAT))))
        if FORMAT:match("org") then
            day = pandoc.Div({
                pandoc.Header(meta.course.units and 4 or 3, pandoc.Str(pandoc.utils.stringify(meta.course.number) .. ", Day " .. tostring(count_days) )),
                pandoc.Para(pandoc.Str("<" .. class_d:fmt(ORG_FORMAT) .. ">"))})
            count_days = count_days + 1
        end
        if class_d:getweekday() == 1 then
            for _, item in pairs(get_week(meta, week)) do
                table.insert(course_schedule, item)
            end
            week = week + 1
        end
        if redefined_day and index_of(meeting_days, redefined_day) then
            table.insert(course_schedule, day)
            if meta.course.classes[meeting] then
                table.insert(course_schedule, meta.course.classes[meeting][1])
            end
            meeting = meeting + 1
        elseif index_of(meeting_days, class_d:getweekday()) then
            local current_holiday = is_holiday(meta.course.holidays, class_d)
            if current_holiday then
                table.insert(course_schedule, day)
                table.insert(course_schedule, pandoc.Para({pandoc.Strong(pandoc.Str("No class: ")), pandoc.Str(current_holiday)}))
            elseif redefined_day then
                table.insert(course_schedule, day)
                table.insert(course_schedule, pandoc.Para({ pandoc.Strong(pandoc.Str("Redefined class: ")), pandoc.Str("Go to your " .. weekdays[redefined_day] .. " classes")}))
            else
                table.insert(course_schedule, day)
                if meta.course.classes[meeting] then
                    table.insert(course_schedule, meta.course.classes[meeting][1])
                end
                meeting = meeting + 1
            end
        end
        class_d:setday(class_d:getday() + 1)
    until class_d > end_d
    return meta
end

function replace (el)
    if pandoc.utils.stringify(el) == "%course_schedule%" or pandoc.utils.stringify(el) == "{% include schedule.html %}" then
        return course_schedule
    end
    return el
end

return {{Meta = make_schedule}, {Para = replace}}
