// Script -> BYOND code procs
#define SCRIPT_MAX_REPLACEMENTS_ALLOWED 200
// --- List operations (lists known as vectors in n_script) ---

// Clone of list()
/proc/n_list()
	var/list/returnlist = list()
	for(var/e in args)
		returnlist.Add(e)
	return returnlist

// Clone of pick()
/proc/n_pick()
	var/list/finalpick = list()
	for(var/e in args)
		if(isobject(e))
			if(istype(e, /list))
				var/list/sublist = e
				for(var/sube in sublist)
					finalpick.Add(sube)
				continue
		finalpick.Add(e)

	return pick(finalpick)

// Clone of list[]
/proc/n_listpos(list/L, pos, value)
	if(!istype(L, /list)) return
	if(isnum(pos))
		if(!value)
			if(LAZYLEN(L) >= pos)
				return L[pos]
		else
			if(LAZYLEN(L) >= pos)
				L[pos] = value
	else if(istext(pos))
		if(!value)
			return L[pos]
		else
			L[pos] = value

// Clone of list.Copy()
/proc/n_listcopy(list/L, start, end)
	if(!istype(L, /list)) return
	return L.Copy(start, end)

// Clone of list.Add()
/proc/n_listadd()
	var/list/chosenlist
	var/i = 1
	for(var/e in args)
		if(i == 1)
			if(isobject(e))
				if(istype(e, /list))
					chosenlist = e
			i = 2
		else
			if(chosenlist)
				chosenlist.Add(e)

// Clone of list.Remove()
/proc/n_listremove()
	var/list/chosenlist
	var/i = 1
	for(var/e in args)
		if(i == 1)
			if(isobject(e))
				if(istype(e, /list))
					chosenlist = e
			i = 2
		else
			if(chosenlist)
				chosenlist.Remove(e)

// Clone of list.Cut()
/proc/n_listcut(list/L, start, end)
	if(!istype(L, /list)) return
	return L.Cut(start, end)

// Clone of list.Swap()
/proc/n_listswap(list/L, firstindex, secondindex)
	if(!istype(L, /list)) return
	if(LAZYLEN(L) >= secondindex && LAZYLEN(L) >= firstindex)
		return L.Swap(firstindex, secondindex)

// Clone of list.Insert()
/proc/n_listinsert(list/L, index, element)
	if(!istype(L, /list)) return
	return L.Insert(index, element)

// --- Miscellaneous functions ---

// Clone of sleep()
/proc/delay(time)
	sleep(time)

// Clone of prob()
/proc/prob_chance(chance)
	return prob(chance)

// Merge of list_find() and findtext()
/proc/smartfind(haystack, needle, start = 1, end = 0)
	if(haystack && needle)
		if(isobject(haystack))
			if(istype(haystack, /list))
				if(length(haystack) >= end && start > 0)
					var/list/listhaystack = haystack
					return list_find(listhaystack, needle, start, end)

		else
			if(istext(haystack))
				if(length(haystack) >= end && start > 0)
					return findtext_char(haystack, needle, start, end)

// Clone of copytext()
/proc/docopytext(string, start = 1, end = 0)
	if(istext(string) && isnum(start) && isnum(end))
		if(start > 0)
			return copytext(string, start, end)

// Clone of length()
/proc/smartlength(container)
	if(container)
		if(istype(container, /list))
			return length(container)
		else
			if(istext(container))
				return length_char(container)

// BY DONKIE~
// String stuff
/proc/n_lower(string)
	if(istext(string))
		return lowertext(string)

/proc/n_upper(string)
	if(istext(string))
		return uppertext(string)

/*
//Makes a list where all indicies in a string is a seperate index in the list
// JUST A HELPER DON'T ADD TO NTSCRIPT
/proc/string_tolist(string)
	var/list/L = list()

	var/i
	for(i=1, i<=length(string), i++)
		L.Add(copytext(string, i, i))

	return L

/proc/string_explode(string, separator)
	if(istext(string))
		if(istext(separator) && separator == "")
			return string_tolist(string)
		var/i
		var/lasti = 1
		var/list/L = list()

		for(i=1, i<=length(string)+1, i++)
			if(copytext(string, i, i+1) == separator) // We found a separator
				L.Add(copytext(string, lasti, i))
				lasti = i+1

		L.Add(copytext(string, lasti, length(string)+1)) // Adds the last segment

		return L

Just found out there was already a string explode function, did some benchmarking, and that function were a bit faster, sticking to that.
*/
/proc/string_explode(string, separator)
	if(istext(string) && istext(separator))
		return splittext(string, separator)

