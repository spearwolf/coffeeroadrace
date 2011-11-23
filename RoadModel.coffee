class RoadModel

    CLEAR_CANVAS = 0
    DRAW_GROUND = 1
    DRAW_ROAD_LINE = 2
    DRAW_ROAD_LINE2 = 3

    constructor: (@width, @height) ->
        @roadLineCount = (0.5 + @height / 2)|0
        @halfWidth = @width/2
        @distanceStep = (@height * 0.5) / @roadLineCount
        @zFactor = @height >> 1
        @zFactor2 = 1.95
        @zFactor3 = 2.0
        @noScaleLine = 8
        @populateZMap()
        @createScaleMap()
        @curveMap = (Math.pow(Math.sin(i/@roadLineCount*Math.PI/2), 4) for i in [0...@roadLineCount])

    populateZMap: ->
        @depthMap = (1.0 / ((i * @distanceStep) - (@height / 1.85)) for i in [0...@roadLineCount])
        playerZ = 100.0 / @depthMap[@noScaleLine]
        for i in [0...@roadLineCount]
            @depthMap[i] *= playerZ
        return

    createScaleMap: ->
        distance = @height - (@distanceStep * @roadLineCount)
        @scaleMap = (for i in [0...@roadLineCount]
                        d = distance
                        distance += @distanceStep
                        ((d * @zFactor3) / @zFactor) - @zFactor2)

    makeCurvesAndHills: (xOffset, segment) ->
        x = 0
        y = @height - 1
        xMap = []
        yMap = []
        dx = dy = 0
        for i in [0...@roadLineCount]
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

            #if segmentType == 'curved'
            #curve = segment.curve * Math.pow(Math.sin(i/@roadLineCount*Math.PI/2), 4)
            #curve = 
            dx += segment.curve * @curveMap[i] * segment.ddx

            x += dx
            y += dy - 1

            xMap.push @halfWidth + x + xOffset * ((@roadLineCount - i) / @roadLineCount)
            yMap.push y

        return [xMap, yMap]

    createScanlines: (xMap, yMap, texOffset) ->
        j = y = 0
        scanline = []
        for i in [0...@roadLineCount]
            j = @roadLineCount - 1 - i
            tex = (@depthMap[j] + texOffset) % 100 > 50
            y = yMap[j] | 0
            scanline[y] = [tex, xMap[j], y, @scaleMap[i], i]
        return scanline

    createRenderList: (xOffset, texOffset, segment) ->
        [xMap, yMap] = @makeCurvesAndHills xOffset, segment
        scanline = @createScanlines xMap, yMap, texOffset

        h = y = yNext = 0
        scanlineCount = scanline.length
        foundBgPos = false
        renderList = []
        while y < scanlineCount
            unless scanline[y]
                ++y
            else
                unless foundBgPos
                    renderList.push [CLEAR_CANVAS, scanline[y][1], scanline[y][2]]
                    foundBgPos = true
                h = 1
                yNext = y + 1
                while yNext < scanlineCount and (!scanline[yNext] or scanline[yNext][4] < scanline[y][4])
                    ++h
                    ++yNext
                renderList.push [DRAW_GROUND, scanline[y][0], scanline[y][2], h]
                if h > 1 && scanline[yNext]
                    #renderList.push [DRAW_ROAD_LINE, scanline[y][0], scanline[y][1], scanline[y][2], scanline[y][3], h]
                    renderList.push [DRAW_ROAD_LINE2, scanline[y][0], scanline[y][1], scanline[yNext][1], scanline[y][2], scanline[yNext][2], scanline[y][3], scanline[yNext][3], h]
                else
                    renderList.push [DRAW_ROAD_LINE, scanline[y][0], scanline[y][1], scanline[y][2], scanline[y][3], h]
                y += h

        return renderList


if window?
    window.RoadModel = RoadModel
else
    roadModel = null
    self.addEventListener "message", (e) ->
        switch e.data.action
            when 'init'
                roadModel = new RoadModel e.data.width, e.data.height
            when 'createRenderList'
                self.postMessage
                    action: 'renderList',
                    renderList: roadModel.createRenderList(e.data.xOffset, e.data.texOffset, e.data.segment)

