# Mandatory login behavior

- A fresh visitor without a valid PHP API bearer-token session sees the full-screen sign-in/sign-up page first.
- The Flutter Home page, bottom navigation, side navigation, destination screens, and admin dashboard are only built after authentication succeeds.
- There is no guest-browsing button.
- Successful login or registration saves the bearer token and replaces the auth page with the website.
- Sign out revokes the token through PHP when possible, clears the local token, and returns to the auth page.
- On a later browser load, a saved token is verified with `auth&action=me`; valid tokens restore the authenticated session, while invalid/expired tokens are cleared and the auth page remains visible.
- Authentication is backed by the existing PHP REST API and MySQL database; Firebase is not used.

If you need to force the login page during testing, sign out from the account menu or clear the browser's site storage for the local Flutter Web origin.
