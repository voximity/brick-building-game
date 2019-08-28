# brick-building-game

This repository contains the source code for my brick builder, [Brick Building Game](https://www.roblox.com/games/2993087806/Brick-Building-Game).
I worked on it for a week, the spring break of 2019. It has intuitive building mechanics and is roughly based on Blockland.

If this project is interesting to you, please take a look at [Brickadia](https://brickadia.com/).

This code is albeit better than my [FPS source](https://github.com/voximity/extract), still not the greatest. It is quickly written (a lot of it is written
in under 48 hours) and isn't the most readable at times.

## Structure

### Client

Contains all code for managing building, removing, painting, rendering, etc.

### Server

Contains replication code for mirroring client changes to other clients.

### Shared

Contains some shared code that is used between the client and server.

### Not included

Not included is the source to the work-in-progress-ish eventing system. When it is complete and functional, it will be added to this repo.

## Contributing

I may work on this game again in the future, but I am not accepting contributions to this repository. Feel free to fork and use as you like.