/proc/n_repeat(string, amount)
	if(istext(string) && isnum(amount))
		var/i
		var/newstring = ""
		if(length(newstring)*amount >=1000)
			return
		for(i=0, i<=amount, i++)
			if(i>=1000)
				break
			newstring = newstring + string

		return newstring

/proc/n_reverse(string)
	if(istext(string))
		var/newstring = ""
		var/i
		for(i=length(string), i>0, i--)
			if(i>=1000)
				break
			newstring = newstring + copytext(string, i, i+1)

		return newstring

// I don't know if it's neccesary to make my own proc, but I think I have to to be able to check for istext.
/proc/n_str2num(string)
	if(istext(string))
		return text2num(string)

// Number shit
/proc/n_num2str(num)
	if(isnum(num))
		return num2text(num)

// Squareroot
/proc/n_sqrt(num)
	if(isnum(num))
		return sqrt(num)

// Magnitude of num
/proc/n_abs(num)
	if(isnum(num))
		return abs(num)

// Round down
/proc/n_floor(num)
	if(isnum(num))
		return round(num)

// Round up
/proc/n_ceil(num)
	if(isnum(num))
		return round(num)+1

// Round to nearest integer
/proc/n_round(num)
	if(isnum(num))
		if(num-round(num)<0.5)
			return round(num)
		return n_ceil(num)

// Clamps N between min and max
/proc/n_clamp(num, min=-1, max=1)
	if(isnum(num)&&isnum(min)&&isnum(max))
		if(num<=min)
			return min
		if(num>=max)
			return max
		return num

// Returns 1 if N is inbetween Min and Max
/proc/n_inrange(num, min=-1, max=1)
	if(isnum(num)&&isnum(min)&&isnum(max))
		return ((min <= num) && (num <= max))
// END OF BY DONKIE :(

// Non-recursive
// Imported from Mono string.ReplaceUnchecked
/proc/string_replacetext(haystack, a, b)
	if(istext(haystack)&&istext(a)&&istext(b))
		var/i = 1
		var/lenh=length_char(haystack)
		var/lena=length_char(a)
		//var/lenb=length(b)
		var/count = 0
		var/list/dat = list()
		while (i < lenh)
			var/found = findtext_char(haystack, a, i, 0)
			//log_misc("findtext([haystack], [a], [i], 0)=[found]")
			if (found == 0) // Not found
				break
			else
				if (count < SCRIPT_MAX_REPLACEMENTS_ALLOWED)
					dat+=found
					count+=1
				else
					//log_misc("Script found [a] [count] times, aborted")
					break
			//log_misc("Found [a] at [found]! Moving up...")
			i = found + lena
		if (count == 0)
			return haystack
		//var/nlen = lenh + ((lenb - lena) * count)
		var/buf = copytext_char(haystack,1,dat[1]) // Prefill
		var/lastReadPos = 0
		for (i = 1, i <= count, i++)
			var/precopy = dat[i] - lastReadPos-1
			//internal static unsafe void CharCopy (String target, int targetIndex, String source, int sourceIndex, int count)
			//fixed (char* dest = target, src = source)
			//CharCopy (dest + targetIndex, src + sourceIndex, count);
			//CharCopy (dest + curPos, source + lastReadPos, precopy);
			buf+=copytext_char(haystack,lastReadPos,precopy)
			log_misc("buf+=copytext([haystack],[lastReadPos],[precopy])")
			log_misc("[buf]")
			lastReadPos = dat[i] + lena
			//CharCopy (dest + curPos, replace, newValue.length);
			buf+=b
			log_misc("[buf]")
		buf+=copytext_char(haystack,lastReadPos, 0)
		return buf
