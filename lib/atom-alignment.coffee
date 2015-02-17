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
        atom.commands.add 'atom-workspace',
            'atom-alignment:align': ->
                editor = atom.workspace.getActivePaneItem()
                alignLines editor

            'atom-alignment:alignMultiple': ->
                editor = atom.workspace.getActivePaneItem()
                alignLinesMultiple editor

alignLines = (editor) ->
    spaceChars     = atom.config.get 'atom-alignment.alignmentSpaceChars'
    matcher        = atom.config.get 'atom-alignment.alignBy'
    trimRight      = atom.config.get 'atom-alignment.trimRight'
    a = new Aligner(editor, spaceChars, matcher, trimRight)
    a.align(false)
    return

alignLinesMultiple = (editor) ->
    spaceChars     = atom.config.get 'atom-alignment.alignmentSpaceChars'
    matcher        = atom.config.get 'atom-alignment.alignBy'
    trimRight      = atom.config.get 'atom-alignment.trimRight'
    a = new Aligner(editor, spaceChars, matcher, trimRight)
    a.align(true)
    return
