jQuery ($) ->

    class RoadModel  # {{{
        constructor: (@width, @height) ->
            @roadLines = (0.5 + @height / 2)|0
            @halfWidth = @width/2
            @heightStep = (@height * 0.5) / @roadLines
            @zFactor = @height >> 1
            @zFactor2 = 1.95
            @zFactor3 = 2.0
            @noScaleLine = 8
            @populateZMap()
            @ddx = 0.015 * @heightStep
            @ddy = 0.01 * @heightStep
            console.log "RoadModel initialized"

        populateZMap: ->  # {{{
            # Populate the zMap with the depth of the road lines
            @zMap = (1.0 / ((i * @heightStep) - (@height / 1.85)) for i in [0...@roadLines])
            playerZ = 100.0 / @zMap[@noScaleLine]
            for i in [0...@roadLines]
                @zMap[i] *= playerZ
            return
            # }}}

        updateRoad: (xOffset, texOffset) ->  # {{{
            rx = @halfWidth + xOffset
            ry = @height - 1
            rrx = []
            rry = []
            dx = dy = 0
            for i in [0...@roadLines]
                rrx.push rx
                rry.push ry

                #switch @nextStretch
                    #when "straight"
                        #if i >= @segmentY
                            #dx += @ddx
                            #dy -= @ddy
                        #else
                            #dx -= @ddx / 64
                            #dy += @ddy

                    #when "curved"
                        #if i <= @segmentY
                            #dx += @ddx
                            #dy -= @ddy
                        #else
                            #dx -= @ddx / 64
                            #dy += @ddy
                rx += dx
                ry += dy - 1

            distance = @height - (@heightStep * @roadLines)
            j = y = scaleX = 0
            scan = []
            for i in [0...@roadLines]
                j = @roadLines - 1 - i
                tex = (@zMap[j] + texOffset) % 100 > 50
                y = (rry[j])|0
                scaleX = ((distance * @zFactor3) / @zFactor) - @zFactor2
                scan[y] = [tex, rrx[j], y, scaleX, i]
                distance += @heightStep

            h = y = y2 = 0
            len = scan.length
            backgroundPosition = null
            renderList = []
            while y < len
                if scan[y]
                    unless backgroundPosition
                        backgroundPosition = [scan[y][1], scan[y][2]]
                        renderList.push [0, backgroundPosition[0], backgroundPosition[1]]
                    h = 1
                    y2 = y + 1
                    while y2 < len and (!scan[y2] or scan[y2][4] < scan[y][4])
                        ++h
                        ++y2
                    renderList.push [1, scan[y][0], scan[y][2], h]
                    if h > 1 && scan[y2]
                        renderList.push [3, scan[y][0], scan[y][1], scan[y2][1], scan[y][2], scan[y2][2], scan[y][3], scan[y2][3], h]
                    else
                        renderList.push [2, scan[y][0], scan[y][1], scan[y][2], scan[y][3], h]
                    y += h
                else
                    ++y

            delete scan
            return renderList
            # }}}

    # end of class RoadModel }}}

    class CoffeeRoadRace  # {{{
        constructor: (@containerId) ->  # {{{
            @width = $("##{@containerId}").width()
            @height = $("##{@containerId}").height()

            @model = new RoadModel(@width, @height)

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
            renderList = @model.updateRoad(@xOffset, @texOffset)
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

