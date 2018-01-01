# curbmap iOS application
Changes 12-29-17 -> 1-1-18
1. Login and Signup are working
2. Signup still needs to learn how to tell you that you're not doing something right
3. Timer now works with User Notifications and everthing works there. Even if you close the app and reopen it... or leave it closed.
4. Settings are now correct, sort of, I still have to figure out how offline settings will work.
5. We now use some reactive monitoring for the User Notfications care of RxSwift and RxCocoa.

Changes: 12-28-17 -> 12-29-17
1. After you take a photo, position it's marker exactly where you took it!
2. Buttons are still getting screwed up by constraints
3. Timers are now going to use UserNotifications (i.e. local notifications and can play sounds and vibrate your phone... though mine never seems to vibrate and only plays sounds if it's not muted... unlike a real alarm)
4. Some things are now being written using RxSwift... which I like, but Rx anything can be annoying to get right.

Changes: initial->12-28-17
1. Currently the map is user configurable with two options from MapBox maps (derivative of Open Street Maps and MapBox). 
  1. The themes are Dark (default)
  2. And Light
2. Menus appear in screen as partial overlays
3. Menus update for login/logout
4. Photo gets heading and OLC and submits to Curbmap's API for later ML processing
5. Using curbmap's OLC implementation
