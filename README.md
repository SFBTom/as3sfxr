A port of sfxr from C++ to AS3, using the new sound and file capabilities of Flash Player 10.

sfxr was originally created by Tomas Pettersson: http://www.drpetter.se/project_sfxr.html

## New Features
* Asynchronous caching
* Cache-during-first-play
* Automatic cache clearing on parameter change
* Faster synthesis
* Choose from 4 different osciltors - square, saw, sine and noise. Adjust the 22 parameters to find a sound effect you like. * Then save it out as a .wav file, or save the parameter settings to load back in later and tweak the sound further.

Features 7 'generator' functions, which produce random but familiar game sounds such as pickup/coin, laser/shoot and explosion.

## as3sfxr API
You can use the SfxrSynth class in your own code to generate sfx on the fly, without the need to import .wav files. The first time a sound is played, it's synthesized live, but also cached, so that the next time it's played, it's just played out of the cache. Alternatively, pre-cache the sound at a time of your choosing to have it ready to play.

Find a sound you like using the app, copy out the settings and paste them right into your code:

var synth:SfxrSynth = new SfxrSynth();
synth.params.setSettingsString("0,,0.271,,0.18,0.395,,0.201,,,,,,0.284,,,,,0.511,,,,,0.5");

...

synth.play();
Mutations
The playMutated() method allows you to play a slightly mutated version of your sound, without losing the original settings. All the mutated sounds will therefore be based around the original sound, whereas just using the mutate() method changes the settings each time causing the sound to drift away from the original. The mutation parameter controls the size of the mutation

var synth:SfxrSynth = new SfxrSynth();
synth.params.setSettingsString("0,,0.271,,0.18,0.395,,0.201,,,,,,0.284,,,,,0.511,,,,,0.5");
setInterval(synth.playMutated, 1000, 0.05);
Caching
The caching methods cacheSound() and cacheMutations() allow you to generate the full wave whenever you like, before playing the cached wave. Reading from the wave ByteArray is a lot faster than creating the wave as it plays. If a callback function is passed in, the sound is cached asynchronously, taking a few milliseconds per frame to cache and calling the callback when it's complete. Especially useful for caching a number of mutations of long sounds.

var synth:SfxrSynth = new SfxrSynth();
synth.params.setSettingsString("0,,0.271,,0.18,0.395,,0.201,,,,,,0.284,,,,,0.511,,,,,0.5");
synth.cacheSound();

...

synth.play();
Enjoy!
