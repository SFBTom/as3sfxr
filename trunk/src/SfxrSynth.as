package
{
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	/**
	 * SfxrSynth
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
	public class SfxrSynth
	{
		//--------------------------------------------------------------------------
		//
		//  Sound Parameters
		//
		//--------------------------------------------------------------------------
		
		public var waveType				:int = 		0;		// Shape of the wave (square, saw, sin or noise)
		
		public var sampleRate			:int = 		44100;	// Samples per second - only used for .wav export
		
		public var bitDepth				:int = 		16;		// Bits per sample - only used for .wav export
		
		public var masterVolume			:Number = 	0.5;	// Overall volume of the sound
		
		public var attackTime			:Number =	0.0;	// Length of the volume envelope attack
		public var sustainTime			:Number = 	0.0;	// Length of the volume envelope sustain
		public var sustainPunch			:Number = 	0.0;	// Tilts the sustain envelope for more 'pop'
		public var decayTime			:Number = 	0.0;	// Length of the volume envelope decay (yes, I know it's called release)
		
		public var startFrequency		:Number = 	0.0;	// Base note of the sound
		public var minFrequency			:Number = 	0.0;	// If sliding, the sound will stop at this frequency, to prevent really low notes
		
		public var slide				:Number = 	0.0;	// Slides the note up or down
		public var deltaSlide			:Number = 	0.0;	// Accelerates the slide
		
		public var vibratoDepth			:Number = 	0.0;	// Strength of the vibrato effect
		public var vibratoSpeed			:Number = 	0.0;	// Speed of the vibrato effect (i.e. frequency)
		
		public var changeAmount			:Number = 	0.0;	// Shift in note, either up or down
		public var changeSpeed			:Number = 	0.0;	// How fast the note shift happens (only happens once)
		
		public var squareDuty			:Number = 	0.0;	// Controls the ratio between the up and down states of the square wave, changing the tibre
		public var dutySweep			:Number = 	0.0;	// Sweeps the duty up or down
		
		public var repeatSpeed			:Number = 	0.0;	// Speed of the note repeating - certain variables are reset each time
		
		public var phaserOffset			:Number = 	0.0;	// Offsets a second copy of the wave by a small phase, changing the tibre
		public var phaserSweep			:Number = 	0.0;	// Sweeps the phase up or down
		
		public var lpFilterCutoff		:Number = 	0.0;	// Frequency at which the low-pass filter starts attenuating higher frequencies
		public var lpFilterCutoffSweep	:Number = 	0.0;	// Sweeps the low-pass cutoff up or down
		public var lpFilterResonance	:Number = 	0.0;	// Changes the attenuation rate for the low-pass filter, changing the timbre
		
		public var hpFilterCutoff		:Number = 	0.0;	// Frequency at which the high-pass filter starts attenuating lower frequencies
		public var hpFilterCutoffSweep	:Number = 	0.0;	// Sweeps the high-pass cutoff up or down
		
		//--------------------------------------------------------------------------
		//
		//  Preview Variables
		//
		//--------------------------------------------------------------------------
		
		private var _sound:Sound;							// Sound instance used to play the preview
		private var _channel:SoundChannel;					// SoundChannel instance of playing Sound
		
		private var _preview:ByteArray;						// Full preview wave, read out in chuncks by the onSampleData method
		private var _previewPos:uint;						// Current position in the preview
		private var _previewLength:uint;					// Number of bytes in the preview wave
		private var _previewSamples:uint;					// Number of bytes to write to the soundcard
		
		//--------------------------------------------------------------------------
		//
		//  Synth Variables
		//
		//--------------------------------------------------------------------------
		
		private var _envelopeVolume:Number;					// Current volume of the envelope
		private var _envelopeStage:int;						// Current stage of the envelope (attack, sustain, decay, end)
		private var _envelopeTime:Number;					// Current time through current enelope stage
		private var _envelopeLength:Number;					// Length of the current envelope stage
		private var _envelopeLength0:Number;				// Length of the attack stage
		private var _envelopeLength1:Number;				// Length of the sustain stage
		private var _envelopeLength2:Number;				// Length of the decay stage
		private var _envelopeOverLength0:Number;			// 1 / _envelopeLength0 (for quick calculations)
		private var _envelopeOverLength1:Number;			// 1 / _envelopeLength1 (for quick calculations)
		private var _envelopeOverLength2:Number;			// 1 / _envelopeLength2 (for quick calculations)
		private var _envelopeFullLength:Number;				// Full length of the volume envelop (and therefore sound)
		
		private var _phase:int;								// Phase through the wave
		private var _pos:Number;							// Phase expresed as a Number from 0-1
		private var _period:Number;							// Period of the wave
		private var _periodTemp:Number;						// Period modified by vibrato
		private var _maxPeriod:Number;						// Maximum period before sound stops (from minFrequency)
		
		private var _slide:Number;							// Note slide
		private var _deltaSlide:Number;						// Change in slide
		
		private var _vibratoPhase:Number;					// Phase through the vibrato sine wave
		private var _vibratoSpeed:Number;					// Speed at which the vibrato phase moves
		private var _vibratoAmplitude:Number;				// Amount to change the period of the wave by at the peak of the vibrato wave
		
		private var _changeAmount:Number					// Amount to change the note by
		private var _changeTime:int;						// Counter for the note change
		private var _changeLimit:int;						// Once the time reaches this limit, the note changes
		
		private var _squareDuty:Number;						// Offset of center switching point in the square wave
		private var _dutySweep:Number;						// Amount to change the duty by
		
		private var _repeatTime:int;						// Counter for the repeats
		private var _repeatLimit:int;						// Once the time reaches this limit, some of the variables are reset
		
		private var _phaserOffset:Number;					// Phase offset for phaser effect
		private var _phaserDeltaOffset:Number;				// Change in phase offset
		private var _phaserInt:int;							// Integer phaser offset, for bit maths
		private var _phaserPos:int;							// Position through the phaser buffer
		private var _phaserBuffer:Vector.<Number>;			// Buffer of wave values used to create the out of phase second wave
		
		private var _lpFilterPos:Number;					// Confession time
		private var _lpFilterOldPos:Number;					// I can't quite get a handle on how the filters work
		private var _lpFilterDeltaPos:Number;				// And the variables in the original source had short, meaningless names
		private var _lpFilterCutoff:Number;					// Perhaps someone would be kind enough to enlighten me
		private var _lpFilterDeltaCutoff:Number;			// I keep going back and staring at the code
		private var _lpFilterDamping:Number;				// But nothing comes to mind
		
		private var _hpFilterPos:Number;					// Oh well, it works
		private var _hpFilterCutoff:Number;					// And I guess that's all that matters
		private var _hpFilterDeltaCutoff:Number;			// Annoying though
		
		private var _noiseBuffer:Vector.<Number>;			// Buffer of random values used to generate noise
		
		private var _superSample:Number;					// Actual sample writen to the wave
		private var _sample:Number;							// Sub-sample calculated 8 times per actual sample, averaged out to get the super sample
		private var _sampleCount:uint;						// Number of samples added to the buffer sample
		private var _bufferSample:Number;					// Another supersample used to create a 22050Hz wave
		
		//--------------------------------------------------------------------------
		//	
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Instantiates the Sound instance and ssets up the buffers as fixed length Vectors
		 */
		public function SfxrSynth():void 
		{
			_sound = new Sound();
			_sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
			
			_phaserBuffer = new Vector.<Number>(1024, true);
			_noiseBuffer = new Vector.<Number>(32, true);
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Output Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Plays the preview of the wave, using the FP10 Sound API
		 */
		public function play():void
		{
			reset(true);
			
			if(_channel) _channel.stop();
			
			_preview = new ByteArray();
			synthWave(_preview, true);
			
			_previewPos = 0;
			_previewLength = _preview.length;
			_previewSamples = 24576;
			
			if(_previewLength < _previewSamples)
			{
				// If the sound is smaller than the buffer length, add silence to allow it to play
				for(var i:uint = 0, l:uint = _previewSamples - _previewLength; i < l; i++) _preview.writeFloat(0.0);
				
				_previewLength = _previewSamples;
			}
			
			_channel = _sound.play();
		}
		
		/**
		 * Reads out chuncks of data from the preview wave and writes it to the soundcard
		 * @param	e	SampleDataEvent to write data to
		 */
		private function onSampleData(e:SampleDataEvent):void
		{
			if(_previewPos + _previewSamples > _previewLength) _previewSamples = _previewLength - _previewPos;
			
			e.data.writeBytes(_preview, _previewPos, _previewSamples);
			
			_previewPos += _previewSamples;
		}
		
		/**
		 * Returns a ByteArray of the wave in the form of a .wav file, ready to be saved out
		 * @return	Wave in a .wav file
		 */
		public function getWavFile():ByteArray
		{
			reset(true);
			
			if(_channel) _channel.stop();
			
			var soundLength:uint = _envelopeFullLength;
			if (bitDepth == 16) soundLength *= 2;
			if (sampleRate == 22050) soundLength /= 2;
			
			var filesize:int = 36 + soundLength;
			var blockAlign:int = bitDepth / 8;
			var bytesPerSec:int = sampleRate * blockAlign;
			
			var wav:ByteArray = new ByteArray();
			
			// Header
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x52494646);		// Chunk ID "RIFF"
			wav.endian = Endian.LITTLE_ENDIAN;
			wav.writeUnsignedInt(filesize);			// Chunck Data Size
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x57415645);		// RIFF Type "WAVE"
			
			// Format Chunk
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x666D7420);		// Chunk ID "fmt "
			wav.endian = Endian.LITTLE_ENDIAN;
			wav.writeUnsignedInt(16);				// Chunk Data Size
			wav.writeShort(1);						// Compression Code PCM
			wav.writeShort(1);						// Number of channels
			wav.writeUnsignedInt(sampleRate);		// Sample rate
			wav.writeUnsignedInt(bytesPerSec);		// Average bytes per second
			wav.writeShort(blockAlign);				// Block align
			wav.writeShort(bitDepth);				// Significant bits per sample
			
			// Data Chunk
			wav.endian = Endian.BIG_ENDIAN;
			wav.writeUnsignedInt(0x64617461);		// Chunk ID "data"
			wav.endian = Endian.LITTLE_ENDIAN;
			wav.writeUnsignedInt(soundLength);		// Chunk Data Size
			
			synthWave(wav);
			
			wav.position = 0;
			
			return wav;
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Synth Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Resets the runing variables
		 * Used once at the start (total reset) and for the repeat effect (partial reset)
		 * @param	totalReset	If the reset is total
		 */
		private function reset(totalReset:Boolean):void
		{
			_period = 100.0 / (startFrequency * startFrequency + 0.001);
			_maxPeriod = 100.0 / (minFrequency * minFrequency + 0.001);
			
			_slide = 1.0 - slide * slide * slide * 0.01;
			_deltaSlide = -deltaSlide * deltaSlide * deltaSlide * 0.000001;
			
			_squareDuty = 0.5 - squareDuty * 0.5;
			_dutySweep = -dutySweep * 0.00005;
			
			if (changeAmount > 0.0) _changeAmount = 1.0 - changeAmount * changeAmount * 0.9;
			else 					_changeAmount = 1.0 + changeAmount * changeAmount * 10.0;
			
			_changeTime = 0;
			
			if(changeSpeed == 1.0) 	_changeLimit = 0;
			else 					_changeLimit = (1.0 - changeSpeed) * (1.0 - changeSpeed) * 20000 + 32;
			
			if(totalReset)
			{
				_phase = 0;
				
				_lpFilterPos = 0.0;
				_lpFilterDeltaPos = 0.0;
				_lpFilterCutoff = lpFilterCutoff * lpFilterCutoff * lpFilterCutoff * 0.1;
				_lpFilterDeltaCutoff = 1.0 + lpFilterCutoffSweep * 0.0001;
				_lpFilterDamping = 5.0 / (1.0 + lpFilterResonance * lpFilterResonance * 20.0) * (0.01 + _lpFilterCutoff)
				if(_lpFilterDamping > 0.8) _lpFilterDamping = 0.8;
				
				_hpFilterPos = 0.0;
				_hpFilterCutoff = hpFilterCutoff * hpFilterCutoff * 0.1;
				_hpFilterDeltaCutoff = 1.0 + hpFilterCutoffSweep * 0.0003;
				
				_vibratoPhase = 0.0;
				_vibratoSpeed = vibratoSpeed * vibratoSpeed * 0.01;
				_vibratoAmplitude = vibratoDepth * 0.5;
				
				_envelopeVolume = 0.0;
				_envelopeStage = 0;
				_envelopeTime = 0;
				_envelopeLength0 = attackTime * attackTime * 100000.0;
				_envelopeLength1 = sustainTime * sustainTime * 100000.0;
				_envelopeLength2 = decayTime * decayTime * 100000.0;
				_envelopeLength = _envelopeLength0;
				_envelopeFullLength = _envelopeLength0 + _envelopeLength1 + _envelopeLength2;
				
				_envelopeOverLength0 = 1.0 / _envelopeLength0;
				_envelopeOverLength1 = 1.0 / _envelopeLength1;
				_envelopeOverLength2 = 1.0 / _envelopeLength2;
				
				_phaserOffset = phaserOffset * phaserOffset * 1020.0;
				if(phaserOffset < 0.0) _phaserOffset = -_phaserOffset;
				_phaserDeltaOffset = phaserSweep * phaserSweep;
				if(_phaserDeltaOffset < 0.0) _phaserDeltaOffset = -_phaserDeltaOffset;
				_phaserPos = 0;
				for(var i:uint = 0; i < 1024; i++) _phaserBuffer[i] = 0.0;
				
				for(i = 0; i < 32; i++) _noiseBuffer[i] = Math.random() * 2.0 - 1.0;
				
				_repeatTime = 0;
				_repeatLimit = int((1.0-repeatSpeed) * (1.0-repeatSpeed)) * 20000 + 32;
				if(repeatSpeed == 0.0) _repeatLimit = 0;
			}
		}
		
		/**
		 * Writes the wave to the supplied buffer ByteArray
		 * @param	buffer		A ByteArray to write the wave to
		 * @param	preview		If the wave should be written for the preview 
		 */
		private function synthWave(buffer:ByteArray, preview:Boolean = false):void
		{
			var finished:Boolean = false;
			
			_sampleCount = 0;
			_bufferSample = 0.0;
			
			for(var i:uint = 0; i < _envelopeFullLength; i++)
			{
				if(finished) return;
				
				if(_repeatLimit != 0)
				{
					if(++_repeatTime >= _repeatLimit)
					{
						_repeatTime = 0;
						reset(false);
					}
				}
				
				if(_changeLimit != 0)
				{
					if(++_changeTime >= _changeLimit)
					{
						_changeLimit = 0;
						_period *= _changeAmount;
					}
				}
				
				_slide += _deltaSlide;
				_period = _period * _slide;
				
				if(_period > _maxPeriod)
				{
					_period = _maxPeriod;
					if(minFrequency > 0.0) finished = true;
				}
				
				_periodTemp = _period;
				
				if(_vibratoAmplitude > 0.0)
				{
					_vibratoPhase += _vibratoSpeed;
					_periodTemp = _period * (1.0 + Math.sin(_vibratoPhase) * _vibratoAmplitude);
				}
				
				_periodTemp = int(_periodTemp);
				if(_periodTemp < 8) _periodTemp = 8;
				
				_squareDuty += _dutySweep;
					 if(_squareDuty < 0.0) _squareDuty = 0.0;
				else if(_squareDuty > 0.5) _squareDuty = 0.5;
				
				if(++_envelopeTime > _envelopeLength)
				{
					_envelopeTime = 0;
					
					switch(++_envelopeStage)
					{
						case 1: _envelopeLength = _envelopeLength1; break;
						case 2: _envelopeLength = _envelopeLength2; break;
					}
				}
				
				switch(_envelopeStage)
				{
					case 0: _envelopeVolume = _envelopeTime * _envelopeOverLength0; 									break;
					case 1: _envelopeVolume = 1.0 + (1.0 - _envelopeTime * _envelopeOverLength1) * 2.0 * sustainPunch; 	break;
					case 2: _envelopeVolume = 1.0 - _envelopeTime * _envelopeOverLength2; 								break;
					case 3: _envelopeVolume = 0.0; finished = true; 													break;
				}
				
				_phaserOffset += _phaserDeltaOffset;
				_phaserInt = int(_phaserOffset);
					 if(_phaserInt < 0) 	_phaserInt = -_phaserInt;
				else if(_phaserInt > 1023) 	_phaserInt = 1023;
				
				if(_hpFilterDeltaCutoff != 0.0)
				{
					_hpFilterCutoff *- _hpFilterDeltaCutoff;
						 if(_hpFilterCutoff < 0.00001) 	_hpFilterCutoff = 0.00001;
					else if(_hpFilterCutoff > 0.1) 		_hpFilterCutoff = 0.1;
				}
				
				_superSample = 0.0;
				for(var j:int = 0; j < 8; j++)
				{
					_sample = 0.0;
					_phase++;
					if(_phase >= _periodTemp)
					{
						_phase = _phase % _periodTemp;
						if(waveType == 3) 
						{ 
							for(var n:uint = 0; n < 32; n++) _noiseBuffer[n] = Math.random() * 2.0 - 1.0;
						}
					}
					
					_pos = Number(_phase) / _periodTemp;
					
					switch(waveType)
					{
						case 0: _sample = (_pos < _squareDuty) ? 0.5 : -0.5; 					break;
						case 1: _sample = 1.0 - _pos * 2.0;										break;
						case 2: _sample = Math.sin(_pos * Math.PI * 2.0);						break;
						case 3: _sample = _noiseBuffer[uint(_phase * 32 / int(_periodTemp))];	break;
					}
					
					_lpFilterOldPos = _lpFilterPos;
					_lpFilterCutoff *= _lpFilterDeltaCutoff;
						 if(_lpFilterCutoff < 0.0) _lpFilterCutoff = 0.0;
					else if(_lpFilterCutoff > 0.1) _lpFilterCutoff = 0.1;
					
					if(lpFilterCutoff != 1.0)
					{
						_lpFilterDeltaPos += (_sample - _lpFilterPos) * _lpFilterCutoff * 4;
						_lpFilterDeltaPos -= _lpFilterDeltaPos * _lpFilterDamping;
					}
					else
					{
						_lpFilterPos = _sample;
						_lpFilterDeltaPos = 0.0;
					}
					
					_lpFilterPos += _lpFilterDeltaPos;
					
					_hpFilterPos += _lpFilterPos - _lpFilterOldPos;
					_hpFilterPos -= _hpFilterPos * _lpFilterCutoff;
					_sample = _hpFilterPos;
					
					_phaserBuffer[_phaserPos&1023] = _sample;
					_sample += _phaserBuffer[(_phaserPos - _phaserInt + 1024) & 1023];
					_phaserPos = (_phaserPos + 1) & 1023;
					
					_superSample += _sample;
				}
				
				_superSample = masterVolume * _envelopeVolume * _superSample / 8.0;
				
				if(_superSample > 1.0) 	_superSample = 1.0;
				if(_superSample < -1.0) _superSample = -1.0;
				
				if(preview)
				{
					buffer.writeFloat(_superSample);
					buffer.writeFloat(_superSample);
				}
				else
				{
					_bufferSample += _superSample;
				
					_sampleCount++;
					
					if(sampleRate == 44100 || _sampleCount == 2)
					{
						_bufferSample /= _sampleCount;
						_sampleCount = 0;
						
						if(bitDepth == 16) 	buffer.writeShort(int(32000.0 * _bufferSample));
						else 				buffer.writeByte(_bufferSample * 127 + 128);
						
						_bufferSample = 0.0;
					}
				}
			}
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Generation Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Sets the parameters to generate a pickup/coin sound
		 */
		public function generatePickupCoin():void
		{
			resetParams();
			
			startFrequency = 0.4 + Math.random() * 0.5;
			
			sustainTime = Math.random() * 0.1;
			decayTime = 0.1 + Math.random() * 0.4;
			sustainPunch = 0.3 + Math.random() * 0.3;
			
			if(Math.random() < 0.5) 
			{
				changeSpeed = 0.5 + Math.random() * 0.2;
				changeAmount = 0.2 + Math.random() * 0.4;
			}
		}
		
		/**
		 * Sets the parameters to generate a laser/shoot sound
		 */
		public function generateLaserShoot():void
		{
			resetParams();
			
			waveType = uint(Math.random() * 3);
			if(waveType == 2 && Math.random() < 0.5) waveType = uint(Math.random() * 2);
			
			startFrequency = 0.5 + Math.random() * 0.5;
			minFrequency = startFrequency - 0.2 - Math.random() * 0.6;
			if(minFrequency < 0.2) minFrequency = 0.2;
			
			slide = -0.15 - Math.random() * 0.2;
			
			if(Math.random() < 0.33)
			{
				startFrequency = 0.3 + Math.random() * 0.6;
				minFrequency = Math.random() * 0.1;
				slide = -0.35 - Math.random() * 0.3;
			}
			
			if(Math.random() < 0.5) 
			{
				squareDuty = Math.random() * 0.5;
				dutySweep = Math.random() * 0.2;
			}
			else
			{
				squareDuty = 0.4 + Math.random() * 0.5;
				dutySweep =- Math.random() * 0.7;	
			}
			
			sustainTime = 0.1 + Math.random() * 0.2;
			decayTime = Math.random() * 0.4;
			if(Math.random() < 0.5) sustainPunch = Math.random() * 0.3;
			
			if(Math.random() < 0.33)
			{
				phaserOffset = Math.random() * 0.2;
				phaserSweep = -Math.random() * 0.2;
			}
			
			if(Math.random() < 0.5) hpFilterCutoff = Math.random() * 0.3;
		}
		
		/**
		 * Sets the parameters to generate an explosion sound
		 */
		public function generateExplosion():void
		{
			resetParams();
			waveType = 3;
			
			if(Math.random() < 0.5)
			{
				startFrequency = 0.1 + Math.random() * 0.4;
				slide = -0.1 + Math.random() * 0.4;
			}
			else
			{
				startFrequency = 0.2 + Math.random() * 0.7;
				slide = -0.2 - Math.random() * 0.2;
			}
			
			startFrequency *= startFrequency;
			
			if(Math.random() < 0.2) slide = 0.0;
			if(Math.random() < 0.33) repeatSpeed = 0.3 + Math.random() * 0.5;
			
			sustainTime = 0.1 + Math.random() * 0.3;
			decayTime = Math.random() * 0.5;
			sustainPunch = 0.2 + Math.random() * 0.6;
			
			if(Math.random() < 0.5)
			{
				phaserOffset = -0.3 + Math.random() * 0.9;
				phaserSweep = -Math.random() * 0.3;
			}
			
			if(Math.random() < 0.33)
			{
				changeSpeed = 0.6 + Math.random() * 0.3;
				changeAmount = 0.8 - Math.random() * 1.6;
			}
		}
		
		/**
		 * Sets the parameters to generate a powerup sound
		 */
		public function generatePowerup():void
		{
			resetParams();
			
			if(Math.random() < 0.5) waveType = 1;
			else 					squareDuty = Math.random() * 0.6;
			
			if(Math.random() < 0.5)
			{
				startFrequency = 0.2 + Math.random() * 0.3;
				slide = 0.1 + Math.random() * 0.4;
				repeatSpeed = 0.4 + Math.random() * 0.4;
			}
			else
			{
				startFrequency = 0.2 + Math.random() * 0.3;
				slide = 0.05 + Math.random() * 0.2;
				
				if(Math.random() < 0.5)
				{
					vibratoDepth = Math.random() * 0.7;
					vibratoSpeed = Math.random() * 0.6;
				}
			}
			
			sustainTime = Math.random() * 0.4;
			decayTime = 0.1 + Math.random() * 0.4;
		}
		
		/**
		 * Sets the parameters to generate a hit/hurt sound
		 */
		public function generateHitHurt():void
		{
			resetParams();
			waveType = uint(Math.random() * 3);
			if(waveType == 2) waveType = 3;
			else if(waveType == 0) squareDuty = Math.random() * 0.6;
			
			startFrequency = 0.2 + Math.random() * 0.6;
			slide = -0.3 - Math.random() * 0.4;
			
			sustainTime = Math.random() * 0.1;
			decayTime = 0.1 + Math.random() * 0.2;
			
			if(Math.random() < 0.5) hpFilterCutoff = Math.random() * 0.3;
		}
		
		/**
		 * Sets the parameters to generate a jump sound
		 */
		public function generateJump():void
		{
			resetParams();
			
			waveType = 0;
			squareDuty = Math.random() * 0.6;
			startFrequency = 0.3 + Math.random() * 0.3;
			slide = 0.1 + Math.random() * 0.2;
			
			sustainTime = 0.1 + Math.random() * 0.3;
			decayTime = 0.1 + Math.random() * 0.2;
			
			if(Math.random() < 0.5) hpFilterCutoff = Math.random() * 0.3;
			if(Math.random() < 0.5) lpFilterCutoff = 1.0 - Math.random() * 0.6;
		}
		
		/**
		 * Sets the parameters to generate a blip/select sound
		 */
		public function generateBlipSelect():void
		{
			resetParams();
			
			waveType = uint(Math.random() * 2);
			if(waveType == 0) squareDuty = Math.random() * 0.6;
			
			startFrequency = 0.2 + Math.random() * 0.4;
			
			sustainTime = 0.1 + Math.random() * 0.1;
			decayTime = Math.random() * 0.2;
			hpFilterCutoff = 0.1;
		}
		
		/**
		 * Resets the parameters, used at the start of each generate function
		 */
		protected function resetParams():void
		{
			waveType = 0;
			startFrequency = 0.3;
			minFrequency = 0.0;
			slide = 0.0;
			deltaSlide = 0.0;
			squareDuty = 0.0;
			dutySweep = 0.0;
			
			vibratoDepth = 0.0;
			vibratoSpeed = 0.0;
			
			attackTime = 0.0;
			sustainTime = 0.3;
			decayTime = 0.4;
			sustainPunch = 0.0;
			
			lpFilterResonance = 0.0;
			lpFilterCutoff = 1.0;
			lpFilterCutoffSweep = 0.0;
			hpFilterCutoff = 0.0;
			hpFilterCutoffSweep = 0.0;
			
			phaserOffset = 0.0;
			phaserSweep = 0.0;
			
			repeatSpeed = 0.0;
			
			changeSpeed = 0.0;
			changeAmount = 0.0;
		}
		
		/**
		 * Randomly adjusts the parameters ever so slightly
		 */
		public function mutate():void
		{
			if(Math.random() < 0.5) startFrequency += 		Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) minFrequency += 		Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) slide += 				Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) deltaSlide += 			Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) squareDuty += 			Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) dutySweep += 			Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) vibratoDepth += 		Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) vibratoSpeed += 		Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) attackTime += 			Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) sustainTime += 			Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) decayTime += 			Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) sustainPunch += 		Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) lpFilterCutoff += 		Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) lpFilterCutoffSweep += 	Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) lpFilterResonance += 	Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) hpFilterCutoff += 		Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) hpFilterCutoffSweep += 	Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) phaserOffset += 		Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) phaserSweep += 			Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) repeatSpeed += 			Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) changeSpeed += 			Math.random() * 0.1 - 0.05;
			if(Math.random() < 0.5) changeAmount += 		Math.random() * 0.1 - 0.05;
		}
		
		/**
		 * Sets all parameters to random values
		 */
		public function randomize():void
		{
			waveType = uint(Math.random() * 4);
			
			attackTime =  			pow(Math.random()*2-1, 4);
			sustainTime =  			pow(Math.random()*2-1, 2);
			sustainPunch =  		pow(Math.random()*0.8, 2);
			decayTime =  			Math.random();

			startFrequency =  		(Math.random() < 0.5) ? pow(Math.random()*2-1, 2) : (pow(Math.random() * 0.5, 3) + 0.5);
			minFrequency =  		0.0;
			
			slide =  				pow(Math.random()*2-1, 5);
			deltaSlide =  			pow(Math.random()*2-1, 3);
			
			vibratoDepth =  		pow(Math.random()*2-1, 3);
			vibratoSpeed =  		Math.random()*2-1;
			
			changeAmount =  		Math.random()*2-1;
			changeSpeed =  			Math.random()*2-1;
			
			squareDuty =  			Math.random()*2-1;
			dutySweep =  			pow(Math.random()*2-1, 3);
			
			repeatSpeed =  			Math.random()*2-1;
			
			phaserOffset =  		pow(Math.random()*2-1, 3);
			phaserSweep =  			pow(Math.random()*2-1, 3);
			
			lpFilterCutoff =  		1 - pow(Math.random(), 3);
			lpFilterCutoffSweep =  	pow(Math.random()*2-1, 3);
			lpFilterResonance =  	Math.random()*2-1;
			
			hpFilterCutoff =  		pow(Math.random(), 5);
			hpFilterCutoffSweep =  	pow(Math.random()*2-1, 5);
			
			if(attackTime + sustainTime + decayTime < 0.2)
			{
				sustainTime = 0.2 + Math.random() * 0.3;
				decayTime = 0.2 + Math.random() * 0.3;
			}
			
			if((startFrequency > 0.7 && slide > 0.2) || (startFrequency < 0.2 && slide < -0.05)) 
			{
				slide = -slide;
			}
			
			if(lpFilterCutoff < 0.1 && lpFilterCutoffSweep < -0.05) 
			{
				lpFilterCutoffSweep = -lpFilterCutoffSweep;
			}
		}
		
		/**
		 * Quick power function
		 * @param	base		Base to raise to power
		 * @param	power		Power to raise base by
		 * @return				The calculated power
		 */
		private function pow(base:Number, power:int):Number
		{
			switch(power)
			{
				case 2: return base*base;
				case 3: return base*base*base;
				case 4: return base*base*base*base;
				case 5: return base*base*base*base*base;
			}
			
			return 1.0;
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Settings String Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Returns a string representation of the parameters for copy/paste sharing
		 * @return	A comma-delimited list of parameter values
		 */
		public function getSettingsString():String
		{
			var string:String = String(waveType);
			string += "," + to3DP(attackTime);
			string += "," + to3DP(sustainTime);
			string += "," + to3DP(sustainPunch);
			string += "," + to3DP(decayTime);
			string += "," + to3DP(startFrequency);
			string += "," + to3DP(minFrequency);
			string += "," + to3DP(slide);
			string += "," + to3DP(deltaSlide);
			string += "," + to3DP(vibratoDepth);
			string += "," + to3DP(vibratoSpeed);
			string += "," + to3DP(changeAmount);
			string += "," + to3DP(changeSpeed);
			string += "," + to3DP(squareDuty);
			string += "," + to3DP(dutySweep);
			string += "," + to3DP(repeatSpeed);
			string += "," + to3DP(phaserOffset);
			string += "," + to3DP(phaserSweep);
			string += "," + to3DP(lpFilterCutoff);
			string += "," + to3DP(lpFilterCutoffSweep);
			string += "," + to3DP(lpFilterResonance);
			string += "," + to3DP(hpFilterCutoff);
			string += "," + to3DP(hpFilterCutoffSweep);
			string += "," + to3DP(masterVolume);		
			
			return string;
		}
		
		/**
		 * Returns the number as a string to 3 decimal places
		 * @param	value	Number to convert
		 * @return			Number to 3dp as a string
		 */
		private function to3DP(value:Number):String
		{
			var string:String = String(value);
			var split:Array = string.split(".");
			if (split.length == 1) 	return string;
			else 					return split[0] + "." + split[1].substr(0, 3);
		}
		
		/**
		 * Parses a settings string into the parameters
		 * @param	string	Settings string to parse
		 * @return			If the string successfully parsed
		 */
		public function setSettingsString(string:String):Boolean
		{
			var values:Array = string.split(",");
			
			if (values.length != 24) return false;
			
			waveType = 				uint(values[0]) || 0;
			attackTime =  			Number(values[1]) || 0;
			sustainTime =  			Number(values[2]) || 0;
			sustainPunch =  		Number(values[3]) || 0;
			decayTime =  			Number(values[4]) || 0;
			startFrequency =  		Number(values[5]) || 0;
			minFrequency =  		Number(values[6]) || 0;
			slide =  				Number(values[7]) || 0;
			deltaSlide =  			Number(values[8]) || 0;
			vibratoDepth =  		Number(values[9]) || 0;
			vibratoSpeed =  		Number(values[10]) || 0;
			changeAmount =  		Number(values[11]) || 0;
			changeSpeed =  			Number(values[12]) || 0;
			squareDuty =  			Number(values[13]) || 0;
			dutySweep =  			Number(values[14]) || 0;
			repeatSpeed =  			Number(values[15]) || 0;
			phaserOffset =  		Number(values[16]) || 0;
			phaserSweep =  			Number(values[17]) || 0;
			lpFilterCutoff =  		Number(values[18]) || 0;
			lpFilterCutoffSweep =  	Number(values[19]) || 0;
			lpFilterResonance =  	Number(values[20]) || 0;
			hpFilterCutoff =  		Number(values[21]) || 0;
			hpFilterCutoffSweep =  	Number(values[22]) || 0;
			masterVolume = 			Number(values[23]) || 0;
			
			return true;
		}   
		
		//--------------------------------------------------------------------------
		//	
		//  Settings File Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Writes the current parameters to a ByteArray and returns it
		 * Compatible with the original Sfxr files
		 * @return	ByteArray of settings data
		 */
		public function getSettingsFile():ByteArray
		{
			var file:ByteArray = new ByteArray();
			file.endian = Endian.LITTLE_ENDIAN;
			
			file.writeInt(102);
			file.writeInt(waveType);
			file.writeFloat(masterVolume);
			
			file.writeFloat(startFrequency);
			file.writeFloat(minFrequency);
			file.writeFloat(slide);
			file.writeFloat(deltaSlide);
			file.writeFloat(squareDuty);
			file.writeFloat(dutySweep);
			
			file.writeFloat(vibratoDepth);
			file.writeFloat(vibratoSpeed);
			file.writeFloat(0);
			
			file.writeFloat(attackTime);
			file.writeFloat(sustainTime);
			file.writeFloat(decayTime);
			file.writeFloat(sustainPunch);
			
			file.writeBoolean(false);
			file.writeFloat(lpFilterResonance);
			file.writeFloat(lpFilterCutoff);
			file.writeFloat(lpFilterCutoffSweep);
			file.writeFloat(hpFilterCutoff);
			file.writeFloat(hpFilterCutoffSweep);
			
			file.writeFloat(phaserOffset);
			file.writeFloat(phaserSweep);
			
			file.writeFloat(repeatSpeed);
			
			file.writeFloat(changeSpeed);
			file.writeFloat(changeAmount);
			
			return file;
		}
		
		/**
		 * Reads parameters from a ByteArray file
		 * Compatible with the original Sfxr files
		 * @param	file	ByteArray of settings data
		 */
		public function setSettingsFile(file:ByteArray):void
		{
			file.position = 0;
			file.endian = Endian.LITTLE_ENDIAN;
			
			var version:int = file.readInt();
			
			if(version != 100 && version != 101 && version != 102) return;
			
			waveType = file.readInt();
			masterVolume = (version == 102) ? file.readFloat() : 0.5;
			
			startFrequency = file.readFloat();
			minFrequency = file.readFloat();
			slide = file.readFloat();
			deltaSlide = (version >= 101) ? file.readFloat() : 0.0;
			
			squareDuty = file.readFloat();
			dutySweep = file.readFloat();
			
			vibratoDepth = file.readFloat();
			vibratoSpeed = file.readFloat();
			var unusedVibratoDelay:Number = file.readFloat();
			
			attackTime = file.readFloat();
			sustainTime = file.readFloat();
			decayTime = file.readFloat();
			sustainPunch = file.readFloat();
			
			var unusedFilterOn:Boolean = file.readBoolean();
			lpFilterResonance = file.readFloat();
			lpFilterCutoff = file.readFloat();
			lpFilterCutoffSweep = file.readFloat();
			hpFilterCutoff = file.readFloat();
			hpFilterCutoffSweep = file.readFloat();
			
			phaserOffset = file.readFloat();
			phaserSweep = file.readFloat();
			
			repeatSpeed = file.readFloat();
			
			changeSpeed = (version >= 101) ? file.readFloat() : 0.0;
			changeAmount = (version >= 101) ? file.readFloat() : 0.0;
		}
	}
}