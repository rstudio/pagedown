--[[
    A Pandoc filter for the Journal of Statistical Software template
    This filter performs two actions:
    1- It stores plain keywords in a pandoc variable named keywords-plain
    2- It build the DOI from the volume and issue parameters and stores it in a variable named doi
--]]

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

local buildDOI = function(volume, issue)
  return "10.18637/jss.v" .. padVolume(volume) .. ".i" .. padIssue(issue)
end

Meta = function(meta)
  ------------------------------------
  --          Keywords              --
  ------------------------------------
  -- Test if there is one keyword:
  if not meta.keywords then error("At least one keyword must be supplied.") end
  -- Store plain keywords:
  local plainKeywords = {}
  for i, v in ipairs(meta.keywords) do
    plainKeywords[i] = pandoc.utils.stringify(v)
  end
  meta["keywords-plain"] = plainKeywords

  ------------------------------------
  --             Author             --
  ------------------------------------
  local author = meta.author
  if author.t == "MetaInlines" then
    meta.author = {data = author, rank = "1"}
  else
    for i, v in ipairs(author) do
      meta.author[i] = {data = v, rank = tostring(i)}
    end
  end

  -------------------------------------
  -- Build DOI from volume and issue --
  -------------------------------------
  -- store a fallback DOI
  meta.doi = "10.18637/jss.vxxx.iyy"

  -- if volume or issue is missing, return the fallback DOI
  if not meta.volume or not meta.issue then return meta end

  local volumeNumber = tonumber(pandoc.utils.stringify(meta.volume))
  local issueNumber = tonumber(pandoc.utils.stringify(meta.issue))

  -- if volume or issue cannot be coerced to a number, return the fallback DOI
  if not volumeNumber or not issueNumber then return meta end

  -- if volume or issue is a number lesser than 1, return the fallback DOI
  if volumeNumber < 1 or issueNumber < 1 then return meta end

  -- if volume or issue is not an integer, return the fallback DOI
  if not isInteger(volumeNumber) or not isInteger(issueNumber) then return meta end

  -- build the DOI
  meta.doi = buildDOI(volumeNumber, issueNumber)
  return meta
end
