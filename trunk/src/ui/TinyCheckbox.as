package ui
{
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	/**
	 * TinyCheckbox
	 * 
	 * Copyright 2010 Thomas Vian
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
	public class TinyCheckbox extends Sprite 
	{
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		
		protected var _back:Shape;					// Background colour shape
		protected var _tick:Shape;					// Tick indicating selection
		protected var _border:Shape;				// Border shape to cover the borders of the back and tick
		
		protected var _text:TextField;				// Label TextField positioned to the left of the checkbox (right aligned)
		
		protected var _rect:Rectangle;				// Bounds of the checkbox and text in the context of the stage
		
		protected var _value:Boolean;				// The current value of the checkbox
		
		protected var _onChange:Function;			// Callback function called when the value of the checkbox changes
		
		//--------------------------------------------------------------------------
		//	
		// Getters / Setters
		//
		//--------------------------------------------------------------------------
		
		/** The value of the checkbox */
		public function get value():Boolean {return _value;}
		public function set value(v:Boolean):void
		{
			if (v != _value)
			{
				_value = v;
				
				_tick.visible = _value;
				
				_onChange(this);
			}
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Creates the TinyCheckbox, adding text and three shapes
		 * @param	onChange		Callback function called when the value of the checkbox changes
		 * @param	label			Label to display to the left of the checkbox
		 */
		public function TinyCheckbox(onChange:Function, label:String = "")
		{
			_onChange = onChange;
			_value = true;
			
			mouseChildren = false;
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			_back = 	drawRect(0, 		0x807060);
			_border = 	drawRect(0, 		0xFFFFFF, 0);
			_tick = 	drawRect(0xFFFFFF, 	0xF0C090, 1, true);
			
			if(label != "")
			{
				_text = new TextField();
				_text.defaultTextFormat = new TextFormat("Amiga4Ever", 8, 0, null, null, null, null, null, TextFormatAlign.RIGHT);
				_text.antiAliasType = AntiAliasType.ADVANCED;
				_text.selectable = false;
				_text.embedFonts = true;
				_text.text = label;
				_text.width = 200;
				_text.height = 20;
				_text.x = -205;
				_text.y = -2.5;
				addChild(_text);
			}
			
			addChild(_back);
			addChild(_tick);
			addChild(_border);
		}
		
		/**
		 * Once the checkbox is on the stage, the event listener can be set up and rectangles recorded
		 * @param	e	Added to stage event
		 */
		private function onAdded(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAdded)
			stage.addEventListener(MouseEvent.CLICK, onMouseClick);
			
			_rect = _back.getBounds(stage);
			
			if (_text)  _rect = _rect.union(_text.getBounds(stage));
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Mouse Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Switches the value of the checkbox
		 * @param	e	MouseEvent
		 */
		protected function onMouseClick(e:MouseEvent):void
		{
			if (_rect.contains(stage.mouseX, stage.mouseY))
			{
				value = !_value;
			}
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Util Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Returns a background shape with the specified colours and alpha
		 * @param	borderColour		Colour of the border
		 * @param	fillColour			Colour of the fill
		 * @param	fillAlpha			Alpha of the fill
		 * @param	tick				If the box should be drawn smaller (for the tick)
		 * @return						The drawn rectangle Shape 
		 */
		private function drawRect(borderColour:uint, fillColour:uint, fillAlpha:Number = 1, tick:Boolean = false):Shape
		{
			var rect:Shape = new Shape();
			rect.graphics.lineStyle(1, borderColour, tick ? 0 : 1, true, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.MITER);
			rect.graphics.beginFill(fillColour, fillAlpha);
			if (tick) 	rect.graphics.drawRect(2, 2, 6, 6);
			else 		rect.graphics.drawRect(0, 0, 9, 9);
			rect.graphics.endFill();
			return rect;
		}
	}
}