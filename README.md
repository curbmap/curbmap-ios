# curbmap iOS application
Changes 1-12-18 -> 1-14-18
* Noticed a little problem that prevented sending lines that were in Realm from sending when you got on wifi (I misspelled application in application/json ;-( )
* Stuff is working smoother in general.
* Lines can now have up to 4 points, but can be sent with just 2 like before. This helps with curvy streets
* Still need to have a little counter on the add restrictions for a line section.
* Still need to clean up that interface to make it kind of fun to add restrictions (open to suggestions!)

Changes 1-1-18 -> 1-12-18
* Cleaned up interface
* Added the option to take a photo or use a photo from the library and place the photo at some exact position on the map, then upload it (or in fact, only upload it when you're on wifi since uploading 6+ MB every time is silly. We'll handle it in the background in bulk when you start the app and youre on wifi.)
* Add a line not just a photo. This is the more "detailed" and helpful approach to getting real restrictions from users. Add multiple restrictions for each line you create (say the street is no parking 8-10am Mondays, and 2 hour parking other times. You can add these two... just click add another).
* Just like photos, your lines will only be uploaded on wifi, unless you have offline set to off in settings.
* A new view to choose whether you're adding a line or photo instead of alerts now.
* Testing version 0.3 around LA. If you want to get in on that build, email me your itunes email address.

Changes 12-29-17 -> 1-1-18
* Login and Signup are working
* Signup still needs to learn how to tell you that you're not doing something right
* Timer now works with User Notifications and everthing works there. Even if you close the app and reopen it... or leave it closed.
* Settings are now correct, sort of, I still have to figure out how offline settings will work.
* We now use some reactive monitoring for the User Notfications care of RxSwift and RxCocoa.

Changes: 12-28-17 -> 12-29-17
* After you take a photo, position it's marker exactly where you took it!
* Buttons are still getting screwed up by constraints
* Timers are now going to use UserNotifications (i.e. local notifications and can play sounds and vibrate your phone... though mine never seems to vibrate and only plays sounds if it's not muted... unlike a real alarm)
* Some things are now being written using RxSwift... which I like, but Rx anything can be annoying to get right.

Changes: initial->12-28-17
* Currently the map is user configurable with two options from MapBox maps (derivative of Open Street Maps and MapBox).
    * The themes are Dark (default)
    * And Light
* Menus appear in screen as partial overlays
* Menus update for login/logout
* Photo gets heading and OLC and submits to Curbmap's API for later ML processing
* Using curbmap's OLC implementation
