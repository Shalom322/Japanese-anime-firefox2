// japanese-anime-firefox - user.js
// Applied on every Firefox start. To change one of these values permanently,
// edit or delete the line here, otherwise Firefox resets it on next launch.

// Allow chrome/userChrome.css and chrome/userContent.css to load (required).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Native vertical tabs on the left (replaces the horizontal tab strip).
user_pref("sidebar.revamp", true);
user_pref("sidebar.verticalTabs", true);

// Collapsed icon rail that expands when the mouse hovers over it.
user_pref("sidebar.visibility", "expand-on-hover");

// Optional: clean New Tab page (logo + search box over the wallpaper).
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
