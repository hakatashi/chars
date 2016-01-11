require! {
  chai: {expect}
  '../': chars
}

It = global.it

var assets

run = (options) ->
  for asset in assets
    if options
      expect chars asset.0, options
      .to.deep.equal asset.1
    else
      expect chars asset.0
      .to.deep.equal asset.1

describe 'Basic Options' ->
  It 'basically works' ->
    assets :=
      * ''
        []
      * \Alice
        <[A l i c e]>
      * \アリス
        <[ア リ ス]>
      * \أليس
        <[أ ل ي س]>

    run!

  describe 'Surrogate Pairs' ->
    It 'handles surrogate pairs as one characters' ->
      assets :=
        * \𝟘𝟙𝟚𝟛
          <[𝟘 𝟙 𝟚 𝟛]>
        * \𠮷野家
          <[𠮷 野 家]>

      run!

    It 'handles unpaired surrogate pairs as separated characters' ->
      assets :=
        # high-only
        * 'foo\uDA3Cbar'
          <[f o o \uDA3C b a r]>
        # low-only
        * 'foo\uDDC0bar'
          <[f o o \uDDC0 b a r]>
        # low and high
        * 'foo\uDDC0\uDA3Cbar'
          <[f o o \uDDC0 \uDA3C b a r]>
        # succession of high surrogate
        * 'foo\uDA3C\uD842\uDFB7bar'
          <[f o o \uDA3C \uD842\uDFB7 b a r]>
        # succession of low surrogate
        * 'foo\uD842\uDFB7\uDDC0bar'
          <[f o o \uD842\uDFB7 \uDDC0 b a r]>
        # string terminating with high surrogate
        * 'foo\uDA3C'
          <[f o o \uDA3C]>

      run!

  describe 'Combining Marks' ->
    It 'handles basic combining marks as appended character' ->
      assets :=
        * 'cafe\u0301'
          <[c a f e\u0301]>
        * 'de\u0301po\u0302t'
          <[d e\u0301 p o\u0302 t]>

      run!

describe '`detailed Option`' ->
  It 'returns detailed token array instead of plain text' ->
    assets :=
      * ''
        []
      * \アリス
        [
        * type: []
          char: \ア
          broken: false
        * type: []
          char: \リ
          broken: false
        * type: []
          char: \ス
          broken: false
        ]
      * \𠮷野家
        [
        * type: []
          char: \𠮷
          broken: false
        * type: []
          char: \野
          broken: false
        * type: []
          char: \家
          broken: false
        ]

    run {+detailed}
