Aligner = require './aligner'

module.exports =
    config:
        alignmentSpaceChars:
            type: 'array'
            default: ['=', ':']
            items:
                type: "string"
            description: "insert space in front of the character (a=1 > a =1)"
        alignBy:
            type: 'array'
            default: [':=', ':', '=']
            items:
                type: "string"
            description: "consider the order, the left most matching value is taken to compute the alignment"
        trimRight:
            type: 'boolean'
            default: false
            description: "also trim the right part of the variable after the matching character"

    activate: (state) ->
        atom.commands.add 'atom-workspace', 'atom-alignment:align', ->
            editor = atom.workspace.getActivePaneItem()
            alignLines editor


alignLines = (editor) ->
    spaceChars     = atom.config.get 'atom-alignment.alignmentSpaceChars'
    matcher        = atom.config.get 'atom-alignment.alignBy'
    trimRight      = atom.config.get 'atom-alignment.trimRight'
    alignableLines = Aligner.alignFor editor
    # If selected lines
    if alignableLines
        # For each range
        max     = 0
        matched = null
        alignableLines.forEach (range) ->

            # Split lines
            textLines = editor.getTextInBufferRange(range).split("\n")

            # If we have more one line
            textLines.forEach (a, b) ->
                # If no matcher has be set for the moment
                # We try to take on
                unless matched
                    matcher.forEach (possibleMatcher) ->
                        unless matched
                            if (a.indexOf possibleMatcher, 0) isnt -1
                                matched = possibleMatcher

                splitString = a.split(matched)

                if splitString.length > 1
                    splitString[0] = splitString[0].replace(/\s+$/g, '')
                    # Detection of max in this range
                    max = if max < splitString[0].length then splitString[0].length else max

        addSpacePrefix = spaceChars.indexOf(matched) > -1
        max            = max + if addSpacePrefix then 2 else 1

        alignableLines.forEach (range) ->
            textLines = editor.getTextInBufferRange(range).split("\n")
            if max and matched
                textLines.forEach (a, b) ->
                    splitString = a.split(matched)
                    if splitString.length > 1
                        # Remove un needed space
                        splitString[0] = splitString[0].replace(/\s+$/g, '')
                        diff = max - splitString[0].length

                        if diff > 0
                            splitString[0] = splitString[0] + Array(diff).join(' ')

                        if (splitString[1] && splitString[1].charAt(0) != ' ')
                            splitString[1] = splitString[1]

                        if trimRight
                            splitString[1] = if addSpacePrefix then " "+splitString[1].trim() else splitString[1].trim()

                        textLines[b] = splitString.join(matched)

                editor.setTextInBufferRange(range, textLines.join('\n'))
