# curbmap iOS application
Changes 1-1-18 -> 1-12-18
1. Cleaned up interface
2. Added the option to take a photo or use a photo from the library and place the photo at some exact position on the map, then upload it (or in fact, only upload it when you're on wifi since uploading 6+ MB every time is silly. We'll handle it in the background in bulk when you start the app and youre on wifi.)
3. Add a line not just a photo. This is the more "detailed" and helpful approach to getting real restrictions from users. Add multiple restrictions for each line you create (say the street is no parking 8-10am Mondays, and 2 hour parking other times. You can add these two... just click add another).
4. Just like photos, your lines will only be uploaded on wifi, unless you have offline set to off in settings.
5. A new view to choose whether you're adding a line or photo instead of alerts now.
6. Testing version 0.3 around LA. If you want to get in on that build, email me your itunes email address.

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
