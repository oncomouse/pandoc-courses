-- source: https://stackoverflow.com/a/76160226
function merge_tables(...)
    local result = {}

    for i, tbl in ipairs({...}) do
      for k, v in pairs(tbl) do
        if type(k) ~= "number" then
          result[k] = v
        else
          table.insert(result, v)
        end
      end
    end

    return result
end

-- Functional-style list mapping; we use this a bunch below
function list_map(fn, xs)
    local ys = {}
    for i,x in ipairs(xs) do
        table.insert(ys, fn(x, i))
    end
    return ys
end

function Pandoc(doc)
    local header = {}
    local blocks = doc.blocks
    local meta = doc.meta
    table.insert(header, pandoc.Header(2, "Course Information"))
    table.insert(header, pandoc.Para({
        pandoc.Strong("Course Number:"), pandoc.Space(), pandoc.Str(pandoc.utils.stringify(meta.course.number)), pandoc.LineBreak(),
        pandoc.Strong("Course Title:"), pandoc.Space(), pandoc.Str(pandoc.utils.stringify(meta.course.title) .. (meta.course.subtitle and pandoc.utils.stringify(meta.course.subtitle) or "")), pandoc.LineBreak(),
        pandoc.Strong("Section:"), pandoc.Space(), pandoc.Str(meta.course.section and pandoc.utils.stringify(meta.course.section) or ""),
        pandoc.Strong("Time:"), pandoc.Space(), pandoc.Str(meta.course.meetings and pandoc.utils.stringify(meta.course.meetings[1].time) or course.time), pandoc.LineBreak(),
        pandoc.Strong("Location:"), pandoc.Space(), pandoc.Str(meta.course.meetings and pandoc.utils.stringify(meta.course.meetings[1].location) or course.location), pandoc.LineBreak(),
        pandoc.Strong("Credit Hours:"), pandoc.Space(), pandoc.Str("4")
    }))
    table.insert(header, pandoc.Header(2, "Instructor Details"))
    table.insert(header, pandoc.Para({
        -- Work through the list of instructors:
        table.unpack(list_map(function(instructor)
                                  return pandoc.Span({
                                      pandoc.Strong("Instructor:"), pandoc.Space(), pandoc.Str(pandoc.utils.stringify(instructor.name)), pandoc.LineBreak(),
                                      -- Get all the office locations and office hours the instructor is using:
                                      table.unpack(list_map(function(office)
                                                                return pandoc.Span{
                                                                    pandoc.Strong("Office:"), pandoc.Space(), pandoc.Str(pandoc.utils.stringify(office.location)), pandoc.LineBreak(),
                                                                    pandoc.Strong("Office Hours:"), pandoc.Space(), pandoc.Str(pandoc.utils.stringify(office.hours)), pandoc.LineBreak()}
                                                            end, instructor.office or {}))
                                  })
                              end, meta.course.instructors or {}))
    }))
    table.insert(header, pandoc.Header(2, "Course Description"))
    table.insert(header, pandoc.BlockQuote(meta.course.description))
    table.insert(header, pandoc.Header(2, "Course Learning Outcomes"))
    table.insert(header, pandoc.Para("In this course, students can expect"))
    table.insert(header, pandoc.BulletList(meta.course.outcomes and list_map(function(x) return pandoc.utils.stringify(x) end, meta.course.outcomes) or {}))
    return pandoc.Pandoc(merge_tables(header, blocks), meta)
end
