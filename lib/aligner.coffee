{Range} = require 'atom'

module.exports =
    class Aligner
        # Public
        constructor: (@editor, @spaceChars, @matcher, @trimRight) ->
            @lineNums = []
            cursors = @editor.getCursors()
            cnt = 0
            for cursor in cursors
                cnt += 1 if cursor.visible

            if (cnt > 1)
                for cursor in cursors
                    @lineNums.push(cursor.getBufferRow())
            else
                ranges = @editor.getSelectedBufferRanges()
                for range in ranges
                    @lineNums = @lineNums.concat(range.getRows())
                    @lineNums.pop() if range.end.column == 0

            @lines = []
            for line in @lineNums
                o =
                    text   : @editor.lineTextForBufferRow(line)
                    length : @editor.lineLengthForBufferRow(line)
                    line   : line
                @lines.push (o)

        # Private
        __computeLines: (startPos) =>
            if @lines.length > 0
                max     = 0
                maxParts = []
                matched = null
                @lines.forEach (o) =>
                    line = o.text
                    unless matched
                        @matcher.forEach (possibleMatcher) ->
                            unless matched
                                if (line.indexOf possibleMatcher, startPos) isnt -1
                                    matched = possibleMatcher
                            return

                    splitString = line.split(matched)

                    if splitString.length > 1
                        splitString[0] = splitString[0].replace(/\s+$/g, '')
                        # Detection of max in this range
                        max = if max < splitString[0].length then splitString[0].length else max
                    return

                if (max > 0)
                    addSpacePrefix = @spaceChars.indexOf(matched) > -1
                    max            = max + if addSpacePrefix then 2 else 1

                    @lines.forEach (o) =>
                        line = o.text
                        if max and matched
                            splitString = line.split(matched)
                            if splitString.length > 1
                                # Remove un needed space
                                splitString[0] = splitString[0].replace(/\s+$/g, '')
                                diff = max - splitString[0].length

                                if diff > 0
                                    splitString[0] = splitString[0] + Array(diff).join(' ')

                                if @trimRight
                                    splitString[1] = if addSpacePrefix then " "+splitString[1].trim() else splitString[1].trim()

                                o.text = splitString.join(matched)
                        return
            return max

        # Public
        align: =>
            @__computeLines(0)

            @lines.forEach (o) =>
                @editor.setTextInBufferRange([[o.line, 0],[o.line, o.length]], o.text)
