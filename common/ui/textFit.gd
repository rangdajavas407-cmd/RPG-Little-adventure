extends RefCounted

# Membuat teks muat dalam lebar tertentu: huruf diperkecil sampai batas, lalu dipotong dengan titik.
# Dipakai untuk nama panjang (item, musuh, pembicara) agar tidak keluar dari kotak / layar.

static func fit(label_, text_, maxWidth_, minSize_=5):
	var text=str(text_)
	label_.remove_theme_font_size_override("font_size")
	var font=label_.get_theme_font("font")
	var size=label_.get_theme_font_size("font_size")
	var startSize=size
	while size>minSize_ and font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>maxWidth_:
		size-=1
	var shown=text
	while shown.length()>3 and font.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>maxWidth_:
		shown=shown.substr(0,shown.length()-2)
	if shown!=text:
		shown=shown.rstrip(" (")+"."
	if size!=startSize:
		label_.add_theme_font_size_override("font_size",size)
	label_.text=shown
	label_.tooltip_text=text
