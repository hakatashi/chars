require! {
  chai: {expect}
  './': chars
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

describe 'Basic Usage' ->
  It 'basically works' ->
    assets :=
      * * \Alice
        * <[A l i c e]>
      * * \アリス
        * <[ア リ ス]>
      * * \أليس
        * <[أ ل ي س]>

    run!
