require! {
  'xtend': extend
  'core-js/library/fn/array/from': array-from
  'core-js/library/fn/string/code-point-at'
  'general-category'
}

is-surrogate = -> 0xD800 <= it <= 0xDFFF
is-low-surrogate = -> 0xD800 <= it <= 0xDBFF
is-high-surrogate = -> 0xDC00 <= it <= 0xDFFF

class Splitter
  default-options = {
    +ids
    +combining-mark
    +myanmar-vowel
    -detailed
  }

  (string, options) ->
    @options = extend {}, default-options, options

    # Coerce given argument into string
    @string =
      if typeof! string is \String
        string
      else
        string.to-string!

  split: ->
    @chars = array-from @string

    @tokens = []
    @ptr = 0

    # Iterate pointer through string and process characters
    while @ptr < @chars.length
      @char = @chars[@ptr]
      @char-code = @char |> code-point-at

      if @ptr + 1 >= @chars.length
        @next-char = null
        @next-char-code = null
      else
        @next-char = @chars[@ptr + 1]
        @next-char-code = @next-char |> code-point-at

      # Fallback
      # No special rule matched. Just push normal character.
      @push-token {
        type: null
        char: @char
        -broken
      }
      @ptr++

  # Push token to tokens slot acording with current options
  push-token: (token) ->
    if @options.detailed
      if token.type
        token.type = [token.type]
      else
        token.type = []

      @tokens.push token
    else
      @tokens.push token.char

  # Append modifier to the last pushed token.
  # If no recent pushed token exists, it will create broken modifier token
  append-modifier: (modifier) ->

module.exports = (string, options = {}) ->
  splitter = new Splitter ...
  splitter.split!
  splitter.tokens
