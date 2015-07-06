{Range} = require 'atom'

_ = require 'lodash'

class Ignorelist
    #public
    constructor: (string, regexp) ->
        @__ignoreList = []
        if regexp?
            while match = regexp.exec(string)
                @__ignoreList.push {start:match.index, end:match.index + match[0].length}

    contains: (matcher, idx) =>
        found = false
        _.forEach @__ignoreList, (ignore) ->
            if ignore.start <= idx && ignore.end >= idx + matcher.length
                found = true
                return false

        return found

class SafeRegExp
    #public
    constructor: (parts) ->
        _.each parts, (part, idx) ->
            if part == "|"
                parts[idx] = "\\"+part

        @__regex = new RegExp(parts.join("|"), "g")

    exec: (s) =>
        @__regex.exec(s)

module.exports =
    class Aligner
        # Public
        constructor: (@editor, @leftSpaceChars, @rightSpaceChars, @matcher, @ignoreChars) ->
            @rows = []
            @alignments = []
            @ignoreRegexp = new SafeRegExp(@ignoreChars) if @ignoreChars.length > 0

        # Private
        __getRows: =>
            rowNums = []
            allCursors = []
            cursors = _.filter @editor.getCursors(), (cursor) ->
                allCursors.push(cursor)
                row = cursor.getBufferRow()
                if cursor.visible && !_.contains(rowNums, row)
                    rowNums.push(row)
                    return true

            if (cursors.length > 1)
                @mode = "cursor"
                for cursor in cursors
                    row = cursor.getBufferRow()
                    t = @editor.lineTextForBufferRow(row)
                    v = cursor.getBufferColumn()
                    l = @__computeLength(t.substring(0, v))
                    o =
                        text   : t
                        length : t.length
                        row    : row
                        column : l
                        virtualColumn: v
                    @rows.push (o)
            else
                rowNums = []
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

                @mode = "align"

            if @mode != "cursor"
                @rows.forEach (o) ->
                    t = o.text.replace(/\s/g, '')
                    if t.length > 0
                        firstCharIdx = o.text.indexOf(t.charAt(0))
                        o.text = o.text.substr(0,firstCharIdx) + o.text.substring(firstCharIdx).replace(/\ {2,}/g, ' ')

                    return
            return

        __getAllIndexes: (string) =>
            ignoreList = new Ignorelist string, @ignoreRegexp
            allMatcherRegEx = new SafeRegExp(@matcher) if @matcher.length > 0
            allMatcher = []
            if allMatcherRegEx?
                while match = allMatcherRegEx.exec(string)
                    if !ignoreList.contains(match, match.index)
                        allMatcher.push {matcher: match[0], start:match.index, end:match.index + match[0].length}

            return allMatcher

        __getNextMatcher: (start, matcher, text) =>
            allMatcher = @__getAllIndexes(text)

            canUseMatcher = (i) ->
                found = false
                _.forEach allMatcher, (m) ->
                    if m.start == i && m.end == i + matcher.length && m.matcher == matcher
                        found = true
                        return false

                return found

            ret = -1
            idx = text.indexOf matcher, start
            while idx >= 0
                if canUseMatcher idx
                    ret = idx
                    break
                else
                    start = idx + 1

                idx = text.indexOf matcher, start

            return ret

        #generate the sequence of alignment characters computed from the first matching line
        __generateAlignmentList: () =>
            if @mode == "cursor"
                _.forEach @rows, (o) =>
                    part = o.text.substring(o.virtualColumn)
                    _.forEach @leftSpaceChars, (char) ->
                        idx = part.indexOf(char)
                        if idx == 0 && o.text.charAt(o.virtualColumn) != " "
                            o.leftSpace = true
                            o.leftSpaceCharLength = char.length
                            return false

                    _.forEach @rightSpaceChars, (char) ->
                        idx = part.indexOf(char)
                        if idx == 0 && o.text.charAt(o.virtualColumn)+char.length != " "
                            o.rightSpace = true
                            o.rightSpaceCharLength = char.length
                            return false

                    return
            else
                _.forEach @rows, (o) =>
                    newAlignments = @__getAllIndexes(o.text)

                    if newAlignments.length > @alignments.length
                        @alignments = newAlignments.slice()

                @alignments = @alignments.sort (a, b) -> a.start - b.start
                @alignments = _.pluck @alignments, "matcher"
                console.log("atom-alignment: normal mode -> matcher: #{@alignments}")
                return

        __computeLength: (s) =>
            diff = tabs = idx = 0
            tabLength = @editor.getTabLength()
            for char in s
                if char == "\t"
                    diff += tabLength - (idx % tabLength)
                    idx += tabLength - (idx % tabLength)
                    tabs++
                else
                    idx++

            return s.length+diff-tabs

        __computeRows: () =>
            max = 0
            if @mode == "align" || @mode == "break"
                matched = null
                idx = -1
                possibleMatcher = @alignments.shift()
                leftSpace = @leftSpaceChars.indexOf(possibleMatcher) > -1
                rightSpace = @rightSpaceChars.indexOf(possibleMatcher) > -1
                @rows.forEach (o) =>
                    o.splited = null
                    if !o.done
                        line = o.text
                        idx = @__getNextMatcher(o.nextPos, possibleMatcher, line)
                        if (idx != -1)
                            matched = possibleMatcher
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
                                splitString[0] = splitString[0].trimRight() if not leftSpace
                                splitString[1] = splitString[1].trimLeft() if not rightSpace
                                o.splited = splitString
                                l = @__computeLength(splitString[0])
                                if max <= l
                                    max = l
                                    max++ if l > 0 && leftSpace && splitString[0].charAt(splitString[0].length-1) != " "

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
                            diff = max - @__computeLength(splitString[0])
                            if diff > 0
                                splitString[0] = splitString[0] + Array(diff).join(' ')

                            splitString[1] = " "+splitString[1].trim() if rightSpace

                            if @mode == "break"
                                _.forEach splitString, (s, i) ->
                                    splitString[i] = s.trim()
                                    return

                                o.text = splitString.join("\n")
                            else
                                o.text = splitString.join(matched)
                            o.done = o.stop
                            o.nextPos = splitString[0].length+matched.length
                        return
                return @alignments.length > 0
            else #cursor
                @rows.forEach (o) ->
                    if max <= o.column
                        max = o.column
                        part = o.text.substring(0,o.virtualColumn)
                        max++ if part.length > 0 && o.leftSpace && part.charAt(part.length-1) != " "
                    return

                max++

                @rows.forEach (o) =>
                    line = o.text
                    splitString = [line.substring(0,o.virtualColumn), line.substring(o.virtualColumn)]
                    diff = max - @__computeLength(splitString[0])
                    if diff > 0
                        splitString[0] = splitString[0] + Array(diff).join(' ')

                    o.leftSpaceCharLength ?= 0
                    o.rightSpaceCharLength ?= 0
                    splitString[1] = splitString[1].substring(0, o.leftSpaceCharLength) + splitString[1].substr(o.leftSpaceCharLength).trim()
                    if o.rightSpace
                        splitString[1] = splitString[1].substring(0, o.rightSpaceCharLength) + " " +splitString[1].substr(o.rightSpaceCharLength)

                    o.text = splitString.join("")
                    return
                return false

        # Public
        align: (multiple) =>
            @__getRows()
            @__generateAlignmentList()
            if @rows.length == 1 && multiple
                @mode = "break"

            if multiple || @mode == "break"
                loop
                    cont = @__computeRows()
                    break if not cont
            else
                @__computeRows()

            @rows.forEach (o) =>
                @editor.setTextInBufferRange([[o.row, 0],[o.row, o.length]], o.text)
                return
