import std/[httpclient, sequtils, unicode, strbasics, json, files, uri], parsetoml, system, strutils, cligen


var webClient = newHttpClient()

var 
  parserret: seq[string]


var 
  sites: seq[string]
  list2: seq[string] #todo: More then 2 lists
  


proc onionJsFixer(line:string): string =

  var stripedLine: string

  stripedLine = line.strip()
  stripedLine.strip(chars = {',', '\'', ';'})

  return stripedLine


proc DoodleStripper(line:string): string =

  var stripedLine: string

  stripedLine = line.strip()

  stripedLine.strip(chars = {'['})

  return stripedLine.split(",")[0].strip(chars = {'"'})

proc urlValidator(url:string): string = 
  var x = parseUri(url)

  if (x.scheme == "http" or x.scheme == "https") and x.isAbsolute:
    result = x.scheme & "://" & x.hostname

# Parsers

# todo: maak een generic json parser 
proc baccyJSON(ring: TomlValueRef): seq[string] = # dit is gewoon de generic json parser geworden, heb liever een apparte
  let url = ring["url"].getStr

  echo "[baccyJSON] Downloading Ring " & ring["name"].getStr & " from " & ring["url"].getStr

  # tbh heb ik geen zin om het async maken, maar met hoe groot dit gaat zijn is het wel handiger om het zo te doen.

  let ringJson = parsejson(webClient.getContent(url))

  var 
    sites:  seq[string]
  

  for site in ringJson.getElems:
    if site{"state"}.getInt == 2 or ring{"allowAll"}.getBool:
      sites.addUnique(site["url"].getStr)

  return sites



proc onion(ring: TomlValueRef): seq[string] =

  let url = ring["url"].getStr

  echo "[onion] Downloading Ring " & ring["name"].getStr & " from " & ring["url"].getStr


  let js = webClient.getContent(url)


  var magic = false
  var 
    sites: seq[string]

  for line in js.split("\n"):

    if magic:
      if "];" in line:
        return sites
      elif not line.strip.startsWith("//"):
        sites.addUnique(onionJsFixer(line))

    if not magic:
      if "var sites = [" in line:
        magic = true
      elif "let sites = [" in line:
        magic = true



proc doodlering(ring: TomlValueRef): seq[string] =

  let url = ring["url"].getStr

  echo "[doodlering] Downloading Ring " & ring["name"].getStr & " from " & ring["url"].getStr


  let js = webClient.getContent(url)


  var magic = false
  var 
    sites: seq[string]

  for line in js.split("\n"):

    if magic:
      if "];" in line:
        return sites
      elif not line.strip.startsWith("//"):
        sites.addUnique(DoodleStripper(line))

    if not magic:
      if "var sites = [" in line:
        magic = true
      elif "let sites = [" in line:
        magic = true




proc webringParser(configFile: string, output = "./sites.json") =

  let confFile = readFile(configFile)
  let config = parseString(confFile)

  for webring in config["rings"].getElems:

    var parser = webring["parser"].getStr


    if parser == "onion": # Define your parsers here!
      parserret = onion(webring)
    elif parser == "doodlering":
      parserret = doodlering(webring)
    elif parser == "baccyjson":
      parserret = baccyJSON(webring)
    else:
      echo "[system] [ERROR] Couldn't find parser '" & parser & "' requested by ring '" & webring["name"].getStr & "'"


    if not webring{"list2"}.getBool:
      for value in parserret:
        sites.addUnique(urlValidator(value))
    else:
      for value in parserret:
        list2.addUnique(urlValidator(value))




  writeFile(output, pretty(%* {
    "sites": sites,
    "list2": list2
  }.toTable))

  echo "Sites uitgeput naar" & output













dispatch webringParser

  





