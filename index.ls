require! {
  'xtend': extend
  'array-unique'
  'core-js/library/fn/array/from': array-from
  'core-js/library/fn/string/code-point-at'
  'general-category/latest': general-category
}

class Splitter
  default-options = {
    +ids
    +combining-mark
    +kharoshthi-virama
    +flag-sequence
    -detailed
  }

  ids-number-of-arguments = {
    '⿰': 2
    '⿱': 2
    '⿲': 3
    '⿳': 3
    '⿴': 2
    '⿵': 2
    '⿶': 2
    '⿷': 2
    '⿸': 2
    '⿹': 2
    '⿺': 2
    '⿻': 2
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

      if @options.kharoshthi-virama
        result = @read-kharoshthi-virama!
        continue if result is true

      if @options.combining-mark
        result = @read-combining-mark!
        continue if result is true

      if @options.ids
        result = @read-ids!
        continue if result is true

      if @options.flag-sequence
        result = @read-flag-sequence!
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
    # Emoji_Modifiers are not categorized as a “mark," but considered as a modifier.
    if category[0] is \M or 0x1F3FB <= @char-code <= 0x1F3FF
      @append-modifier {
        type: \combiningMark
        char: @char
        -broken
      }
      @ptr++
      return true

    return false

  read-ids: ->
    return false unless 0x2FF0 <= @char-code <= 0x2FFB

    result = @read-partial-ids @ptr

    ids = @chars[@ptr til result.ptr].join ''

    @push-token {
      type: \ids
      char: ids
      result.broken
    }
    @ptr = result.ptr

    return true

  # Recieve starting point of ids token and returns the object with following structure
  #   ptr: ending point + 1 of that token
  #   broken: boolean whether reading token is broken (= incomplete)
  read-partial-ids: (ptr) ->
    if ptr >= @chars.length
      return {
        ptr: @chars.length
        +broken
      }

    char = @chars[ptr]
    argument-length = ids-number-of-arguments[char]

    # Just a character, not composed one
    if argument-length is undefined
      return {
        ptr: ptr + 1
        -broken
      }

    else
      # Skip current pointer once to read through IDC
      current-ptr = ptr + 1
      broken = false

      for i in [0 til argument-length]
        result = @read-partial-ids current-ptr
        current-ptr = result.ptr

        if result.broken
          broken = true
          break

      return {
        ptr: current-ptr
        broken
      }

  # Read Kharoshthi Virama and trigger combination of Kharoshthi characters.
  # The rules for combination is documented in Unicode Standard 8.0.0 §14.4 and
  # the corresponding proposals for adding Kharoshthi characters, L2/02-203 R2.
  # In short, the rule for Kharoshthi Virama is described in the following quotation
  # from Unicode Standard 8.0.0:
  #     When not followed by a consonant, the virama causes the preceding consonant
  #     to be written as subscript to the left of the letter preceding it. If followed by another consonant,
  #     the virama will trigger a combined form consisting of two or more consonants.
  read-kharoshthi-virama: ->
    return false unless @char-code is 0x10A3F

    # Code points for Kharoshthi Consonants are U+10A10 to U+10A33, which contains
    # two unassigned code points for now in Unicode 8.0.0. They are reserved for future versions
    # of Unicode and should be treated as true Kharoshthi Consonants here.
    if @next-char isnt null and 0x10A10 <= @next-char-code <= 0x10A33
      @append-modifier {
        type: \kharoshthiVirama
        char: @char + @next-char
        -broken
      }
      @ptr += 2
      return true

    else
      @append-modifier {
        type: \kharoshthiVirama
        char: @char
        -broken
      }

      @combine-with-preceding-char!

      @ptr++
      return true

  # Read Regional Indicator Symbol and pushes a paired character sequence if it makes
  # a valid emoji flag sequence.
  # ED-14 of UTR 51 UNICODE EMOJI defines which character sequence may be treated as
  # a valid emoji flag sequence, and it's just a paired combiunation of Regional Indicator Symbols.
  # http://www.unicode.org/reports/tr51/#def_emoji_flag_sequence
  read-flag-sequence: (ptr) ->
    return false unless 0x1F1E6 <= @char-code <= 0x1F1FF

    if 0x1F1E6 <= @next-char-code <= 0x1F1FF
      @push-token {
        type: \flagSequence
        char: @char + @next-char
        -broken
      }

      @ptr += 2
      return true

    else
      @push-token {
        type: \flagSequence
        char: @char
        +broken
      }

      @ptr++
      return true

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

  # Combine the current top-on-the-stack character with the preceding character.
  combine-with-preceding-char: ->
    return if @tokens.length < 2

    unless @options.detailed
      @tokens[* - 2] += @tokens.pop!

    else
      last-token = @tokens.pop!

      @tokens[* - 2]
        ..type ++= last-token.type
        ..type = array-unique @tokens[* - 2]

        ..char += last-token.char

        ..broken ||= last-token.broken

module.exports = (string, options = {}) ->
  splitter = new Splitter ...
  splitter.split!
  splitter.tokens
