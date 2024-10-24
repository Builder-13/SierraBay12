/// Transforms the speech emphasis mods from [/atom/movable/proc/say_emphasis] into the appropriate HTML tags. Includes escaping.
#define ENCODE_HTML_EMPHASIS(input, char, html, varname) \
	var/static/regex/##varname = regex("(?<!\\\\)[char](.+?)(?<!\\\\)[char]", "g");\
	input = varname.Replace_char(input, "<[html]>$1</[html]>")

/// Scans the input sentence for speech emphasis modifiers, notably `_italics_` and `+bold+`
/mob/proc/say_emphasis(input)
	ENCODE_HTML_EMPHASIS(input, "_", "i", italics)
	ENCODE_HTML_EMPHASIS(input, "\\+", "b", bold)
	var/static/regex/remove_escape_backlashes = regex("\\\\(_|\\+)", "g") // Removes backslashes used to escape text modification.
	input = remove_escape_backlashes.Replace_char(input, "$1")
	return input

#undef ENCODE_HTML_EMPHASIS

/mob/living/format_say_message(message)
	return say_emphasis(..())

/mob/format_emote(emoter, message)
	return say_emphasis(..())
