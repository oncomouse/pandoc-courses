function Meta(meta)
    if pandoc.utils.stringify(meta.title) == "Syllabus" then
        meta.title = pandoc.utils.stringify(meta.course.number) .. ": " .. pandoc.utils.stringify(meta.course.title) .. ", " .. pandoc.utils.stringify(meta.course.term)
        return meta
    end
end
