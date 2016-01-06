require! {
  'xtend': extend
}

is-surrogate = -> 0xD800 <= it <= 0xDFFF
is-low-surrogate = -> 0xD800 <= it <= 0xDBFF
is-high-surrogate = -> 0xDC00 <= it <= 0xDFFF

class Splitter
  default-options = {
    +surrogate-pair
    +ids
    +ivs
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
    @tokens = []
    @ptr = 0

    # Iterate pointer through string and process characters
    while @ptr < @string.length
      @char = @string[@ptr]
      @char-code = @string.char-code-at @ptr

      if @ptr + 1 >= @string.length
        @next-char = null
        @next-char-code = null
      else
        @next-char = @string[@ptr + 1]
        @next-char-code = @string.char-code-at @ptr + 1

      # Surrogate Pair
      if @options.surrogate-pair
        read-char = @read-surrogate-pair!
        continue if read-char

      # Fallback
      # No special rule matched. Just push normal character.
      @push-token {
        type: \normal
        char: @char
        -broken
      }
      @ptr++

  # Push token to tokens slot acording with current options
  push-token: (token) ->
    if @options.detailed
      @tokens.push token
    else
      @tokens.push token.char

  # Surrogate Pairs
  read-surrogate-pair: ->
    if @char-code |> is-low-surrogate
      # Read current buffer and push surrogate pair if possible

      # If string is terminating and no high surrogate can be seen
      unless @next-char
        @push-token {
          type: \surrogatePair
          char: @char
          +broken
        }
        @ptr++
        return true

      else
        # If next char is high surrogate, it is always valid surrogate pair
        if @next-char-code |> is-high-surrogate
          @push-token {
            type: \surrogatePair
            char: @char + @next-char
            -broken
          }
          @ptr += 2
          return true

        else
          @push-token {
            type: \surrogatePair
            char: @char
            +broken
          }
          @ptr++
          return true

    # If high surrogate is seen before low surrogate, it is invalid.
    if @char-code |> is-high-surrogate
      @push-token {
        type: \surrogatePair
        char: @char
        +broken
      }
      @ptr++
      return true

    return false

module.exports = (string, options = {}) ->
  splitter = new Splitter ...
  splitter.split!
  splitter.tokens
