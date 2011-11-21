jQuery ($) ->

    class CoffeeRoadRace  # {{{
        constructor: (@containerId) ->  # {{{
            @width = $("##{@containerId}").width()
            @height = $("##{@containerId}").height()

            #@model = new RoadModel(@width, @height)
            @modelWorker = new Worker "RoadModel.js"
            @modelWorker.postMessage
                action: 'init',
                width: @width,
                height: @height
            @renderQeue = []
            self = this
            @modelWorker.addEventListener "message", (e) ->
                if e.data.action == 'renderList'
                    self.renderQeue.push e.data.renderList

            @createHtml()

            @speed = 5
            @texOffset = 100
            @segmentY = 0
            @xOffset = 0.0

            @nextStretch = "straight"
            @pause = false

            # Road Colors & Theme
            @colortheme =
                true: ["#f2e2d8", "#f0f0f0", "#a4a2a5"],
                false: ["#dcccc2", "#f0f0f0", "#acaaad"]
            @roadWidth = @width >> 1
            @roadHalfWidth = @roadWidth >> 1
            @sideWidth = 20

            @backgroundImage = null
            self = this
            img = new Image()
            img.src = "cloudy_1280x400.png"
            $(img).load -> self.backgroundImage = img
            # }}}

        createHtml: ->  # {{{
            @groundCanvasId = "groundCanavas"
            @roadCanvasId = "roadCanavas"

            $container = $ "##{@containerId}"
            $container.css "position", "relative"
            $container.html """
                <canvas id='#{@groundCanvasId}' width='#{@width}' height='#{@height}'></canvas>
                <canvas id='#{@roadCanvasId}' width='#{@width}' height='#{@height}'></canvas>
            """

            @groundCanvas = $container.children("##{@groundCanvasId}").get 0
            @roadCanvas = $container.children("##{@roadCanvasId}").get 0

            $(@groundCanvas).css
                position: "absolute",
                top: 0,
                left: 0

            $(@roadCanvas).css
                position: "absolute",
                top: 0,
                left: 0,
                'z-index': 100

            @groundCtx = @groundCanvas.getContext "2d"
            @roadCtx = @roadCanvas.getContext "2d"
            return
            # }}}

        drawRoad: ->  # {{{
            @modelWorker.postMessage
                action: 'updateRoad',
                xOffset: @xOffset,
                texOffset: @texOffset

            #renderList = @model.updateRoad(@xOffset, @texOffset)
            renderList = @renderQeue.shift()

            if renderList
                for args in renderList
                    cmd = args.shift()
                    switch cmd
                        when 0
                            @clearCanvas args...
                        when 1
                            @drawGround args...
                        when 2
                            @drawRoadLine args...
                        when 3
                            @drawRoadLine2 args...
            delete renderList
            return
            # }}}

        getShaderProg: (texture) ->  # {{{
            # [ /*coords:*/ [], /*width:*/ [], /*paint:*/ [[<styleIndex>, [<coordsIndex>, <widthIndex>], ..], .. ]

            unless @shaders
                roadThird = @roadWidth/3

                @shaders = {}
                @shaders[true] = [
                    [
                        -@roadHalfWidth-@sideWidth,
                        -(roadThird>>1),
                        -@roadHalfWidth+(@sideWidth>>1),
                        @roadHalfWidth-@sideWidth,
                        roadThird>>1,
                    ],
                    [
                        @roadWidth+(@sideWidth<<1),
                        @sideWidth>>1,
                    ],
                    [
                        [2, [0, 0]],
                        [1, [1, 1], [2, 1], [3, 1], [4, 1]]
                    ]
                ]
                @shaders[false] = [
                    [
                        -@roadHalfWidth-@sideWidth,
                        @roadHalfWidth,
                        -@roadHalfWidth,
                        -@sideWidth>>1
                    ],
                    [
                        @sideWidth,
                        @roadWidth
                    ],
                    [
                        [1, [0, 0], [1, 0]],
                        [2, [2, 1]]
                    ]
                ]

            return @shaders[!!texture]
            # }}}

        drawRoadLine: (texture, x, y, scaleX, h = 1) ->  # {{{
            shader = @getShaderProg texture

            coords = (x + c * scaleX for c in shader[0])
            widths = (w * scaleX for w in shader[1])

            for paint in shader[2]
                @roadCtx.fillStyle = @colortheme[texture][paint[0]]
                for i in [1...paint.length]
                    @roadCtx.fillRect coords[paint[i][0]], y, widths[paint[i][1]], h

            return
            # }}}

        drawRoadLine2: (texture, x, x2, y, y2, scaleX, scaleX2, h) ->  # {{{
            shader = @getShaderProg texture

            coords = []
            coords2 = []
            for c in shader[0]
                coords.push x + c * scaleX
                coords2.push x2 + c * scaleX2

            widths = []
            widths2 = []
            for w in shader[1]
                widths.push w * scaleX
                widths2.push w * scaleX2

            for paint in shader[2]
                @roadCtx.fillStyle = @colortheme[texture][paint[0]]
                for i in [1...paint.length]
                    @roadCtx.beginPath()
                    @roadCtx.moveTo coords[paint[i][0]], y
                    @roadCtx.lineTo coords[paint[i][0]] + widths[paint[i][1]], y
                    @roadCtx.lineTo coords2[paint[i][0]] + widths2[paint[i][1]], y2
                    @roadCtx.lineTo coords2[paint[i][0]], y2
                    @roadCtx.closePath()
                    @roadCtx.fill()

            return
            # }}}

        drawGround: (texture, y, h) ->  # {{{
            @roadCtx.fillStyle = @colortheme[texture][0]
            @roadCtx.fillRect 0, y, @width, h
            return
            # }}}

        clearCanvas: (x, y) ->  # {{{
            if @backgroundImage and x and y
                @groundCtx.drawImage @backgroundImage,
                    @width - x,
                    @height - y,
                    @width,
                    y,
                    0,
                    0,
                    @width,
                    y
            else
                @groundCtx.fillStyle = "#60a0c0"
                @groundCtx.fillRect 0, 0, @width, @height

            @roadCtx.clearRect 0, 0, @width, @height
            return
            # }}}

        race: ->  # {{{
            return if @pause

            @texOffset += @speed
            if @texOffset >= 100
                @texOffset -= 100
            if @texOffset < 0
                @texOffset += 100

            @segmentY -= 1
            if @segmentY < 0
                @segmentY += @roadLines
                if @nextStretch == 'straight'
                    @nextStretch = "curved"
                else
                    @nextStretch = 'straight'

            @drawRoad()
            return
            # }}}

    # end of class CoffeeRoadRace }}}

    # http://active.tutsplus.com/tutorials/games/create-a-racing-game-without-a-3d-engine/
    #
    console.log("CoffeeRoadRace by spearwolf <wolfger@spearwolf.de>")

    racer = window.racer = new CoffeeRoadRace "roadRace"

    #stats = new Stats()
    #$("body").append $(stats.domElement).addClass("statsJsWidget")

    $(window).keydown (event) ->
        #console.log event.keyCode
        if event.keyCode == 80  # 'p' -> pause
            racer.pause = !racer.pause
        if event.keyCode == 87  # 'w' -> more speed
            racer.speed += 0.1
        if event.keyCode == 83  # 's' -> less speed
            racer.speed -= 0.1
        if event.keyCode == 65  # 'a' -> left
            racer.xOffset -= 5
        if event.keyCode == 68  # 'd' -> right
            racer.xOffset += 5

    reqAnimFrame = window.mozRequestAnimationFrame or window.webkitRequestAnimationFrame
    anim = ->
        racer.race()
        #stats.update()
        reqAnimFrame anim

    anim()

