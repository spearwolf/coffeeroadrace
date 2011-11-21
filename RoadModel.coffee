class RoadModel

    CLEAR_CANVAS = 0
    DRAW_GROUND = 1
    DRAW_ROAD_LINE = 2
    DRAW_ROAD_LINE2 = 3

    constructor: (@width, @height) ->
        @roadLines = (0.5 + @height / 2)|0
        @halfWidth = @width/2
        @distanceStep = (@height * 0.5) / @roadLines
        @zFactor = @height >> 1
        @zFactor2 = 1.95
        @zFactor3 = 2.0
        @noScaleLine = 8
        @populateZMap()
        @ddx = 0.015 * @distanceStep
        @ddy = 0.01 * @distanceStep

    populateZMap: ->
        # Populate the zMap with the depth of the road lines
        @zMap = (1.0 / ((i * @distanceStep) - (@height / 1.85)) for i in [0...@roadLines])
        playerZ = 100.0 / @zMap[@noScaleLine]
        for i in [0...@roadLines]
            @zMap[i] *= playerZ
        return

    updateRoad: (xOffset, texOffset) ->  # {{{
        x = @halfWidth + xOffset
        y = @height - 1
        xMap = []
        yMap = []
        dx = dy = 0
        for i in [0...@roadLines]
            xMap.push x
            yMap.push y

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
            x += dx
            y += dy - 1

        distance = @height - (@distanceStep * @roadLines)
        j = y = scaleX = 0
        scanline = []
        for i in [0...@roadLines]
            j = @roadLines - 1 - i
            tex = (@zMap[j] + texOffset) % 100 > 50
            y = yMap[j] | 0
            scaleX = ((distance * @zFactor3) / @zFactor) - @zFactor2
            scanline[y] = [tex, xMap[j], y, scaleX, i]
            distance += @distanceStep

        h = y = yNext = 0
        scanlineCount = scanline.length
        foundBgPos = false
        renderList = []
        while y < scanlineCount
            if scanline[y]
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
                    renderList.push [DRAW_ROAD_LINE2, scanline[y][0], scanline[y][1], scanline[yNext][1], scanline[y][2], scanline[yNext][2], scanline[y][3], scanline[yNext][3], h]
                else
                    renderList.push [DRAW_ROAD_LINE, scanline[y][0], scanline[y][1], scanline[y][2], scanline[y][3], h]
                y += h
            else
                ++y

        delete scanline
        return renderList


roadModel = null
self.addEventListener "message", (e) ->
    switch e.data.action
        when 'init'
            roadModel = new RoadModel e.data.width, e.data.height
        when 'updateRoad'
            self.postMessage
                action: 'renderList',
                renderList: roadModel.updateRoad(e.data.xOffset, e.data.texOffset)

