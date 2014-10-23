window.ig.Header = class Header
  (@baseElement, @impExpGraph, @ciselnik) ->
    @element = @baseElement.append \div
      ..attr \class \header
    @impExpGraph
      ..on \drawing @~update
      ..on \focusing @~focus
      ..on \highlight @~highlight
    @backbutton = window.ig.utils.backbutton @element
      ..on \click @impExpGraph~back
    @update!

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
      @heading.html @ciselnik[@impExpGraph.currentKod]
    else
      @backbutton.classed \disabled yes
      verb = if @impExpGraph.direction == "import" then "dovážíme z" else "vyvážíme do"
      @heading.html "Co všechno #verb Číny"

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
      ..append \span .html ~> @ciselnik[it.kod]
      ..append \div .style \background-color ~> @impExpGraph.color it.kod
      ..on \mouseover ~> @impExpGraph.highlight it.kod
      ..on \click ~> @impExpGraph.drawSubset it.kod

  focus: (kod) ->
    @legendItems
      .filter -> it.kod != kod.toString!
      .classed \old yes

  highlight: (kod) ->
    kod .= toString! if kod
    @legendItems
      .classed \active no
      .filter (.kod == kod)
      .classed \active yes



