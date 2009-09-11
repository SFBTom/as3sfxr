package  
{
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.GraphicsPath;
	import flash.display.GraphicsSolidFill;
	import flash.display.GraphicsStroke;
	import flash.display.IGraphicsData;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.ContextMenu;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import ui.TinyButton;
	import ui.TinySlider;
	
	/**
	 * SfxrApp
	 * 
	 * Copyright 2009 Thomas Vian
	 *
	 * Licensed under the Apache License, Version 2.0 (the "License");
	 * you may not use this file except in compliance with the License.
	 * You may obtain a copy of the License at
	 *
	 * 	http://www.apache.org/licenses/LICENSE-2.0
	 *
	 * Unless required by applicable law or agreed to in writing, software
	 * distributed under the License is distributed on an "AS IS" BASIS,
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 * See the License for the specific language governing permissions and
	 * limitations under the License.
	 * 
	 * @author Thomas Vian
	 */
	[SWF(width='640', height='485', backgroundColor='#C0B090', frameRate='25')]
	public class SfxrApp extends Sprite
	{
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		[Embed(source = "assets/amiga4ever.ttf", fontName = "Amiga4Ever", mimeType = 'application/x-font')]
		private var Amiga4Ever:Class;				// Pixel font, original was in a tga file
		
		[Embed(source = "assets/logo.png")]
		private var Logo:Class;						// SFB09 logo, for the bottom left corner
		
		private var _synth:SfxrSynth;				// synthesizer instance
		
		private var _propLookup:Dictionary;			// Look up for property names using a slider key
		private var _sliderLookup:Object;			// Look up for sliders using a property name key
		private var _waveformLookup:Array;			// Look up for waveform buttons
		private var _squareLookup:Array;			// Look up for sliders controlling a square wave property
		
		private var _copyPaste:TextField;			// Input TextField for the settings
		
		//--------------------------------------------------------------------------
		//	
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Initialises the synthesizer and draws the interface
		 */
		public function SfxrApp() 
		{
			_synth = new SfxrSynth();
			_synth.randomize();
			
			_propLookup = new Dictionary();
			_sliderLookup = {};
			_waveformLookup = [];
			_squareLookup = [];
			
			drawButtons();
			drawSliders();
			drawGraphics();
			drawCopyPaste();
			
			updateSliders();
			updateButtons();
			updateCopyPaste();
		}
		
		
		//--------------------------------------------------------------------------
		//	
		//  Button Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Adds the buttons to the stage
		 */
		private function drawButtons():void
		{
			// Generator
			addButton("PICKUP/COIN", 	clickPickupCoin, 	4, 32);
			addButton("LASER/SHOOT", 	clickLaserShoot, 	4, 62);
			addButton("EXPLOSION", 		clickExplosion,  	4, 92);
			addButton("POWERUP", 		clickPowerup, 		4, 122);
			addButton("HIT/HURT", 		clickHitHurt, 		4, 152);
			addButton("JUMP", 			clickJump, 			4, 182);
			addButton("BLIP/SELECT", 	clickBlipSelect, 	4, 212);
			addButton("MUTATE", 		clickMutate, 		4, 384);
			addButton("RANDOMIZE", 		clickRandomize, 	4, 414, 2);
			
			// Waveform
			addButton("SQUAREWAVE", 	clickSquarewave, 	130, 28, 1, true);
			addButton("SAWTOOTH", 		clickSawtooth, 		250, 28, 1, true);
			addButton("SINEWAVE", 		clickSinewave, 		370, 28, 1, true);
			addButton("NOISE", 			clickNoise, 		490, 28, 1, true);
			
			// Play / save / export
			addButton("PLAY SOUND", 	clickPlaySound, 	490, 198);
			addButton("LOAD SOUND", 	clickLoadSound, 	490, 288);
			addButton("SAVE SOUND", 	clickSaveSound, 	490, 318);
			addButton("EXPORT .WAV", 	clickExportWav, 	490, 378, 3);
			addButton("44100 HZ", 		clickSampleRate, 	490, 408);
			addButton("16-BIT", 		clickBitDepth, 		490, 438);
		}
		
		/**
		 * Adds a single button
		 * @param	label			Text to display on the button
		 * @param	onClick			Callback function called when the button is clicked
		 * @param	x				X position of the button
		 * @param	y				Y position of the button
		 * @param	border			Thickness of the border in pixels
		 * @param	selectable		If the button is selectable
		 * @param	selected		If the button starts as selected
		 */
		private function addButton(	label:String, onClick:Function, x:Number, y:Number, border:Number = 1, selectable:Boolean = false):void
		{
			var button:TinyButton = new TinyButton(onClick, label, border, selectable);
			button.x = x;
			button.y = y;
			addChild(button);
			
			if(selectable) _waveformLookup.push(button);
		}
		
		/**
		 * Updates the buttons to reflect the synthesizer
		 */
		private function updateButtons():void
		{
			selectedSwitch(_waveformLookup[_synth.waveType]);
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Generator Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Sets the synthesizer to generate a pickup/coin sound and previews it
		 * @param	button	Button pressed
		 */
		private function clickPickupCoin(button:TinyButton):void
		{
			_synth.generatePickupCoin();
			updateSliders();
			updateButtons();
			updateCopyPaste();
			_synth.play();
		}
		
		/**
		 * Sets the synthesizer to generate a laser/shoot sound and previews it
		 * @param	button	Button pressed
		 */
		private function clickLaserShoot(button:TinyButton):void
		{
			_synth.generateLaserShoot();
			updateSliders();
			updateButtons();
			updateCopyPaste();
			_synth.play();
		}
		
		/**
		 * Sets the synthesizer to generate an explosion sound and previews it
		 * @param	button	Button pressed
		 */
		private function clickExplosion(button:TinyButton):void
		{
			_synth.generateExplosion();
			updateSliders();
			updateButtons();
			updateCopyPaste();
			_synth.play();
		}
		
		/**
		 * Sets the synthesizer to generate a powerup sound and previews it
		 * @param	button	Button pressed
		 */
		private function clickPowerup(button:TinyButton):void
		{
			_synth.generatePowerup();
			updateSliders();
			updateButtons();
			updateCopyPaste();
			_synth.play();
		}
		
		/**
		 * Sets the synthesizer to generate a hit/hurt sound and previews it
		 * @param	button	Button pressed
		 */
		private function clickHitHurt(button:TinyButton):void
		{
			_synth.generateHitHurt();
			updateSliders();
			updateButtons();
			updateCopyPaste();
			_synth.play();
		}
		
		/**
		 * Sets the synthesizer to generate a jump sound and previews it
		 * @param	button	Button pressed
		 */
		private function clickJump(button:TinyButton):void
		{
			_synth.generateJump();
			updateSliders();
			updateButtons();
			updateCopyPaste();
			_synth.play();
		}
		
		/**
		 * Sets the synthesizer to generate a blip/select sound and previews it
		 * @param	button	Button pressed
		 */
		private function clickBlipSelect(button:TinyButton):void
		{
			_synth.generateBlipSelect();
			updateSliders();
			updateButtons();
			updateCopyPaste();
			_synth.play();
		}
		
		/**
		 * Sets the synthesizer to mutate the sound and preview it
		 * @param	button	Button pressed
		 */
		private function clickMutate(button:TinyButton):void
		{
			_synth.mutate();
			updateSliders();
			updateButtons();
			updateCopyPaste();
			_synth.play();
		}
		
		/**
		 * Sets the synthesizer to randomize the sound and preview it
		 * @param	button	Button pressed
		 */
		private function clickRandomize(button:TinyButton):void
		{
			_synth.randomize();
			updateSliders();
			updateButtons();
			updateCopyPaste();
			_synth.play();
		}          
		
		//--------------------------------------------------------------------------
		//	
		//  Waveform Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Selects the squarewave waveform type
		 * @param	button	Button pressed
		 */
		private function clickSquarewave(button:TinyButton):void
		{
			_synth.waveType = 0;
			selectedSwitch(button);
			updateCopyPaste();
		}
		
		/**
		 * Selects the sawtooth waveform type
		 * @param	button	Button pressed
		 */
		private function clickSawtooth(button:TinyButton):void
		{
			_synth.waveType = 1;
			selectedSwitch(button);
			updateCopyPaste();
		}
		
		/**
		 * Selects the sinewave waveform type
		 * @param	button	Button pressed
		 */
		private function clickSinewave(button:TinyButton):void
		{
			_synth.waveType = 2;
			selectedSwitch(button);
			updateCopyPaste();
		}
		
		/**
		 * Selects the noise waveform type
		 * @param	button	Button pressed
		 */
		private function clickNoise(button:TinyButton):void
		{
			_synth.waveType = 3;
			selectedSwitch(button);
			updateCopyPaste();
		}
		
		/**
		 * Unselects all the waveform buttons and selects the one passed in 
		 * @param	select	Selects this button
		 */
		private function selectedSwitch(select:TinyButton):void
		{
			for(var i:uint = 0, l:uint = _waveformLookup.length; i < l; i++)
			{
				if(_waveformLookup[i] != select) _waveformLookup[i].selected = false;
			}
			
			if(!select.selected) select.selected = true;
			
			for(i = 0; i < 2; i++)
			{
				_squareLookup[i].dimLabel = _synth.waveType != 0;
			}
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Play/Save/Export Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Previews the sound
		 * @param	button	Button pressed
		 */
		private function clickPlaySound(button:TinyButton):void
		{
			_synth.play();
		}
		
		/**
		 * Opens a browse window to load a sound setting file
		 * @param	button	Button pressed
		 */
		private function clickLoadSound(button:TinyButton):void
		{
			var file:FileReference = new FileReference();
			file.addEventListener(Event.SELECT, onSelectSettings);
			file.browse([new FileFilter("SFX Sample Files (*.sfs)", "*.sfs")]);
		}
		
		/**
		 * When the user selects a file, begins loading it
		 * @param	e	Select event
		 */
		private function onSelectSettings(e:Event):void
		{
			var file:FileReference = e.target as FileReference;
			file.removeEventListener(Event.SELECT, onSelectSettings);
			file.addEventListener(Event.COMPLETE, onLoadSettings);
			file.load();
		}
		
		/**
		 * Once loaded, passes the file to the synthesizer to parse
		 * @param	e	Complete event
		 */
		private function onLoadSettings(e:Event):void
		{
			var file:FileReference = e.target as FileReference;
			file.removeEventListener(Event.COMPLETE, onLoadSettings);
			
			_synth.setSettingsFile(file.data);
			updateSliders();
			updateButtons();
			updateCopyPaste();
		}
		
		/**
		 * Saves out a sound settings file
		 * @param	button	Button pressed
		 */
		private function clickSaveSound(button:TinyButton):void
		{
			var file:ByteArray = _synth.getSettingsFile();
			
			new FileReference().save(file, "sfx.sfs");
		}
		
		/**
		 * Exports the sound as a .wav file
		 * @param	button	Button pressed
		 */
		private function clickExportWav(button:TinyButton):void
		{
			var file:ByteArray = _synth.getWavFile();
			
			new FileReference().save(file, "sfx.wav");
		}
		
		/**
		 * Switches the sample rate between 44100Hz and 22050Hz 
		 * @param	button	Button pressed
		 */
		private function clickSampleRate(button:TinyButton):void
		{
			if(_synth.sampleRate == 44100) 	_synth.sampleRate = 22050;
			else 							_synth.sampleRate = 44100;
			
			button.label = _synth.sampleRate + " HZ";
		}
		
		/**
		 * Switches the bit depth between 16-bit and 8-bit
		 * @param	button	Button pressed
		 */
		private function clickBitDepth(button:TinyButton):void
		{
			if(_synth.bitDepth == 16) 	_synth.bitDepth = 8;
			else 						_synth.bitDepth = 16;
			
			button.label = _synth.bitDepth + "-BIT";
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Slider Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Adds the sliders to the stage
		 */
		private function drawSliders():void
		{
			addSlider("ATTACK TIME", 			"attackTime", 			350, 70);
			addSlider("SUSTAIN TIME",			"sustainTime", 			350, 88);
			addSlider("SUSTAIN PUNCH",			"sustainPunch", 		350, 106);
			addSlider("DECAY TIME",				"decayTime", 			350, 124);
			addSlider("START FREQUENCY",		"startFrequency", 		350, 142);
			addSlider("MIN FREQUENCY",			"minFrequency", 		350, 160);
			addSlider("SLIDE",					"slide", 				350, 178, true);
			addSlider("DELTA SLIDE",			"deltaSlide", 			350, 196, true);
			addSlider("VIBRATO DEPTH",			"vibratoDepth", 		350, 214);
			addSlider("VIBRATO SPEED", 			"vibratoSpeed", 		350, 232);
			addSlider("CHANGE AMOUNT", 			"changeAmount", 		350, 250, true);
			addSlider("CHANGE SPEED", 			"changeSpeed", 			350, 268);
			addSlider("SQUARE DUTY", 			"squareDuty", 			350, 286, false, true);
			addSlider("DUTY SWEEP", 			"dutySweep", 			350, 304, true, true);
			addSlider("REPEAT SPEED", 			"repeatSpeed", 			350, 322);
			addSlider("PHASER OFFSET", 			"phaserOffset", 		350, 340, true);
			addSlider("PHASER SWEEP", 			"phaserSweep", 			350, 358, true);
			addSlider("LP FILTER CUTOFF", 		"lpFilterCutoff", 		350, 376);
			addSlider("LP FILTER CUTOFF SWEEP", "lpFilterCutoffSweep", 	350, 394, true);
			addSlider("LP FILTER RESONANCE", 	"lpFilterResonance", 	350, 412);
			addSlider("HP FILTER CUTOFF", 		"hpFilterCutoff", 		350, 430);
			addSlider("HP FILTER CUTOFF SWEEP", "hpFilterCutoffSweep", 	350, 448, true);
			addSlider("", 						"masterVolume", 		492, 178);
		}
		
		/**
		 * Adds a single slider
		 * @param	label			Text label to display next to the slider
		 * @param	property		Property name to link with the slider
		 * @param	x				X position of slider
		 * @param	y				Y Position of slider
		 * @param	plusMinus		If the slider ranges from -1 to 1 (true) or 0 to 1 (false)
		 * @param	square			If the slider is linked to the square duty properties
		 */
		private function addSlider(label:String, property:String, x:Number, y:Number, plusMinus:Boolean = false, square:Boolean = false):void
		{
			var slider:TinySlider = new TinySlider(onSliderChange, label, plusMinus);
			slider.x = x;
			slider.y = y;
			addChild(slider);
			
			_propLookup[slider] = property;
			_sliderLookup[property] = slider;
			
			if(square) _squareLookup.push(slider);
		}
		
		/**
		 * Updates the property on the synthesizer to the slider's value
		 * @param	slider
		 */
		private function onSliderChange(slider:TinySlider):void
		{
			_synth[_propLookup[slider]] = slider.value;
			
			updateCopyPaste();
		}
		
		/**
		 * Updates the sliders to reflect the synthesizer
		 */
		private function updateSliders():void
		{
			for(var prop:String in _sliderLookup)
			{
				_sliderLookup[prop].value = _synth[prop];
			}
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Copy Paste Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Adds a TextField over the whole app. 
		 * Allows for right-click copy/paste, as well as ctrl-c/ctrl-v
		 */
		private function drawCopyPaste():void
		{
			_copyPaste = new TextField();
			_copyPaste.addEventListener(TextEvent.TEXT_INPUT, updateFromCopyPaste);
			_copyPaste.addEventListener(KeyboardEvent.KEY_DOWN, updateCopyPaste);
			_copyPaste.addEventListener(KeyboardEvent.KEY_UP, updateCopyPaste);
			_copyPaste.defaultTextFormat = new TextFormat("Amiga4Ever", 8, 0);
			_copyPaste.wordWrap = false;
			_copyPaste.multiline = false;
			_copyPaste.type = TextFieldType.INPUT;
			_copyPaste.embedFonts = true;
			_copyPaste.width = 640;
			_copyPaste.height = 580;
			_copyPaste.x = 0;
			_copyPaste.y = -20;
			addChild(_copyPaste);
			
			_copyPaste.contextMenu = new ContextMenu();
			_copyPaste.contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, updateCopyPaste);
			
			Mouse.cursor = MouseCursor.ARROW;
		}
		
		/**
		 * Updates the contents of the textfield to a representation of the settings
		 * @param	e	Optional event
		 */
		private function updateCopyPaste(e:Event = null):void
		{
			_copyPaste.text = _synth.getSettingsString();
			
			_copyPaste.setSelection(0, _copyPaste.text.length);
			stage.focus = _copyPaste;
		}
		
		/**
		 * When the textfield is pasted into, and the new info parses, updates the settings
		 * @param	e	Text input event
		 */
		private function updateFromCopyPaste(e:TextEvent):void
		{
			if (!_synth.setSettingsString(e.text)) 
			{
				_copyPaste.setSelection(0, _copyPaste.text.length);
				stage.focus = _copyPaste;
				
				_copyPaste.text = _synth.getSettingsString();
			}
			
			_copyPaste.setSelection(0, _copyPaste.text.length);
			stage.focus = _copyPaste;
			
			updateSliders();
			updateButtons();
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Graphics Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Draws the extra labels, frames and lines to the stage
		 */
		private function drawGraphics():void
		{
			var lines:Vector.<IGraphicsData> = new Vector.<IGraphicsData>();
			lines.push(new GraphicsStroke(2, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 3, new GraphicsSolidFill(0)));
			lines.push(new GraphicsPath(Vector.<int>([1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,2]), 
										Vector.<Number>([	114,0, 		114,490,
															160,66,		460,66,
															160,138,	460,138,
															160,246,	460,246,
															160,282,	460,282,
															160,318,	460,318,
															160,336,	460,336,
															160,372,	460,372,
															160, 462,	460, 462,
															590,182, 618,182, 618,388, 590,388])));
			lines.push(new GraphicsStroke(1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 3, new GraphicsSolidFill(0)));
			lines.push(new GraphicsPath(Vector.<int>([1,2,1,2,1,2,1,2]), 
										Vector.<Number>([	160, 65, 	160, 463,
															460, 65,	460, 463])));
			
			graphics.drawGraphicsData(lines);
			
			graphics.lineStyle(2, 0xFF0000, 1, true, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.MITER);
			graphics.drawRect(549.5, 177.5, 43, 10);
			
			addLabel("VOLUME", 516, 162, 0);
			
			addLabel("GENERATOR", 6, 8, 0x504030);
			addLabel("MANUAL SETTINGS", 122, 8, 0x504030);
			
			addLabel("AS3SFXR | THOMAS VIAN 2009 | BASED ON SFXR BY TOMAS PETTERSSON", 124, 468, 0x877569, 500);
			
			var logo:DisplayObject = new Logo();
			logo.x = 4;
			logo.y = 444;
			addChild(logo);
		}
		
		/**
		 * Adds a label
		 * @param	label		Text to display
		 * @param	x			X position of the label
		 * @param	y			Y position of the label
		 * @param	colour		Colour of the text
		 */
		private function addLabel(label:String, x:Number, y:Number, colour:uint, width:Number = 200):void
		{
			var txt:TextField = new TextField();
			txt.defaultTextFormat = new TextFormat("Amiga4Ever", 8, colour);
			txt.selectable = false;
			txt.embedFonts = true;
			txt.text = label;
			txt.width = width;
			txt.height = 15;
			txt.x = x;
			txt.y = y;
			addChild(txt);
		}
	}
}