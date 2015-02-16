{Range} = require 'atom'

module.exports =
    class Aligner

        # Public
        @alignFor: (editor) ->
            new Aligner(editor).lines()

        # Public
        constructor: (@editor) ->
            @mode = if @editor.cursors.length > 1 then "cursors" else "selection"

        # Public
        lines: ->
            selectionRanges = @selectionRanges()
            if selectionRanges.length isnt 0
                selectionRanges.map (selectionRange) =>
                    @sortableRangeFrom(selectionRange)

        # Internal
        selectionRanges: =>
            if (@mode == "cursors")
                ranges = []
                for cursor in @editor.cursors
                    range = cursor.getCurrentLineBufferRange()
                    ranges.push range if not range.isEmpty()
                return ranges
            else
                @editor.getSelectedBufferRanges().filter (range) ->
                    not range.isEmpty()

        # Internal
        sortableRangeForEntireBuffer: ->
            @editor.getBuffer().getRange()

        # Internal
        sortableRangeFrom: (selectionRange) ->
            startRow = selectionRange.start.row
            startCol = 0
            endRow = if selectionRange.end.column == 0 then selectionRange.end.row - 1 else selectionRange.end.row
            endCol = @editor.lineLengthForBufferRow(endRow)
            new Range [startRow, startCol], [endRow, endCol]
