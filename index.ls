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

      if @options.combining-mark
        result = @read-combining-mark!
        continue if result is true

      # Fallback
      # No special rule matched. Just push normal character.
      @push-token {
        type: null
        char: @char
        -broken
      }
      @ptr++

  # Read combining marks and append to current token buffer
  read-combining-mark: ->
    category = general-category @char-code

    # First character of category indicates large category of character.
    if category[0] is \M
      @append-modifier {
        type: \combiningMark
        char: @char
        -broken
      }
      @ptr++
      return true

    return false

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
    unless @options.detailed
      if @tokens.length is 0
        @tokens.push modifier.char
      else
        @tokens[* - 1] += modifier.char

    else
      if @tokens.length is 0
        @tokens.push {
          type: [modifier.type]
          modifier.char
          +broken
        }
      else
        last-token = @tokens[* - 1]

        # Append token.type unless already appended
        if last-token.type.index-of modifier.type is -1
          last-token.type.push modifier.type

        last-token.char += modifier.char
        last-token.broken ||= modifier.broken

module.exports = (string, options = {}) ->
  splitter = new Splitter ...
  splitter.split!
  splitter.tokens
