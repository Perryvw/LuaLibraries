LuaLibraries
============

Some useful lua libraries for Dota 2 addons.

Currently available libraries:
- PseudoRNG - A library implementing random number generators using a pseudo-random distribution. For more details see http://dota2.gamepedia.com/Pseudo-random_distribution.
- AttachManager - Provides a way of *reliably* attaching models to unit attachments.
- MotionControllers - A small library providing a nice interface for prioritising modifiers that perform a motion. Useful when you need some modifiers' motion to be prioritised over others.
- OrderFilter - A hack that helps when creating libraries that require SetExecuteOrderFilter. Overwrites the default SetExecuteOrderFilter to allow for multiple calls with different filtering functions. (Should not be required BEFORE addon_game_mode.lua Activate())
- API-JSONDumper - Dumps an object to the JSON format, can be used to dump the dota lua API by dumping _G.

Detailed documentation for each library can be found in the library file.

You can use these libraries by requiring them.
To use PseudoRNG.lua for example, in addon_game_mode.lua add 'require("PseudoRNG")'
