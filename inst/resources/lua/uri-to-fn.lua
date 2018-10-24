local options = {} -- where we store pandoc Meta

local function getMeta(meta)
  options = meta
  return nil -- Do not modify Meta
end

local function uriToFootnote(link)
  local target = link.target
  local content = link.content
  local contentString = pandoc.utils.stringify(content)
  local footnoteContent
  local attr = pandoc.Attr("", {}, {})

  if not options["links-to-footnotes"] then return nil end
  if target == contentString then return nil end
  if target == "mailto:" .. contentString then return nil end

  if string.find(target, "://") then
    footnoteContent = {pandoc.Para({pandoc.Link(target, target, "", attr)})}
    table.insert(content, pandoc.Note(footnoteContent))
    return content
  end

  if string.find(target, "^mailto:") then
    footnoteContent = {pandoc.Para({
      pandoc.Link(string.gsub(target, "^mailto:", ""), target, "", attr)
    })}
    table.insert(content, pandoc.Note(footnoteContent))
    return content
  end

end

return {{Meta = getMeta}, {Link = uriToFootnote}}
