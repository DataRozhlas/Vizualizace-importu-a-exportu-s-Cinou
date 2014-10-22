ig = window.ig

init = ->
  new Tooltip!watchElements!

  impExpGraph = new ig.ImpExpGraph d3.select ig.containers.base
    ..drawImport!
  <~ setTimeout _, 100
  impExpGraph.drawSubset 7
  <~ setTimeout _, 5000
  impExpGraph.back!
if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
