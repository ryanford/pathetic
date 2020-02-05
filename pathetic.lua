local lpeg = require("lpeg")
local P, S, R, V, C, Cc, Cf = lpeg.P, lpeg.S, lpeg.R, lpeg.V, lpeg.C, lpeg.Cc, lpeg.Cf

local pathetic = {}

function pathetic.unescape(self, str)
	if not str then return nil, "no string given" end
	local unescaped = str:gsub("%%([0-7A-Fa-f][0-7A-Fa-f])", function(hex) return string.char("0x" .. hex) end)
	return unescaped
end

function pathetic.escape(self, str)
	if not str then return nil, "no string given" end
	local escaped = str:gsub("[%:%/%?%#%[%]%@%!%$%&%'%(%)%*%+%,%;%=%s]", function(c)
		local byte = string.format("%x", string.byte(c)):upper()
		return "%" .. (#byte == 2 and byte or "0" .. byte)
	end)
	return escaped
end

local pchar = P{
	"pchar",
	pchar = V"unreserved" + V"pct_encoded" + V"sub_delims" + S":@",
	pct_encoded = P"%" * V"hexdig" * V"hexdig",
	unreserved = V"alpha" + V"digit" + S"-._~",
	sub_delims = S"!$&'()*+,;=",
	alpha = R("AZ", "az"),
	digit = R"09",
	hexdig = R("AF", "af", "09")
}

function pathetic.parse_query(self, query)
	if not query then return nil, "no query given" end
	local set = {}
	local parsed = P{
		"parsed_query",
		parsed_query = Cf(Cc{} * (V"stmt" * (P"&" * V"stmt") ^ 0) ^ -1 * -1, function(acc, x)
			if acc[1] then -- match is value
				local key = acc[1]
				if acc[key] then -- key already used
					if type(acc[key]) == "table" then -- key used more than once already
						if not set[key][x] then
							table.insert(acc[key], x)
							set[key][x] = true
						end
					else
						if acc[key] ~= x then -- key used but different value
							acc[key] = { acc[key], x }
							set[key][x] = true
						end
					end
				else -- new key
					acc[key] = x
					set[key] = { [x] = true }
				end
				acc[1] = nil
			else -- match is key
				acc[1] = x
			end

			return acc
		end),
		stmt = V"pair" + V"single",
		single = V"key" * Cc"",
		pair = V"key" * P"=" * V"value",
		key = Cc(self) * C((pchar - S"&=") ^ 1) / self.unescape,
		value = Cc(self) * C((pchar - P"&") ^ 0) / self.unescape,
	}:match(query)
	if not parsed then return nil, "query string malformed" end
	return parsed
end

local query = (pchar + S"/?") ^ 0

local fragment = (pchar + S"/?") ^ 0

local path_part = P{
	"path_part",
	path_part = V"path_abempty" + V"path_absolute" + V"path_noscheme" + V"path_rootless" + V"path_empty",
	path_abempty = (P"/" * V"segment") ^ 0,
	path_absolute = P"/" * (V"segment_nz" * (P"/" * V"segment") ^ 0) ^ -1,
	path_noscheme = V"segment_nz_nc" * (P"/" * V"segment") ^ 0,
	path_rootless = V"segment_nz" * (P"/" * V"segment") ^ 0,
	path_empty = P(-1),
	segment = pchar ^ 0,
	segment_nz = pchar ^ 1,
	segment_nz_nc = (pchar - P":") ^ 1,
}

local uri = P{
	"uri",
	uri = V"path_noquery_nofragment" + V"path_query_nofragment" + V"path_noquery_fragment" + V"path_query_fragment",
	path_noquery_nofragment = C(path_part) * -1,
	path_query_nofragment = C(path_part) * P"?" * C(query) * -1,
	path_noquery_fragment = C(path_part) * Cc(nil) * P"#" * C(fragment) * -1,
	path_query_fragment = C(path_part) * P"?" * C(query) * P"#" * C(fragment) * -1,
}

function pathetic.parse(self, path)
	if not path then return nil, "no path given" end
	local parsed
	local raw_path, raw_query, raw_fragment = uri:match(path)
	if not raw_path then return nil, "path is malformed" end
	parsed = {
		raw_path = raw_path,
		raw_query = raw_query,
		raw_fragment = raw_fragment,
		path = self:unescape(raw_path),
		query = self:parse_query(raw_query),
		fragment = self:unescape(raw_fragment),
	}
	return parsed
end

function pathetic.get_raw_path(self, path)
	if not path then return nil, "no path given" end
	local raw_path = (C(path_part) * (P"?" * query) ^ -1 * (P"#" * fragment) ^ -1 * -1):match(path)
	if not raw_path then return nil, "path is malformed" end
	return raw_path
end

function pathetic.get_path(self, path)
	if not path then return nil, "no path given" end
	local unescaped_path = ((Cc(self) * C(path_part) / self.unescape) * (P"?" * query) ^ -1 * (P"#" * fragment) ^ -1 * -1):match(path)
	if not unescaped_path then return nil, "path is malformed" end
	return unescaped_path
end

function pathetic.get_raw_query(self, path)
	if not path then return nil, "no path given" end
	local raw_query = (path_part * ((P"?" * C(query)) + Cc(nil)) ^ -1 * (P"#" * fragment) ^ -1 * -1):match(path)
	if not raw_query then return nil, "path is malformed" end
	return raw_query
end

function pathetic.get_query(self, path)
	if not path then return nil, "no path given" end
	local parsed_query = (path_part * ((P"?" * ((Cc(self) * C(query)) / self.parse_query)) + Cc(nil)) ^ -1 * (P"#" * fragment) ^ -1 * -1):match(path)
	if not parsed_query then return nil, "path is malformed" end
	return parsed_query
end

function pathetic.get_raw_fragment(self, path)
	if not path then return nil, "no path given" end
	local raw_fragment = (path_part * (P"?" * query) ^ -1 * ((P"#" * C(fragment)) ^ -1 + Cc(nil)) * -1):match(path)
	if not raw_fragment then return nil, "path is malformed" end
	return raw_fragment
end

function pathetic.get_fragment(self, path)
	if not path then return nil, "no path given" end
	local unescaped_fragment = (path_part * (P"?" * query) ^ -1 * (P"#" * (Cc(self) * C(fragment) / self.unescape)) ^ -1 * -1):match(path)
	if not unescaped_fragment then return nil, "path is malformed" end
	return unescaped_fragment
end

return pathetic
