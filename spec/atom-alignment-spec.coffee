Aligner = require '../lib/aligner.coffee'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "atom-alignment", ->
    leftAlignChars  = [':']
    leftSpaceChars  = ['=>', ':=', '=']
    rightSpaceChars = ['=>', ':=', '=', ':']
    matcher         = ['=>', ':=', ':', '=']
    ignoreChars     = ['===', '==', '!==', '!=', '::']
    editor          = null

    align = (callback) ->
        runs(callback)

    beforeEach ->
        waitsForPromise ->
            atom.workspace.open()

        runs ->
            editor = atom.workspace.getActiveTextEditor()
            editorView = atom.views.getView(editor)
            return

    describe "when aligner is called on one line only", ->
        it "has to break the line", ->
            editor.setText "var a = 1; var b = 2;"
            editor.setCursorScreenPosition([1, 1])
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 1).toEqual "var b = 2;"

    describe "when aligner is called on multiple lines with only one matcher", ->
        it "should align correctly", ->
            editor.setText "var a = 1;\nvar bbb =    2;"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 1).toEqual "var bbb = 2;"

    describe "when aligner is called on multiple lines with different matchers", ->
        it "should align correctly", ->
            editor.setText "var a = 1; b:2; c:3;d=4\nvar bbb   : 2;"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 1).toEqual "var bbb:      2;"

    describe "when aligner is called on lines with multiple char matchers", ->
        it "should align correctly", ->
            editor.setText "var a => 1; b = 2;\nvar bbb   => 2;"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 1).toEqual "var bbb => 2;"

    describe "when aligner is called on lines with ignore chars", ->
        it "should align correctly", ->
            editor.setText "a::a::a:1\nbbb::bbb=ccc:1"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a::a::a:         1"

    describe "when there is everything put together (1)", ->
        it "should align correctly", ->
            editor.setText "a::a=b=c=>d\naaaaa=b=>a\nfffffffffff=ffffffff=>h"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a::a        = b = c    => d"
                expect(editor.lineTextForBufferRow 1).toEqual "aaaaa       = b        => a"
                expect(editor.lineTextForBufferRow 2).toEqual "fffffffffff = ffffffff => h"

    describe "when there is everything put together (2)", ->
        it "should align correctly", ->
            editor.setText "a=b=>c\naa=bb=>cc\nb=>c=a\nbb=>cc=aa"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a      = b  => c"
                expect(editor.lineTextForBufferRow 1).toEqual "aa     = bb => cc"
                expect(editor.lineTextForBufferRow 2).toEqual "b=>c   = a"
                expect(editor.lineTextForBufferRow 3).toEqual "bb=>cc = aa"

    describe "when indentation is mixed with spaces and tabs", ->
        it "should align correctly", ->
            editor.setText "aa = 4\na	= 1\nb  = 2\nc::3=4"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "aa   = 4"
                expect(editor.lineTextForBufferRow(1).replace(/\t/g,"t")).toEqual "at   = 1" #specs cannot handle tabs  ... wtf?
                expect(editor.lineTextForBufferRow 2).toEqual "b    = 2"
                expect(editor.lineTextForBufferRow 3).toEqual "c::3 = 4"

    describe "when matcher with left and right space prefix are mixed", ->
        it "should align correctly", ->
            editor.setText "a=1a     : 1\nb               = 2c::ab         :2"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a = 1a    : 1"
                expect(editor.lineTextForBufferRow 1).toEqual "b = 2c::ab: 2"

    describe "when there are some matcher to ignore", ->
        it "should align correctly", ->
            editor.setText "a = a   = b => c\na => a = b => c"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a      = a = b => c"
                expect(editor.lineTextForBufferRow 1).toEqual "a => a = b     => c"

    describe "when matcher is the first character on the line", ->
        it "should align correctly", ->
            editor.setText "a=a\n=c"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a = a"
                expect(editor.lineTextForBufferRow 1).toEqual "  = c"

    describe "when there is nothing to do", ->
        it "should keep the intendation and remove duplicate blanks", ->
            editor.setText "  a::a::b  a\nb::b::c"
            editor.selectAll()
            new Aligner(editor, leftAlignChars, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "  a::a::b a"
                expect(editor.lineTextForBufferRow 1).toEqual "b::b::c"

    describe "when there are multiple separators, but we only want to align the first one", ->
        it "should align the first one, but in any case remove duplicate blanks", ->
            editor.setText "a=1 b=2\na      =2 b       =1"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars, rightSpaceChars, matcher, ignoreChars).align(false)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a = 1 b=2"
                expect(editor.lineTextForBufferRow 1).toEqual "a = 2 b =1"

    leftSpaceChars2  = ['=', ':']
    rightSpaceChars2 = ['=', ':']
    matcher2         = [':', '=', '|']
    ignoreChars2     = ['===', '==', '!==', '!=']

    describe "run 2 when aligner is called on one line only", ->
        it "has to break the line", ->
            editor.setText "var a = 1; var b = 2;"
            editor.setCursorScreenPosition([1, 1])
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 1).toEqual "var b = 2;"

    describe "run 2 when aligner is called on multiple lines with only one matcher", ->
        it "should align correctly", ->
            editor.setText "var a = 1;\nvar bbb =    2;"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 1).toEqual "var bbb = 2;"

    describe "run 2 when aligner is called on multiple lines with different matchers", ->
        it "should align correctly", ->
            editor.setText "var a = 1; b:2; c:3;d=4\nvar bbb   : 2;"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 1).toEqual "var bbb      : 2;"

    describe "run 2 when aligner is called on lines with multiple char matchers", ->
        it "should align correctly", ->
            editor.setText "var a => 1; b = 2;\nvar bbb   => 2;"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 1).toEqual "var bbb = > 2;"

    describe "run 2 when aligner is called on lines with ignore chars", ->
        it "should align correctly", ->
            editor.setText "a==a::a:1\nbbb::bbb=ccc:1"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a==a : : a         : 1"

    describe "run 2 when there is everything put together (1)", ->
        it "should align correctly", ->
            editor.setText "a::a=b=c=>d\naaaaa=b=>a\nfffffffffff=ffffffff=>h"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a : : a     = b        = c = >d"
                expect(editor.lineTextForBufferRow 1).toEqual "aaaaa       = b        = >a"
                expect(editor.lineTextForBufferRow 2).toEqual "fffffffffff = ffffffff = >h"

    describe "run 2 when there is everything put together (2)", ->
        it "should align correctly", ->
            editor.setText "a=b=>c\naa=bb=>cc\nb=>c=a\nbb=>cc=aa"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a  = b   = >c"
                expect(editor.lineTextForBufferRow 1).toEqual "aa = bb  = >cc"
                expect(editor.lineTextForBufferRow 2).toEqual "b  = >c  = a"
                expect(editor.lineTextForBufferRow 3).toEqual "bb = >cc = aa"

    describe "run 2 when indentation is mixed with spaces and tabs", ->
        it "should align correctly", ->
            editor.setText "aa = 4\na	= 1\nb  = 2\nc::3=4"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "aa      = 4"
                expect(editor.lineTextForBufferRow(1).replace(/\t/g,"t")).toEqual "at      = 1" #specs cannot handle tabs  ... wtf?
                expect(editor.lineTextForBufferRow 2).toEqual "b       = 2"
                expect(editor.lineTextForBufferRow 3).toEqual "c : : 3 = 4"

    describe "run 2 when matcher with left and right space prefix are mixed", ->
        it "should align correctly", ->
            editor.setText "a=1a     : 1\nb               = 2c::ab         :2"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a = 1a : 1"
                expect(editor.lineTextForBufferRow 1).toEqual "b = 2c : : ab : 2"

    describe "run 2 when there are some matcher to ignore", ->
        it "should align correctly", ->
            editor.setText "a== = a   = b => c\na => ==a = b => c"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a== = a     = b = > c"
                expect(editor.lineTextForBufferRow 1).toEqual "a   = > ==a = b = > c"

    describe "when character | (pipe) should be aligned", ->
        it "should align correctly", ->
            editor.setText "a|1|a\naa|1|aa"
            editor.selectAll()
            new Aligner(editor, leftSpaceChars2, rightSpaceChars2, matcher2, ignoreChars2).align(true)
            align ->
                expect(editor.lineTextForBufferRow 0).toEqual "a |1|a"
