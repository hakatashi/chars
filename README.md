# chars

[![Greenkeeper badge](https://badges.greenkeeper.io/hakatashi/chars.svg)](https://greenkeeper.io/)

[![Build Status](https://travis-ci.org/hakatashi/chars.svg)](https://travis-ci.org/hakatashi/chars)

Split strings into array of characters by “Semmantically-correct” way.

This module is inspired by [esrever](https://www.npmjs.com/package/esrever).

## Why not just use `string.split('')`!?!?!?!?

Well, [esrever's README](https://github.com/mathiasbynens/esrever#why-not-just-use-stringsplitreversejoin)
sufficiently explains why, but I can simply answer that
**the chars of JavaScript is not just the chars of Unicode.**

In Unicode, a pair of surrogates constitutes (In other word, “expresses”) one character by itself.
In JavaScript, thanks to [its UCS-2-like behavior,](https://mathiasbynens.be/notes/javascript-encoding)
the pair is treated as two characters.

```js
> '𝟙𝟚𝟛'.split('')
[ '�', '�', '�', '�', '�', '�' ]
```

And what is worse, if you reverse strings by famous `.split('').reverse().join('')` trick,
you may even get wrong character by joining partial surrogate pairs.

```js
> '𝟙𝟚𝟛'.split('').reverse().join('')
'�𝟚𝟙�' // Huh?
```

OK, now “chars” is here for you. Instead of using `string.split('')`,
you can gracefully use `chars(string)` at ease.

```js
> chars('𝟙𝟚𝟛').reverse().join('')
'𝟛𝟚𝟙' // Gotcha!
```

“chars” recognizes **surrogate pairs** and **other Unicode mechanisms**
to split strings into array of characters. Be like a boss, y'all!

### But sorry!

If you just want something to recognize *only* surrogate pairs to
split strings into array of characters,
**you already have it** as an ES6 feature.

```js
> Array.from('𝟙𝟚𝟛').reverse().join('')
'𝟛𝟚𝟙'
```

## Usage

    $ npm i chars

```js
const chars = require('chars');

chars('cafe\u0301'); // -> ['c', 'a', 'f', 'e\u0301']

// All features are on by default.
// You can switch off some specific features by option.
chars('cafe\u0301', {combiningMark: false}); // -> ['c', 'a', 'f', 'e', '\u0301']

// You can also get detailed information about each character.
chars('cafe\u0301', {detailed: true});
/* -> [ { type: [], char: 'c', broken: false },
        { type: [], char: 'a', broken: false },
        { type: [], char: 'f', broken: false },
        { type: [ 'combiningMark' ], char: 'é', broken: false } ] */
```

## Mechanisms

Currently this module recognizes the following mechanisms of Unicode.

* [Surrogate Pairs](#surrogate-pairs)
* [Combining Marks](#combining-marks)
* [IDS](#ids-ideographic-description-sequences)
* [Kharoshthi Virama](#kharoshthi-virama)
* [Regional Indicator Symbols](#regional-indicator-symbols)

Upcoming:

* Zero-Width Joiner
* Prepended Concatenation Marks
* Emoji Sequence
* Adeg Adeg
* Generic virama such as Devanagari (Hard way...!)
* Bugenese Ligature (Includes “iya” only)

### Surrogate Pairs

Read the section [above](#why-not-just-use-stringsplit).

Parsing surrogate pairs is basic functionality of this module and
you cannnot turn this feature off by option.
If you don't need even this feature, use `string.split('')`.

### Combining Marks

Some Unicode characters works as “modifier” and append additional parts
to the preceding character. These characters should be semantically
interpreted as one combined character.

These characters contain:

* [Diacritics](https://en.wikipedia.org/wiki/Diacritic)

* [Variation Selectors](https://en.wikipedia.org/wiki/Variation_Selectors_(Unicode_block))

    Especialy as...

    * Emoji Variation Selectors
    * [Ideographic Variation Selectors](http://unicode.org/reports/tr37/)

* [Emoji Keycaps](http://www.fileformat.info/info/unicode/char/20e3/index.htm)

Example:

```js
> chars('dépôt')
[ 'd', 'é', 'p', 'ô', 't' ]
```

You can turn this feature off by `{combiningMark: false}`.

### IDS (Ideographic Description Sequences)

Ideographs used in east asia are very complex and mostly they can be described by
composition of another ideographs.

Unicode supports description of these composition by special meta-characters,
which is called “IDC (Ideographic Description Characters).”
They constitute some character sequences by simple algorithm and
express single character whose parts are represented by another character.

Semantically they are one “character” with a bunch of portion.
[Unicode Standard 8.0.0 describes](http://www.unicode.org/versions/Unicode8.0.0/ch18.pdf)
how these sequences should be interpreted programatically.

> Ideographic Description characters are not combining characters,
and there is no requirement that they affect character or word boundaries. Thus U+2FF1
U+4E95 U+86D9 may be treated as a sequence of three characters or even three words.
>
> Implementations of the Unicode Standard may choose to parse Ideographic Description
Sequences when calculating word and character boundaries. Note that such a decision will
make the algorithms involved significantly more complicated and slower.

Then, this module _choosed_ to parse IDS as character.

Example:

```js
> chars('⿱女⿰女女しい')
[ '⿱女⿰女女', 'し', 'い' ]
```

You can turn this feature off by `{ids: false}`

### Kharoshthi Virama

Kharoshthi (aka Kharosthi) is an ancient script used in ancient India ([Wikipedia](https://en.wikipedia.org/wiki/Kharosthi)).
In this script, we have to handle a strange modifier called “Kharoshthi Virama.”
It behaves like ZWJ when the both side of the Virama is Kharoshthi consonants, and otherwise
it modifies preceding character to be a modifier, and makes it to be written in the bottom-left
of the character preceding it.
It means, this character may affect the preceding character but one!

```js
> chars('𐨫𐨿𐨤𐨑𐨿𐨐𐨿𐨮𐨨𐨿𐨪𐨢𐨁𐨐𐨿')
[ '𐨫𐨿𐨤', '𐨑𐨿𐨐𐨿𐨮', '𐨨𐨿𐨪', '𐨢𐨁𐨐𐨿' ]
```

Note: If you have problem for reading this script,
just install [Noto Sans Kharoshthi](https://www.google.com/get/noto/#sans-khar) font.

You can turn this feature off by `{kharoshthiVirama: false}`

#### Further readings

* [Unicode Standard 8.0.0 §14 South and Central Asia-III](http://www.unicode.org/versions/Unicode8.0.0/ch14.pdf#page=11)
* [Proposal for adding Kharoshthi characters in Unicode Standard](http://www.unicode.org/L2/L2002/02203r2-kharoshthi.pdf#page=9)

## Regional Indicator Symbols

Regional Indicator Symbols is a part of the emoji symbol specification,
which is to encode a country by the combination of two-letter country codes.
Every succeeding pairs of the Regional Indicator Symbols should be considered as
the existing country code and therefore be one character.

```js
> chars('FREEDOM🇺🇸')
[ 'F', 'R', 'E', 'E', 'D', 'O', 'M', '🇺🇸' ]
```
