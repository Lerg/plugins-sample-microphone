display.setStatusBar(display.HiddenStatusBar)

local widget = require('widget')
local json = require('json')
local microphone = require('plugin.microphone')

microphone.enableDebug() -- Shows when signal detector changes states.

display.setDefault('background', 1)

local x, y = display.contentCenterX, display.contentCenterY - 200
local w, h = display.contentWidth * 0.4, 50
local x_spacing = display.contentWidth * 0.25

local gain_label = display.newText{text = 'Gain: ', x = 0, y = display.contentHeight - 0.1 * display.contentHeight, align = 'left'}
gain_label.anchorX, gain_label.anchorY = 0, 1
gain_label:setFillColor(0.2)

local volume_label = display.newText{text = 'Volume: ', x = 0, y = display.contentHeight, align = 'left'}
volume_label.anchorX, volume_label.anchorY = 0, 1
volume_label:setFillColor(0.2)

local radius = 0.8 * display.contentCenterX
local circle = display.newCircle(x, display.contentHeight - radius, radius)
circle:setFillColor(0, 1, 1)
circle:scale(0.01, 0.01)

local is_initialized = false

function circle:enterFrame()
	if is_initialized then
		local volume = microphone.getVolume()
		local scale = math.sqrt(volume) -- Values are from 0 to 1. Normal values are quite low, hence sqrt.
		self.xScale, self.yScale = scale, scale
		gain_label.text = string.format('Gain: %.2f', microphone.getGain())
		volume_label.text = string.format('Volume: %.2f', volume)
	end
end
Runtime:addEventListener('enterFrame', circle)

local function microphone_listener(event)
	if not event.isError then
		if event.name == 'init' then
			is_initialized = true
		end
	end
	print(json.encode(event))
end

local filename

widget.newButton{
	x = x, y = y,
	width = w, height = h,
	label = 'Init',
	onRelease = function()
		filename = tostring(math.random()):sub(3, 10) .. '.wav' -- Random filename prevents audio caching by Corona.
		microphone.init{
			filename = filename,
			--baseDir = system.DocumentsDirectory,
			--sampleRate = 44100, -- Sample rate in Hz.
			detector = { -- Optional.
				on = 0.2, -- Start recording when volume is larger or equal to this value.
				off = 0.05 -- Trim the end if the volume of the last part is less than this value.
			},
			gain = { -- Gain control.
				--min = 0, -- Minimal gain.
				max = 10, -- Maximum gain.
				--value = 1, -- Initial gain value.
				target = 0.1, -- Target volume. 0 is disable.
				--speed = 0.1, -- Gain adjustment speed.
				--allowClipping = false, -- If true, gain is not automatically reduced to prevent clipping.
			},
			listener = microphone_listener
		}
	end}

widget.newButton{
	x = x - x_spacing, y = y + 50,
	width = w, height = h,
	label = 'Start recording',
	onRelease = function()
		microphone.start()
	end}

widget.newButton{
	x = x + x_spacing, y = y + 50,
	width = w, height = h,
	label = 'Stop recording',
	onRelease = function()
		microphone.stop()
	end}

widget.newButton{
	x = x - x_spacing, y = y + 100,
	width = w, height = h,
	label = 'Is recording?',
	onRelease = function()
		native.showAlert('Is recording?', microphone.isRecording() and 'Yes' or 'No', {'OK'})
	end}

widget.newButton{
	x = x + x_spacing, y = y + 100,
	width = w, height = h,
	label = 'Set gain to 1',
	onRelease = function()
		microphone.set{gain = {value = 1}}
	end}

local audio_file
widget.newButton{
	x = x - x_spacing, y = y + 150,
	width = w, height = h,
	label = 'Play file',
	onRelease = function()
		if filename then
			audio_file = audio.loadSound(filename, system.DocumentsDirectory)
			if audio_file then
				print('Audio file started.')
				audio.play(audio_file, {onComplete = function()
					print('Audio file ended.')
				end})
			else
				print('Audio file does not exist')
			end
		end
	end}

widget.newButton{
	x = x + x_spacing, y = y + 150,
	width = w, height = h,
	label = 'Stop file',
	onRelease = function()
		if audio_file then
			audio.stop()
			audio.dispose(audio_file)
			audio_file = nil
		end
	end}