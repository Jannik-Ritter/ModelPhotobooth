local postProcess = {}

function postProcess.applyOutline(buf: buffer, w: number, h: number, color: Color3, thickness: number): buffer
	local cr = math.floor(color.R * 255 + 0.5)
	local cg = math.floor(color.G * 255 + 0.5)
	local cb = math.floor(color.B * 255 + 0.5)
	for _ = 1, thickness do
		local nxt = buffer.create(w * h * 4)
		buffer.copy(nxt, 0, buf, 0, w * h * 4)
		for y = 0, h - 1 do
			for x = 0, w - 1 do
				local o = (y * w + x) * 4
				if buffer.readu8(buf, o + 3) < 128 then
					local hit = false
					for dy = -1, 1 do
						for dx = -1, 1 do
							if (dx ~= 0 or dy ~= 0) and not hit then
								local nx, ny = x + dx, y + dy
								if nx >= 0 and nx < w and ny >= 0 and ny < h and buffer.readu8(buf, (ny * w + nx) * 4 + 3) >= 128 then
									hit = true
								end
							end
						end
					end
					if hit then
						buffer.writeu8(nxt, o, cr)
						buffer.writeu8(nxt, o + 1, cg)
						buffer.writeu8(nxt, o + 2, cb)
						buffer.writeu8(nxt, o + 3, 255)
					end
				end
			end
		end
		buf = nxt
	end
	return buf
end

function postProcess.blurAlphaFlat(src: buffer, w: number, h: number, radius: number): buffer
	local tmp = buffer.create(w * h)
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local s, n = 0, 0
			for k = math.max(0, x - radius), math.min(w - 1, x + radius) do
				s += buffer.readu8(src, y * w + k)
				n += 1
			end
			buffer.writeu8(tmp, y * w + x, math.floor(s / n))
		end
	end
	local out = buffer.create(w * h)
	for x = 0, w - 1 do
		for y = 0, h - 1 do
			local s, n = 0, 0
			for k = math.max(0, y - radius), math.min(h - 1, y + radius) do
				s += buffer.readu8(tmp, k * w + x)
				n += 1
			end
			buffer.writeu8(out, y * w + x, math.floor(s / n))
		end
	end
	return out
end

function postProcess.applyDropShadow(
	buf: buffer,
	w: number,
	h: number,
	color: Color3,
	opacity: number,
	dist: number,
	blur: number,
	angle: number?
): buffer
	local cr = color.R
	local cg = color.G
	local cb = color.B
	local opF = opacity / 100
	local rad = math.rad(angle or 45)
	local offX = math.round(dist * math.cos(rad))
	local offY = math.round(dist * math.sin(rad))
	local sAlpha = buffer.create(w * h)
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local sx, sy = x - offX, y - offY
			if sx >= 0 and sx < w and sy >= 0 and sy < h then
				buffer.writeu8(sAlpha, y * w + x, buffer.readu8(buf, (sy * w + sx) * 4 + 3))
			end
		end
	end
	if blur > 0 then
		sAlpha = postProcess.blurAlphaFlat(sAlpha, w, h, math.max(1, blur))
	end
	local out = buffer.create(w * h * 4)
	for i = 0, w * h - 1 do
		local o = i * 4
		local sa = math.floor(buffer.readu8(sAlpha, i) * opF + 0.5)
		local oa = buffer.readu8(buf, o + 3)
		local or_ = buffer.readu8(buf, o)
		local og = buffer.readu8(buf, o + 1)
		local ob = buffer.readu8(buf, o + 2)
		if oa >= 255 then
			buffer.writeu8(out, o, or_)
			buffer.writeu8(out, o + 1, og)
			buffer.writeu8(out, o + 2, ob)
			buffer.writeu8(out, o + 3, 255)
		elseif sa == 0 then
			buffer.writeu8(out, o, or_)
			buffer.writeu8(out, o + 1, og)
			buffer.writeu8(out, o + 2, ob)
			buffer.writeu8(out, o + 3, oa)
		else
			local oaf = oa / 255
			local saf = sa / 255
			local finaf = oaf + saf * (1 - oaf)
			local fina = math.floor(finaf * 255 + 0.5)
			local finr, fing, finb
			if finaf > 0 then
				finr = math.floor(math.clamp((or_ / 255 * oaf + cr * saf * (1 - oaf)) / finaf * 255, 0, 255) + 0.5)
				fing = math.floor(math.clamp((og / 255 * oaf + cg * saf * (1 - oaf)) / finaf * 255, 0, 255) + 0.5)
				finb = math.floor(math.clamp((ob / 255 * oaf + cb * saf * (1 - oaf)) / finaf * 255, 0, 255) + 0.5)
			else
				finr, fing, finb = 0, 0, 0
			end
			buffer.writeu8(out, o, finr)
			buffer.writeu8(out, o + 1, fing)
			buffer.writeu8(out, o + 2, finb)
			buffer.writeu8(out, o + 3, fina)
		end
	end
	return out
end

