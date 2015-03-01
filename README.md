## **The Game of Chairs** 
######Social Proximity and Indoor Location mixed together. Powered by Estimote and Alljoyn.


####Description

The Game of Chairs is the evolution of the famous Musical Chairs, but instead of chairs you have Estimote Beacons.

Before starting to play, you choose to *host* the game and then *start* the game with a number (*N*) of players you want to play with. The *host* player runs and supervises the Alljoyn bus, thanks to which players can see eachother moving around inside the location map, with a profile image, and sending *messages* or *signals* telling that a specific event is occured.

The first turn starts when *N* players has joined the game (included the *host* player) and randomly activates *N-1* beacons, called *stations*, located on the walls. If a *station* is graphically represented with a X on it, means that that *station* is not active throughout the turn. When all the players has reached the centre of the location map, a sound is heard and the race begins: players have to reach one *station* as fast as they can in order to pass the turn. When a player reaches a *station* a message is sent on the Alljoyn bus and if it's active and free then it becomes *taken* and that player will see a green light surrounding the taken *station*, while the others will see a red light instead, meaning that the *station* is no more available. When all the *stations* are taken the *host* launches the *end turn* event, and the one player who has not been able to *take* any *station* is excluded from the next turn and he won't be visible on the location map anymore (if the *host* player loses the game he has to phisically remain on the field). 

The last player left on the map is the winner, then the game is over.

Enjoy!

####Screenshots

######The start screen

<img src="https://lh4.googleusercontent.com/-HYeFi_53jvk/VPMDCtZwGqI/AAAAAAAAAGo/yeXME6OoEk8/w654-h1164-no/iOS%2BSimulator%2BScreen%2BShot%2B01.mar.2015%2B12.55.31.png" width="375px" height="667px"/> 

######Here you can create a the indoor location map of your room

<img src="https://lh6.googleusercontent.com/-rOodEybj2QE/VPMDGqToI4I/AAAAAAAAAG8/H-zTdbylIqY/w654-h1164-no/iOS%2BSimulator%2BScreen%2BShot%2B01.mar.2015%2B12.55.43.png" width="375px" height="667px"/> 

######When a turn starts all the players are in centre of the room waiting for the start sound

<img src="https://lh6.googleusercontent.com/-t0goZodQII8/VPMDCWkLUgI/AAAAAAAAAGk/rI8QIYTqecw/w654-h1164-no/iOS%2BSimulator%2BScreen%2BShot%2B01.mar.2015%2B12.55.08.png" width="375px" height="667px"/> 

######Each player has to run faster as possible near an avaliable station

<img src="https://lh3.googleusercontent.com/-_eWVrdMHnlk/VPMDCw12WcI/AAAAAAAAAGs/jq_a8BpOiE0/w654-h1164-no/iOS%2BSimulator%2BScreen%2BShot%2B01.mar.2015%2B12.48.58.png" width="375px" height="667px"/> 

######The last player left wins the game

<img src="https://lh3.googleusercontent.com/-rJEmWDtIuMY/VPMDG6NAsVI/AAAAAAAAAG4/fVFi-R1HTSo/w654-h1164-no/iOS%2BSimulator%2BScreen%2BShot%2B01.mar.2015%2B13.02.07.png" width="375px" height="667px"/> 


######Created by *Silvia Promontorio*
