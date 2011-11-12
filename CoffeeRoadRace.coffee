jQuery ($) ->

    class CoffeeRoadRace

        constructor: (@containerId) ->
            @width = $("##{@containerId}").width()
            @height = $("##{@containerId}").height()
            @halfWidth = @width/2

            @createHtml()

            # Depth of the visible road
            @roadLines = (0.5 + @height / 2)|0
            @widthStep = (@height * 0.5) / @roadLines
            @zFactor = 95
            @zFactor2 = 1.2
            # Line of the player's car
            @noScaleLine = 8

            # Animation
            @speed = 5
            @texOffset = 100
            @nextStretch = "straight"
            @pause = false

            # Road Colors
            @colortheme =
                true: ["#f2e2d8", "#989697", "#a4a2a5", "#f0f0f0"],
                false: ["#dcccc2", "#f0f0f0", "#acaaad"]
            #@colortheme =
                #true: ["#00a030", "#f0f0f0", "#888888", "#f0f0f0"],
                #false: ["#008040", "#f01060", "#666666"]
            @sideWidth = 20

            # Sharpness of the curves
            @ddx = 0.015
            @ddx *= @widthStep
            @segmentY = @roadLines
            # Hills, Slopes
            @ddy = 0.01
            @ddy *= @widthStep

            @populateZMap()

            @backgroundImage = null
            self = this
            img = new Image()
            img.src = "cloudy_1280x400.png"
            $(img).load -> self.backgroundImage = img

        createHtml: ->
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

        # Populate the zMap with the depth of the road lines
        populateZMap: ->
            @zMap = []
            for i in [0...@roadLines]
                @zMap.push 1.0 / ((i * @widthStep) - (@height / 1.85))

            playerZ = 100.0 / @zMap[@noScaleLine]
            for i in [0...@roadLines]
                @zMap[i] *= playerZ
            return

        drawRoad: ->
            rx = @halfWidth
            ry = @height - 1
            rrx = []
            rry = []
            dx = dy = 0
            for i in [0...@roadLines]
                rrx.push rx
                rry.push ry

                switch @nextStretch
                    when "straight"
                        if i >= @segmentY
                            dx += @ddx
                            #dy -= @ddy
                        else
                            dx -= @ddx / 64
                            #dy += @ddy

                    when "curved"
                        if i <= @segmentY
                            dx += @ddx
                            #dy -= @ddy
                        else
                            dx -= @ddx / 64
                            #dy += @ddy
                rx += dx
                ry += dy - 1

            half_width = @halfWidth - (@widthStep * @roadLines)
            j = y = 0
            scan = []
            for i in [0...@roadLines]
                j = @roadLines - 1 - i
                tex = (@zMap[j] + @texOffset) % 100 > 50
                y = (rry[j])|0
                scan[y] = [tex, rrx[j], y, half_width / @zFactor - @zFactor2, i]
                half_width += @widthStep

            h = y = y2 = 0
            len = scan.length
            @backgroundPosition = null
            while y < len
                if scan[y]
                    unless @backgroundPosition
                        @backgroundPosition = [scan[y][1], scan[y][2]]
                        @clearCanvas()
                    h = 1
                    y2 = y + 1
                    while y2 < len and (!scan[y2] or scan[y2][4] < scan[y][4])
                        ++h
                        ++y2
                    @drawGround scan[y][0], scan[y][2], h
                    if h > 1 && scan[y2]
                        @drawRoadLine2 scan[y][0], scan[y][1], scan[y2][1], scan[y][2], scan[y2][2], scan[y][3], scan[y2][3], h
                    else
                        @drawRoadLine scan[y][0], scan[y][1], scan[y][2], scan[y][3], h
                    y += h
                else
                    ++y

            delete scan
            return

        getShaderProg: (texture) ->
            # [ /*coords:*/ [], /*width:*/ [], /*paint:*/ [[<styleIndex>, [<coordsIndex>, <widthIndex>], ..], .. ]

            unless @shaders
                @shaders = {}
                @shaders[true] = [
                    [
                        -(@halfWidth/2)-@sideWidth,
                        @halfWidth/2,
                        -@halfWidth/2,
                        @sideWidth/2
                    ],
                    [
                        @sideWidth,
                        @halfWidth
                    ],
                    [
                        [1, [0, 0], [1, 0]],
                        [2, [2, 1]],
                        [3, [3, 0]]
                    ]
                ]
                @shaders[false] = [
                    [
                        -(@halfWidth/2)-@sideWidth,
                        @halfWidth/2,
                        -@halfWidth/2,
                        @sideWidth/2
                    ],
                    [
                        @sideWidth,
                        @halfWidth
                    ],
                    [
                        [1, [0, 0], [1, 0]],
                        [2, [2, 1]]
                    ]
                ]

            return @shaders[!!texture]

        drawRoadLine: (texture, x, y, scaleX, h = 1) ->
            shader = @getShaderProg texture

            coords = []
            for c in shader[0]
                coords.push x + c * scaleX

            widths = []
            for w in shader[1]
                widths.push w * scaleX

            for paint in shader[2]
                @roadCtx.fillStyle = @colortheme[texture][paint[0]]
                for i in [1...paint.length]
                    @roadCtx.fillRect coords[paint[i][0]], y, widths[paint[i][1]], h

            return

        drawRoadLine2: (texture, x, x2, y, y2, scaleX, scaleX2, h) ->
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

        drawGround: (texture, y, h) ->
            @roadCtx.fillStyle = @colortheme[texture][0]
            @roadCtx.fillRect 0, y, @width, h
            return

        clearCanvas: ->
            if @backgroundImage and @backgroundPosition
                @groundCtx.drawImage @backgroundImage,
                    @width - @backgroundPosition[0],
                    @height - @backgroundPosition[1],
                    @width,
                    @backgroundPosition[1],
                    0,
                    0,
                    @width,
                    @backgroundPosition[1]
            else
                @groundCtx.fillStyle = "#60a0c0"
                @groundCtx.fillRect 0, 0, @width, @height

            @roadCtx.clearRect 0, 0, @width, @height
            return

        race: ->
            return if @pause

            @texOffset += @speed
            if @texOffset >= 100
                @texOffset -= 100

            @segmentY -= 1
            if @segmentY < 0
                @segmentY += @roadLines
                if @nextStretch == 'straight'
                    @nextStretch = "curved"
                else
                    @nextStretch = 'straight'

            @drawRoad()
            return


    # http://active.tutsplus.com/tutorials/games/create-a-racing-game-without-a-3d-engine/
    #
    console.log("CoffeeRoadRace by spearwolf <wolfger@spearwolf.de>")

    racer = window.racer = new CoffeeRoadRace "roadRace"

    reqAnimFrame = window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame
    anim = ->
        racer.race()
        reqAnimFrame anim

    anim()

