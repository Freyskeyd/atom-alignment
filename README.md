# atom-alignment package

[Atom package](https://atom.io/packages/atom-alignment)

> Inspired by sublime text plugin ([sublime_alignment](https://github.com/wbond/sublime_alignment))

## Usage

A simple key-binding for aligning multi-line, multi-cursor and multiple selections in Atom.

Use `ctrl+cmd+a` on Mac or `ctrl+alt+a` to align all matches



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

With more than one selection

```javascript
var a = b;    /* selection 1 */
var ab = c;   /*             */
var notMePlease='NOOOO';
var abcd = d; /* selection 2 */
var ddddd =d; /*             */
```

```javascript
var a     = b;
var ab    = c;
var notMePlease='NOOOO';
var abcd  = d;
var ddddd = d;
```

On a single line started with `ctrl+cmd+a`

```javascript
var a = b var cde =   d
```

```javascript
var a = b
var cde = d
```

When working with multiple cursors, the different lines are aligned at the best matching cursor position.

You can even align multiple matches

```javascript
lets = see = what => happens
a  = a  = b = c : d => e
```

```javascript
lets = see = what      => happens
a    = a   = b = c : d => e
```

## License

MIT © [Andre Lerche](https://github.com/papermoon1978)

MIT © [Simon Paitrault](http://www.freyskeyd.fr)
