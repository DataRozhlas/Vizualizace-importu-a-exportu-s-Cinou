ig = window.ig

init = ->
  ciselnik = {}
  for line in ig.data.ciselnik.split "\n"
    [kod, nazev] = line.split "\t"
    continue if kod == "kod"
    ciselnik[kod] = nazev
  new Tooltip!watchElements!
  container = d3.select ig.containers.base
  impExpGraph = new ig.ImpExpGraph container, ciselnik
    ..drawImport!
  header = new ig.Header container, impExpGraph, ciselnik
  d = new Date!
    ..setTime 1262498549361
  header.displayValues d

if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
