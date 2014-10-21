window.ig.ImpExpGraph = class ImpExpGraph
  (@parentElement) ->
    width = 1000px
    height = 700px
    @margin = [0 0 30 0]
    @height = height - @margin.0 - @margin.2
    @width = width - @margin.1 - @margin.3
    @svg = @parentElement.append \svg
      ..attr \class \impExpGraph
      ..attr \width width
      ..attr \height height
    @drawing = @svg.append \g
    @setXScale!
    @drawXAxis!

  draw: (data) ->
    layers = {}
    for {kod}:datum in data
      layers[kod] ?= []
      layers[kod].push datum
    cenaExtent = d3.extent data, (.cena)
    timeExtent = d3.extent data, (.date)
    console.log timeExtent

  drawXAxis: ->
    @xAxis = d3.svg.axis!
      ..scale @xScale
      ..tickSize 5, 1

    @xAxisG = @svg.append \g
      ..attr \class "axis x"
      ..attr \transform "translate(0, #{@height})"
      ..call @xAxis

  setXScale: ->
    @startDate = new Date!
      ..setTime 0
      ..setMonth 0
      ..setFullYear 1999
    @endDate = new Date!
      ..setTime 0
      ..setMonth 9
      ..setFullYear 2014
    @xScale = d3.time.scale!
      ..domain [@startDate, @endDate]
      ..range [0, @width]
