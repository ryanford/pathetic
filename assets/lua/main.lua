package.path = "assets/lua/?.lua;" .. package.path

local pathetic = require("pathetic")
local inspect = require("inspect")
local js = require("js")

local window = js.global
local document = window.document

local display = document:getElementById("display")
local form = document:getElementById("ui")
local label = form:querySelector("label")
local path_input = document:getElementById("path_input")
local btn = document:getElementById("submit_btn")

form:addEventListener("submit", function(self, e)
	local input = document:getElementById("path_input")
	local parsed, err = pathetic:parse(input.value)
	display.textContent = parsed and inspect(parsed) or err
end)

btn:removeAttribute("disabled")
label:removeAttribute("style")
path_input:removeAttribute("style")
btn:removeAttribute("style")
