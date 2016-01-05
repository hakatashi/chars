require! {
  chai: {expect}
  '../': chars
}

It = global.it

var assets

run = (options) ->
  for asset in assets
    if options
      expect chars asset.0
      .to.deep.equal asset.1
    else
      expect chars asset.0, options
      .to.deep.equal asset.1

describe 'Basic Options' ->
  It 'basically works' ->
    assets :=
      * * ''
        * []
      * * \Alice
        * <[A l i c e]>
      * * \アリス
        * <[ア リ ス]>
      * * \أليس
        * <[أ ل ي س]>

    run!

  describe 'Surrogate Pairs' ->
    It 'can handle surrogate pairs as one characters' ->
      assets :=
        * * \𝟘𝟙𝟚𝟛
          * <[𝟘 𝟙 𝟚 𝟛]>
        * * \𠮷野家
          * <[𠮷 野 家]>

      run!
