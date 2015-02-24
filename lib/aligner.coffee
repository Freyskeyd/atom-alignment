{Range} = require 'atom'

_ = require 'lodash'

module.exports =
    class Aligner
        # Public
        constructor: (@editor, @spaceChars, @matcher, @addSpacePostfix) ->
            @rows = []
            @alignments = []

        # Private
        __getRows: =>
            rowNums = []
            cursors = _.filter @editor.getCursors(), (cursor) ->
                row = cursor.getBufferRow()
                if cursor.visible && !_.contains(rowNums, row)
                    rowNums.push(row)
                    return true

            if (cursors.length > 1)
                @mode = "cursor"
                for cursor in cursors
                    row = cursor.getBufferRow()
                    o =
                        text   : cursor.getCurrentBufferLine()
                        length : @editor.lineTextForBufferRow(row).length
                        row    : row
                        column : cursor.getBufferColumn()
                    @rows.push (o)
            else
                ranges = @editor.getSelectedBufferRanges()
                for range in ranges
                    rowNums = rowNums.concat(range.getRows())
                    rowNums.pop() if range.end.column == 0

                for row in rowNums
                    o =
                        text   : @editor.lineTextForBufferRow(row)
                        length : @editor.lineTextForBufferRow(row).length
                        row    : row
                    @rows.push (o)

                @mode = if @rows.length > 1 then "default" else "single"

            if @mode != "cursor"
                @rows.forEach (o) ->
                    if o.text[0] == " "
                        firstCharPos  = o.text.length-o.text.trimLeft().length
                        o.text        = Array(firstCharPos).join(" ")+" "+o.text.substring(firstCharPos).replace(/\s{2,}/g, ' ')
                    else
                        o.text        = o.text.replace(/\s{2,}/g, ' ')

        __getAllIndexes: (string, val, indexes) ->
            found = []
            i = 0
            loop
                i = string.indexOf(val, i)
                if i != -1 && !_.some(indexes, {index:i})
                    found.push({found:val,index:i})

                break if i == -1
                i++
            return found

        #generate the sequence of alignment characters computed from the first matching line
        __generateAlignmentList: () =>
            i = 0
            _.forEach @rows, (o) =>
                _.forEach @matcher, (possibleMatcher) =>
                    @alignments = @alignments.concat (@__getAllIndexes o.text, possibleMatcher, @alignments)

                if @alignments.length > 0
                    return false # exit if we got all alignments characters in the row
                else
                    return true # continue
            @alignments = @alignments.sort (a, b) -> a.index - b.index
            @alignments = _.pluck @alignments, "found"
            return

        __computeRows: () =>
            max = 0
            if @mode == "default" || @mode == "single" || @mode == "break"
                matched = null
                idx = -1
                possibleMatcher = @alignments.shift()
                addSpacePrefix = @spaceChars.indexOf(possibleMatcher) > -1
                @rows.forEach (o) =>
                    o.splited = null
                    if !o.done
                        line = o.text
                        if (line.indexOf(possibleMatcher, o.nextPos) != -1)
                            matched = possibleMatcher
                            idx = line.indexOf(matched, o.nextPos)
                            len = matched.length
                            if @mode == "break"
                                idx += len-1
                                c = ""
                                blankPos = -1
                                quotationMark = doubleQuotationMark = 0
                                backslash = charFound = false
                                loop
                                    break if c == undefined
                                    c = line[++idx]
                                    if c == "'" and !backslash then quotationMark++
                                    if c == '"' and !backslash then doubleQuotationMark++
                                    backslash = if c == "\\" and !backslash then true else false
                                    charFound = if c != " " and !charFound then true else charFound
                                    if c == " " and quotationMark % 2 == 0 and doubleQuotationMark % 2 == 0 and charFound
                                        blankPos = idx
                                        break

                                idx = blankPos

                            next = if @mode == "break" then 1 else len

                            if idx isnt -1
                                splitString  = [line.substring(0,idx), line.substring(idx+next)]
                                o.splited = splitString
                                if max < splitString[0].length
                                    max = splitString[0].length
                                    max++ if addSpacePrefix && splitString[0].charAt(splitString[0].length-1) != " "

                        found = false
                        _.forEach @alignments, (nextPossibleMatcher) ->
                            if (line.indexOf(nextPossibleMatcher, idx+len) != -1)
                                found = true
                                return false

                        o.stop = !found

                    return

                if (max >= 0)
                    max++ if max > 0

                    @rows.forEach (o) =>
                        if !o.done and o.splited and matched
                            splitString = o.splited

                            diff = max - splitString[0].length

                            if diff > 0
                                splitString[0] = splitString[0] + Array(diff).join(' ')

                            splitString[1] = " "+splitString[1].trim() if @addSpacePostfix && addSpacePrefix

                            if @mode == "break"
                                _.forEach splitString, (s, i) ->
                                    splitString[i] = s.trim()

                                o.text = splitString.join("\n")
                            else
                                o.text = splitString.join(matched)
                            o.done = o.stop
                            o.nextPos = splitString[0].length+matched.length
                        return
            else
                @rows.forEach (o) ->
                    max = if max < o.column then o.column else max

                max++

                @rows.forEach (o) ->
                    line = o.text
                    splitString = [line.substring(0,o.column), line.substring(o.column)]

                    diff = max - splitString[0].length

                    if diff > 0
                        splitString[0] = splitString[0] + Array(diff).join(' ')

                    splitString[1] = splitString[1].trim()

                    o.text = splitString.join("")
                    return

            return @alignments.length > 0

        # Public
        align: (multiple) =>
            @__getRows()
            @__generateAlignmentList()
            if @mode == "single" && multiple
                @mode = "break"

            if multiple || @mode == "single"
                loop
                    cont = @__computeRows()
                    break if not cont
            else
                @__computeRows()

            @rows.forEach (o) =>
                @editor.setTextInBufferRange([[o.row, 0],[o.row, o.length]], o.text)
