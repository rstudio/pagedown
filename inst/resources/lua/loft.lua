--[[
    A pandoc filter that generates Lists Of Figures and Tables (loft).
    This filter enables the lot and lof options as in LaTeX output formats.

    The user can also customise the titles with lot-title and lof-title:
    ---
    lof:
    lof-title: "Illustrations" # markdown styling is supported
    ---
--]]

-- REQUIREMENTS: Load shared lua function - see `shared.lua` in rmarkdown for more details.
--  * pandocAvailable()
--  * pandoc_type() function (backward compatible type() after 2.17 changes)
--  * print_debug()
dofile(os.getenv 'RMARKDOWN_LUA_SHARED')

--[[
  About the requirement:
  * PANDOC_VERSION -> 2.2.3
]]
if (not pandocAvailable {2,2,3}) then
    io.stderr:write("[WARNING] (jss.lua) requires at least Pandoc 2.1. Lua Filter skipped.\n")
    return {}
end

-- START OF THE FILTER'S FUNCTIONS --

local options = {}     -- where we store pandoc Meta
local tablesList = {}  -- where we store the list of tables
local figuresList = {} -- where we store the list of figures

-- The following function stores pandoc Meta in the options local variable
local function getMeta(meta)
  options = meta
  -- If there is no given titles, use default titles
  if not options["lot-title"] then
    options["lot-title"] = pandoc.MetaInlines(pandoc.Str("List of Tables"))
  end
  if not options["lof-title"] then
    options["lof-title"] = pandoc.MetaInlines(pandoc.Str("List of Figures"))
  end
  return nil -- Do not modify Meta
end

-- Helpers function --

-- From a caption text, retrieve the reference and find it in reference list
local function refFromCaption(captionText, refList)
  local ref
  -- build figure reference from figure caption
  ref = "@ref" .. string.gsub(captionText, "#", "")
  ref = string.gsub(ref, "%)", ") ") -- add a space
  -- insert figure reference in figuresList
  table.insert(refList, {pandoc.Plain(pandoc.Str(ref))})
end

-- This function is called only for Div of class figure inserted by bookdown
local function getFigCaption(div)
  local listOfBlocks = div.content
  local found
  for i, block in ipairs(listOfBlocks) do
    if block.t == "RawBlock" then
      if block.text == '<p class="caption">' then
        found = i + 1
        break
      end
    end
  end
  if found then
    return pandoc.utils.stringify(div.content[found])
  else
    return nil
  end
end

-- Main AST processing functions

-- This function looks for caption in div of class figures. Usually raw HTML of this
-- structure is inserted by knitr::include_graphics() when `fig.cap` is provided
-- which identified as a Div in AST (bc of native_divs).
-- It builds and saves the items used by the list of figures.
local function addFigRef(div)

  local captionText
  local figref

  -- do not build the lof if not required
  if not options.lof then return nil end

  if div.classes:includes("figure") then
    captionText = getFigCaption(div)
    if not captionText then return nil end
    refFromCaption(captionText, figuresList)
  end
  return nil -- Do not modify Div
end

-- This function inspects the Images captions when Images are part of Figures
-- (when Pandoc adds fig: in title meaning implicit_figures have identified it)
-- When a bookdown id is found, it builds and saves the items used by
-- the list of figures.
local function addFigRef2(img)

  local captionText
  local figref

  -- do not build the lof if not required
  if not options.lof then return nil end

  -- Identified a figure
  if img.title and img.title:sub(1,4) == "fig:" then
    captionText = pandoc.utils.stringify(img.caption)
    found = string.find(captionText, "%(#fig:.*%)")
  if found then
    refFromCaption(captionText, figuresList)
  end
  end
end

-- This function inspects the tables captions.
-- When a bookdown id is found, it builds and saves the items used by
--  the list of tables.
local function addTabRef(tab)

  local caption
  local found
  local tabref

  -- do not build the lot if not required
  if not options.lot then return nil end

  caption = pandoc.utils.stringify(tab.caption)
  -- test the presence of a bookdown table id
  found = string.find(caption, "%(#tab:.*%)")
  if found then
    refFromCaption(caption, tablesList)
  end
  return nil -- Do not modify Table
end


-- This function appends the LOT/LOF to the document using custom titles
-- if provided and is insert the new section into TOC unless opt-out
local function appendLoft(doc)

  local lotHeader
  local lofHeader
  local lotClasses = {"lot", "unnumbered", "front-matter"}
  local lofClasses = {"lof", "unnumbered", "front-matter"}
  local idprefix = options.idprefix or ""

  if options.lof then
    table.insert(doc.blocks, 1, pandoc.BulletList(figuresList))
    if options["lof-unlisted"] then table.insert(lofClasses, "unlisted") end
    lofHeader =
      pandoc.Header(1,
                    {table.unpack(options["lof-title"])},
                    pandoc.Attr(idprefix .. "LOF", lofClasses, {})
      )
    table.insert(doc.blocks, 1, lofHeader)
  end

  if options.lot then
    table.insert(doc.blocks, 1, pandoc.BulletList(tablesList))
    if options["lot-unlisted"] then table.insert(lotClasses, "unlisted") end
    lotHeader =
      pandoc.Header(1,
                    {table.unpack(options["lot-title"])},
                    pandoc.Attr(idprefix .. "LOT", lotClasses, {})
      )
    table.insert(doc.blocks, 1, lotHeader)
  end
  return pandoc.Pandoc(doc.blocks, doc.meta)
end

-- Organize filters: Meta filter needs to run before others
return {
  {Meta = getMeta},
  {Div = addFigRef, Image = addFigRef2, Table = addTabRef, Pandoc = appendLoft}
}
