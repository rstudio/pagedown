--[[
    A Pandoc filter for the Journal of Statistical Software template
    This filter performs the following actions:
    - store plain keywords in a pandoc variable named keywords-plain
    - calculate the rank for each author
    - build the DOI from the volume and issue parameters and store it in a variable named doi
    - use fallback values for missing month, year, volume or issue

    Developped using Pandoc 2.2.3 by @RLesur
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

local isInteger = function(number)
  return math.floor(number) == number
end

local padVolume = function(volume)
  local volumeString = tostring(volume)
  if volume < 10 then return "00" .. volumeString end
  if volume < 100 then return "0" .. volumeString end
  return volumeString
end

local padIssue = function(issue)
  local issueString = tostring(issue)
  if issue < 10 then return "0" .. issueString end
  return issueString
end

local getDOI = function(volume, issue)
  -- store a fallback DOI
  local fallback = "10.18637/jss.v000.i00"

  -- if volume or issue is missing, return the fallback DOI
  if not volume or not issue then return fallback end

  local volumeNumber = tonumber(pandoc.utils.stringify(volume))
  local issueNumber = tonumber(pandoc.utils.stringify(issue))

  -- if volume or issue cannot be coerced to a number, return the fallback DOI
  if not volumeNumber or not issueNumber then return fallback end

  -- if volume or issue is a number lesser than 1, return the fallback DOI
  if volumeNumber < 1 or issueNumber < 1 then return fallback end

  -- if volume or issue is not an integer, return the fallback DOI
  if not isInteger(volumeNumber) or not isInteger(issueNumber) then return fallback end

  -- build the DOI
  return "10.18637/jss.v" .. padVolume(volumeNumber) .. ".i" .. padIssue(issueNumber)
end

Meta = function(meta)
  ---------------------------------------
  --           Keywords                --
  ---------------------------------------
  -- Test if there is one keyword:
  if not meta.keywords then error("At least one keyword must be supplied.") end
  -- Store plain keywords:
  local plainKeywords = {}

  if pandoc_type(meta.keywords) == "List" then
    for i, v in ipairs(meta.keywords) do
      plainKeywords[i] = pandoc.utils.stringify(v)
    end
  else
    -- we have only one keyword
    plainKeywords = {pandoc.utils.stringify(meta.keywords)}
  end

  meta["keywords-plain"] = plainKeywords

  ---------------------------------------
  --              Author               --
  ---------------------------------------
  local author = meta.author

  if pandoc_type(author) == "Inlines" then
    meta.author = {data = author, rank = "1"}
  else
    for i, v in ipairs(author) do
      meta.author[i] = {data = v, rank = tostring(i)}
    end
  end

  ----------------------------------------
  --  Build DOI from volume and issue   --
  ----------------------------------------
  meta.doi = getDOI(meta.volume, meta.issue)

  ----------------------------------------
  -- Fallback values for missing params --
  ----------------------------------------
  if not meta.month then meta.month = "MMMMMM" end
  if not meta.year then meta.year = "YYYY" end
  if not meta.volume then meta.volume = "VV" end
  if not meta.issue then meta.issue = "II" end
  if not meta.submitdate then meta.submitdate = "yyyy-mm-dd" end
  if not meta.acceptdate then meta.acceptdate = "yyyy-mm-dd" end

  return meta
end
