BarbarZig
=========

A simple roguelike game written in Zig.
This is a learning project intended to fool around with both a new language and
some lower level programming.

Goals:
------

- Separation of game logic and rendering

  Actual game is written as a library to be used (hopefully) any graphic client,
  possibly via a server.

  Currently a client needs to import the game as a zig package to interact with 
  it, but said interaction can be limited to a single entry point and a few 
  imports (needed for type checking).

  Ideally we should add some serpilization format as well as a simple application
  server so that clients can be written in any language.

- Pseudo ECS architecture

  I'm not aiming for a "proper" ECS systems (ie with cache friendly contiguous
  component storage) as this feels overkill for a simple turn based game.

  Instead focusing on the composable aspect of it, in which game entities are 
  defined exclusively by their associated components.

- Data driven

  Try and define as much game data as possible through data files.

- Random experimentation!

Roadmap
-------

Currently this is little more than basic scaffolding.
Immediate plans are:

- More scaffolding:

    - Proper game state serialization (json)
    - Simple server application
    - Better defined application protocol

- Some actual game logic:

    - Simple combat system
    - Ability to change levels
    - Proper(ish) map generation
    - ...
