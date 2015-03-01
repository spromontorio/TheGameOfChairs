## **The Game of Chairs** ##

#### Social Proximity and Indoor Location mixed together.####
#### Powered by Estimote and Alljoyn ####
The Game of Chairs is the evolution of the famous Musical Chairs, but instead of chairs you have Estimote Beacons.
Before starting to play, you choose to *host* the game and then *start* the game with a number (*N*) of players you want to play with. The *host* player runs and supervises the Alljoyn bus, thanks to which players can see eachother moving around the location map, with a profile image, and sending *messages* or *signals* telling that a specific event is occured.
The first turn starts when *N* players has joined the game (included the *host* player) and randomly activates *N-1* beacons, called *stations*, located on the walls. If a *station* is graphically represented with a X on it, means that *station* is not active throughout the turn. When all the players has reached the centre of the location map, a sound is heard and the race begins: players have to reach one *station* as fast as they can in order to pass the turn. When a player reaches a *station* a message is sent on the Alljoyn bus and if it's active and free then it becomes *taken* and that player will see a green light surrounding the taken *station*, while the others will see a red light instead, meaning that the *station* is no more available. When all the *stations* are taken the *host* launches the *end turn* event, and the one player who has not been able to *take* any *station* is excluded from the next turn and he won't be visible on the location map anymore (if the *host* player loses the game he has to phisically remain on the field). The last player left on the map is the winner, then the game is over.



####Created by *Silvia Promontorio*####
