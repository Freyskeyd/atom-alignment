# atom-alignment package

[Atom package](https://atom.io/packages/atom-alignment)

> Inspired by sublime text plugin ([sublime_alignment](https://github.com/wbond/sublime_alignment))


## Usage

A simple key-binding for aligning multi-line, multi-cursor and multiple selections in Atom.

Use `ctrl+cmd+a` on Mac or `ctrl+alt+a` on Linux or Windows to align the first match only or `ctrl+shift+a` to align all matches



```javascript
var a = b;
var ab = c;
var abcd = d;
var ddddd =d;
```

```javascript
var a     = b;
var ab    = c;
var abcd  = d;
var ddddd = d;
```

On multiple range line

```javascript
var a = b;
var ab = c;
var notMePlease='NOOOO';
var abcd = d;
var ddddd =d;
```

```javascript
var a     = b;
var ab    = c;
var notMePlease='NOOOO';
var abcd  = d;
var ddddd = d;
```

On a single line started with `ctrl+shift+a`

```
var a = b var cde =   d
```

```
var a = b
var cde = d
```
On a single line started with `ctrl+cmd+a` only doubled space characters are removed

When working with multiple cursors, the different lines are aligned at the best matching cursor position.

## License

MIT © [Andre Lerche](https://github.com/papermoon1978)

MIT © [Simon Paitrault](http://www.freyskeyd.fr)
