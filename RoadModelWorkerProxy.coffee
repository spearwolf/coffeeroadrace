window.RoadModel = class RoadModel

    constructor: (width, height) ->
        @renderQueue = []
        @worker = new Worker 'RoadModel.js'
        @worker.postMessage
            action: 'init',
            width: width,
            height: height
        @worker.addEventListener 'message', (e) =>
            if e.data.action is 'renderList'
                @renderQueue.push e.data.renderList

    createRenderList: (xOffset, texOffset, segment) ->
        @worker.postMessage
            action: 'createRenderList',
            xOffset: xOffset,
            texOffset: texOffset,
            segment: segment
        @renderQueue.shift()

