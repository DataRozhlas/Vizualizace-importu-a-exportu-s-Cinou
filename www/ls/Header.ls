window.ig.Header = class Header
  (@baseElement, @impExpGraph, @ciselnik) ->
    @element = @baseElement.append \div
      ..attr \class \header
    @valueHeader = @element.append \div
      ..attr \class \valueHeader
    @impExpGraph
      ..on \drawing @~update
      ..on \focusing @~focus
      ..on \highlight @~highlight
      ..on \pointer @~displayValues
    @backbutton = window.ig.utils.backbutton @element
      ..on \click @impExpGraph~back
    @update!
    @months = <[Leden Únor Březen Duben Květen Červen Červenec Srpen Září Říjen Listopad Prosinec]>

  update: ->
    if @heading
      oldHeading = @heading
      oldHeading.classed \old yes
          ..transition!
            ..delay 800
            ..remove!
    @heading = @element.append \h1
      ..attr \class \header
    @drawLegend!
    if @impExpGraph.currentKod
      @backbutton.classed \disabled no
      @heading
        ..html @ciselnik[@impExpGraph.currentKod]
        ..attr \title @ciselnik[@impExpGraph.currentKod]

    else
      @backbutton.classed \disabled yes
      verb = if @impExpGraph.direction == "import" then "dovážíme z" else "vyvážíme do"
      @heading
        ..html "Co všechno #verb Číny"
        ..attr \title "Co všechno #verb Číny"


  drawLegend: ->
    if @legend
      @legend
        ..classed \old yes
        ..transition!
          ..delay 800
          ..remove!
    items = @impExpGraph.currentLayers.slice!reverse!
    @legend = @element.append \ul
      ..on \mouseout ~> @impExpGraph.highlightOff!
    len = items.length
    @legendItems = @legend.selectAll \li .data items .enter!append \li
      ..attr \class \new
      ..transition!
        ..delay 100
        ..attr \class ''
      ..append \span
        ..attr \class \title
        ..html ~> @ciselnik[it.kod]
      ..append \span
        ..attr \class \value
      ..append \div
        ..attr \class \kost
        ..style \background-color ~> @impExpGraph.color it.kod
      ..on \mouseover ~> @impExpGraph.highlight it.kod
      ..on \click ~> @impExpGraph.drawSubset it.kod
    @sumItem = @legend.append \li
      .attr \class \sum
      .append \span
      .html ''

  focus: (kod) ->
    @legendItems
      .filter -> it.kod != kod.toString!
      .classed \old yes

  highlight: (kod) ->
    kod .= toString! if kod
    if kod is null
      @hideValues!
    @legendItems
      .classed \active no
      .filter (.kod == kod)
      .classed \active yes

  displayValues: (date) ->
    @valueHeader.html "#{@months[date.getMonth!]} #{date.getFullYear!}"
    time = date.getTime!
    lastValidIndex = null
    for datapoint, index in @impExpGraph.currentLayers.0.layerPoints
      if datapoint.time < time
        lastValidIndex := index
      else
        break
    @element.classed \valuesDisplayed yes
    sum = 0
    @legendItems.selectAll \.value
      ..html ->
        if it.layerPoints[lastValidIndex]
          if it.layerPoints[lastValidIndex].cena
            sum += that
            "#{ig.utils.formatNumber it.layerPoints[lastValidIndex].cena} 000 Kč"
          else
            "0 Kč"
        else
          ""
    @sumItem.html "#{ig.utils.formatNumber sum} 000 Kč"
  hideValues: ->
    @element.classed \valuesDisplayed no
    @valueHeader.html ""



