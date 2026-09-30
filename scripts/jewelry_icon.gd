extends RefCounted
# Small native inventory symbols; character art remains painted full-body sprites.
static func make_icon(slot: int) -> Texture2D:
	var gem := "#72c9ef" if slot==4 else ("#d6b0ee" if slot==5 else "#75dbc6")
	var form := '<ellipse cx="24" cy="29" rx="12" ry="14" fill="none" stroke="#e1bd73" stroke-width="5"/><path d="M15 14 L24 6 L33 14 L24 24 Z" fill="%s" stroke="#ffe3a1" stroke-width="2"/>' % gem
	if slot==6:
		form = '<path d="M8 5 Q9 23 24 27 Q39 23 40 5" fill="none" stroke="#e1bd73" stroke-width="2"/><path d="M24 21 L36 32 L24 45 L12 32 Z" fill="%s" stroke="#ffe3a1" stroke-width="3"/>' % gem
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">%s</svg>' % form
	var image := Image.new()
	image.load_svg_from_string(svg)
	return ImageTexture.create_from_image(image)
