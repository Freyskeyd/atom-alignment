Aligner = require './aligner'

module.exports =
    config:
        alignBy:
            type: 'array'
            default: ['=>', ':=', ':', '=']
            items:
                type: "string"
            description: "consider the order, the left most matching separator is taken to compute the alignment"
            order: 1
        leftAlignChars:
            type: 'array'
            default: [':']
            items:
                type: "string"
            description: "when aligning, keep these characters aligned to the left"
            order: 2
        leftSpaceChars:
            type: 'array'
            default: ['=>', ':=', '=']
            items:
                type: "string"
            description: "insert space left of the separator (a=1 > a =1)"
            order: 3
        rightSpaceChars:
            type: 'array'
            default: ['=>', ':=', '=', ":"]
            items:
                type: "string"
            description: "insert space right of the separator (a=1 > a= 1)"
            order: 4
        ignoreChars:
            type: 'array'
            default: ['===', '!==', '==', '!=', '>=', '<=', '::']
            items:
                type: "string"
            description: "ignore as separator"
            order: 5

    activate: (state) ->
        atom.commands.add 'atom-workspace',
            'atom-alignment:align': ->
                alignLines false

            'atom-alignment:alignMultiple': ->
                alignLines true

alignLines = (multiple) ->
    editor          = atom.workspace.getActiveTextEditor()
    leftAlignChars  = atom.config.get('atom-alignment.leftAlignChars',  scope: editor.getRootScopeDescriptor())
    leftSpaceChars  = atom.config.get('atom-alignment.leftSpaceChars',  scope: editor.getRootScopeDescriptor())
    rightSpaceChars = atom.config.get('atom-alignment.rightSpaceChars', scope: editor.getRootScopeDescriptor())
    matcher         = atom.config.get('atom-alignment.alignBy',         scope: editor.getRootScopeDescriptor())
    ignoreChars     = atom.config.get('atom-alignment.ignoreChars',     scope: editor.getRootScopeDescriptor())
    aligner         = new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars)
    aligner.align(multiple)
    return