function postProcess.applyInnerShadow(buf: buffer, w: number, h: number, color: Color3, opacity: number, dist: number, blur: number, angle: number): buffer
	local cr = color.R
	local cg = color.G
	local cb = color.B
	local opF = opacity / 100
	local rad = math.rad(angle or 225)
	local offX = math.round(dist * math.cos(rad))
	local offY = math.round(dist * math.sin(rad))
	local shifted = buffer.create(w * h)
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local sx, sy = x + offX, y + offY
			local srcA = 0
			if sx >= 0 and sx < w and sy >= 0 and sy < h then
				srcA = buffer.readu8(buf, (sy * w + sx) * 4 + 3)
			end
			buffer.writeu8(shifted, y * w + x, 255 - srcA)
		end
	end
	if blur > 0 then
		shifted = postProcess.blurAlphaFlat(shifted, w, h, math.max(1, blur))
	end
	local out = buffer.create(w * h * 4)
	buffer.copy(out, 0, buf, 0, w * h * 4)
	for i = 0, w * h - 1 do
		local o = i * 4
		local origA = buffer.readu8(buf, o + 3)
		if origA > 0 then
			local effA = math.floor(buffer.readu8(shifted, i) * origA / 255 * opF + 0.5)
			if effA > 0 then
				local saf = effA / 255
				buffer.writeu8(out, o, math.floor(math.clamp(cr * 255 * saf + buffer.readu8(out, o) * (1 - saf), 0, 255) + 0.5))
				buffer.writeu8(out, o + 1, math.floor(math.clamp(cg * 255 * saf + buffer.readu8(out, o + 1) * (1 - saf), 0, 255) + 0.5))
				buffer.writeu8(out, o + 2, math.floor(math.clamp(cb * 255 * saf + buffer.readu8(out, o + 2) * (1 - saf), 0, 255) + 0.5))
			end
		end
	end
	return out
end

-- Outer glow: blur the model's alpha outward and composite the glow color beneath the original.
function postProcess.applyOuterGlow(
	buf: buffer,
	w: number,
	h: number,
	color: Color3,
	opacity: number,
	blur: number
): buffer
	local cr = color.R
	local cg = color.G
	local cb = color.B
	local opF = opacity / 100

	local glowAlpha = buffer.create(w * h)
	for i = 0, w * h - 1 do
		buffer.writeu8(glowAlpha, i, buffer.readu8(buf, i * 4 + 3))
	end
	if blur > 0 then
		glowAlpha = postProcess.blurAlphaFlat(glowAlpha, w, h, math.max(1, blur))
	end

	local out = buffer.create(w * h * 4)
	for i = 0, w * h - 1 do
		local o = i * 4
		local ga = math.floor(buffer.readu8(glowAlpha, i) * opF + 0.5)
		local oa = buffer.readu8(buf, o + 3)
		local or_ = buffer.readu8(buf, o)
		local og = buffer.readu8(buf, o + 1)
		local ob = buffer.readu8(buf, o + 2)
		if oa >= 255 then
			buffer.writeu8(out, o, or_)
			buffer.writeu8(out, o + 1, og)
			buffer.writeu8(out, o + 2, ob)
			buffer.writeu8(out, o + 3, 255)
		elseif ga == 0 then
			buffer.writeu8(out, o, or_)
			buffer.writeu8(out, o + 1, og)
			buffer.writeu8(out, o + 2, ob)
			buffer.writeu8(out, o + 3, oa)
		else
			local oaf = oa / 255
			local saf = ga / 255
			local finaf = oaf + saf * (1 - oaf)
			local fina = math.floor(finaf * 255 + 0.5)
			local finr, fing, finb
			if finaf > 0 then
				finr = math.floor(math.clamp((or_ / 255 * oaf + cr * saf * (1 - oaf)) / finaf * 255, 0, 255) + 0.5)
				fing = math.floor(math.clamp((og / 255 * oaf + cg * saf * (1 - oaf)) / finaf * 255, 0, 255) + 0.5)
				finb = math.floor(math.clamp((ob / 255 * oaf + cb * saf * (1 - oaf)) / finaf * 255, 0, 255) + 0.5)
			else
				finr, fing, finb = 0, 0, 0
			end
			buffer.writeu8(out, o, finr)
			buffer.writeu8(out, o + 1, fing)
			buffer.writeu8(out, o + 2, finb)
			buffer.writeu8(out, o + 3, fina)
		end
	end
	return out
end

-- Chromatic aberration: radially shift R outward and B inward from the image centre.
-- `amount` is the maximum pixel displacement at the corners.
function postProcess.applyChromaticAberration(buf: buffer, w: number, h: number, amount: number): buffer
	local cx = (w - 1) / 2
	local cy = (h - 1) / 2
	local maxRadius = math.sqrt(cx * cx + cy * cy)
	local scale = if maxRadius > 0 then amount / maxRadius else 0

	local out = buffer.create(w * h * 4)
	buffer.copy(out, 0, buf, 0, w * h * 4)

	local function readChannel(x: number, y: number, ch: number): number
		local sx = math.clamp(math.round(x), 0, w - 1)
		local sy = math.clamp(math.round(y), 0, h - 1)
		return buffer.readu8(buf, (sy * w + sx) * 4 + ch)
	end

	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local o = (y * w + x) * 4
			local dx = (x - cx) * scale
			local dy = (y - cy) * scale
			-- R shifted outward, B shifted inward, G unchanged
			buffer.writeu8(out, o, readChannel(x + dx, y + dy, 0))
			buffer.writeu8(out, o + 2, readChannel(x - dx, y - dy, 2))
		end
	end
	return out
end

return postProcess
