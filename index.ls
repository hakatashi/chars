require! {
  'xtend': extend
}

is-surrogate = -> 0xD800 <= it <= 0xDFFF
is-low-surrogate = -> 0xD800 <= it <= 0xDBFF
is-high-surrogate = -> 0xDC00 <= it <= 0xDFFF

module.exports = (string, options = {}) ->
  # Coerce given argument into string
  string = string.to-string! if typeof! string isnt \String

  default-options = {
    +surrogate-pair
    +ids
    +ivs
    +combining-mark
    +myanmar-vowel
    -detailed
  }

  options = extend {}, default-options, options

  result = []

  # Iterate pointer through string and process characters
  ptr = 0

  while ptr < string.length
    char = string[ptr]
    char-code = string.char-code-at ptr

    ### Surrogate Pairs ###

    if options.surrogate-pair

      if char-code |> is-low-surrogate
        # Read current buffer and push surrogate pair if possible

        # If string is terminating and no high surrogate can be seen
        if ptr + 1 >= string.length
          result.push {
            type: \surrogatePair
            char
            +broken
          }
          ptr++
          continue

        else
          next-char = string[ptr + 1]
          next-char-code = string.char-code-at ptr + 1

          # If next char is high surrogate, it is always valid surrogate pair
          if next-char-code |> is-high-surrogate
            result.push {
              type: \surrogatePair
              char: char + next-char
              -broken
            }
            ptr += 2
            continue

          else
            result.push {
              type: \surrogatePair
              char
              +broken
            }
            ptr++
            continue

      # If high surrogate is seen before low surrogate, it is invalid.
      if char-code |> is-high-surrogate
        result.push {
          type: \surrogatePair
          char
          +broken
        }
        ptr++
        continue

    ### Fallback ###

    # No special rule matched. Just push normal character.
    result.push {
      type: \normal
      char
      -broken
    }
    ptr++

  if options.detailed
    return result
  else
    # Convert to normal string array
    return result.map (.char)
