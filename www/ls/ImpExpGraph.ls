window.ig.ImpExpGraph = class ImpExpGraph
  (@parentElement) ->
    width = 1000px
    height = 700px
    @margin = [10 0 30 60]
    @height = height - @margin.0 - @margin.2
    @width = width - @margin.1 - @margin.3
    @svg = @parentElement.append \svg
      ..attr \class \impExpGraph
      ..attr \width width
      ..attr \height height
    @drawing = @svg.append \g
      ..attr \transform "translate(#{@margin.3}, #{@margin.0})"
    @setXScale!
    @drawXAxis!
    @prepareYScale!
    @prepareYAxis!
    @stack = d3.layout.stack!
      ..values (.layerPoints)
      ..x (.date)
      ..y (.cena)
    @color = d3.scale.ordinal!
      ..range <[#e41a1c #377eb8 #4daf4a #984ea3 #ff7f00 #ffff33 #a65628 #f781bf #999999]>

  draw: (data) ->

    @yAxisG.call @yAxis
    data.sort (a, b) -> a.time - b.time
    dateRange = generateDateRange data.0, data[*-1]
    layers_assoc = {}
    for {kod}:datum in data
      layers_assoc[kod] ?= []
      layers_assoc[kod].push datum
    layers = for kod, layerPoints of layers_assoc
      layerPoints = extrapolate layerPoints, dateRange
      {kod, layerPoints}

    stacked = @stack layers
    max = d3.max layers[*-1].layerPoints.map -> it.y0 + it.y
    @yScale.domain [0, max]
    area = d3.svg.area!
      ..x ~> @xScale it.date
      ..y0 ~> @yScale it.y0
      ..y1 ~> @yScale it.y0 + it.y
    @drawing.selectAll \path.new .data layers .enter!append \path
      ..attr \d -> area it.layerPoints
      ..attr \fill ~>
        @color it.kod
      ..attr \data-tooltip -> it.kod


  drawXAxis: ->
    @xAxis = d3.svg.axis!
      ..scale @xScale
      ..tickSize 5, 1

    @xAxisG = @svg.append \g
      ..attr \class "axis x"
      ..attr \transform "translate(#{@margin.3}, #{@margin.0 + @height})"
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

  prepareYScale: ->
    @yScale = d3.scale.linear!
      ..range [@height, 0]

  prepareYAxis: ->
    @yAxis = d3.svg.axis!
      ..scale @yScale
      ..orient "left"
      ..tickSize 5, 1
      ..tickFormat ->
        | it == 0 => "0 Kč"
        | it < 1e3 => it + " mil."
        | it < 1e6 => it / 1e3 + " mld."
        | otherwise => it / 1e6 + " bil."

    @yAxisG = @svg.append \g
      ..attr \class "axis y"
      ..attr \transform "translate(#{@margin.3}, #{@margin.0})"

class RangeItem
  (date) ->
    @date = new Date!
      ..setTime date.getTime!
    obdobiMesic = (@date.getMonth! + 1).toString!
    if obdobiMesic.length == 1
      obdobiMesic = "0" + obdobiMesic
    @obdobi = "#{obdobiMesic}/#{@date.getFullYear!}"
    @cena = 0
    @extrapolated = yes


generateDateRange = (min, max) ->
  currentDate = new Date!
    ..setTime 0
    ..setMonth min.date.getMonth!
    ..setFullYear min.date.getFullYear!
  currentMonth =  currentDate.getMonth!
  currentYear = currentDate.getFullYear!
  i = 0
  out = []
  while currentDate.getTime! <= max.time
    out.push new RangeItem currentDate
    currentMonth += 1
    if currentMonth > 11
      currentMonth = 0
      currentYear += 1
      currentDate.setFullYear currentYear
    currentDate.setMonth currentMonth
  out.push new RangeItem currentDate
  out


extrapolate = (input, range) ->
  currentIndex = 0
  lastCena = null
  rangeLength = range.length
  out = range.map (rangeItem, index) ->
    if input[currentIndex]?obdobi == rangeItem.obdobi
      lastCena := input[currentIndex].cena
      ++currentIndex
      input[currentIndex - 1]
    else if lastCena and (rangeLength - index) < 5
      date         : rangeItem.date
      obdobi       : rangeItem.obdobi
      cena         : lastCena
      extrapolated : yes
    else
      rangeItem
  out

