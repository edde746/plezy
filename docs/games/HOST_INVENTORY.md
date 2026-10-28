# One library, several gaming computers

PlezyNG merges games by Steam AppID, never by title. Your Steambox, desktop
and BC250 can have different installed games and different Steam library
drives. The same AppID appears once, with separate routes and installation
snapshots for each computer. A GameStream application ID is **not** a Steam
AppID; only an explicit `steamAppId` mapping joins the two transports.

## Connect installed libraries

1. On each computer, enable Games for the active PlezyNG profile. Under Games,
   enable **Share installed Steam games** and the existing Companion Remote
   server. Sharing is off by default, independent of device streaming pairing.
2. PlezyNG detects conventional Linux/SteamOS, Windows and macOS Steam roots.
   Choose **Steam installation folder** for a nonstandard installation. The
   reader follows Steam's `steamapps/libraryfolders.vdf` to other local drives.
3. On the viewing device, pair with that computer through Companion Remote.
   In Games, add its Steam streaming connection, then choose **Import installed
   games** from that computer's menu. Confirm that the paired companion and
   selected streaming computer are the same machine.
4. Repeat for the other computers. Their snapshots remain together in the
   profile. Use **Installed** and the computer chips to filter the same grid.

Steam account linking is optional for this flow. OpenID imports the account's
visible catalog; it does not enumerate installed games on each computer.
Different Steam library drives on one computer are aggregated into that
computer's single route. Disk paths and account credentials stay on the host.

## What the states mean

| Evidence | What it establishes | What it does not establish |
| --- | --- | --- |
| Steam account catalog | Steam reports the game in the visible catalog | Installation, family-copy availability, streaming access |
| Installed snapshot | The host manifest reports fully installed at the shown time | Current reachability, a working decoder, entitlement |
| Partial scan | Some readable manifests were found | That an unseen game was uninstalled |
| Saved computer | A profile knows the connection | Pairing or online state |
| First frame | An embedded session received/rendered video | Cloud-save synchronization or permission to quit the host game |

Manifest state is a hint from the local Steam installation. Steam remains the
authority when launching, installing, resolving cloud conflicts and checking
family-copy availability. Favorite state belongs to the game, not a computer.
A successful route is remembered; a route reported absent is not automatically
preferred over an installed route. Multiple suitable computers open a chooser.

## Protocol and security

The `gameInventory` command is **appended** to `RemoteCommandType`; older numeric
command indices do not move. `deviceInfo.gameInventoryVersion == 1` is required
before a new client requests a snapshot. Old peers remain valid remotes.
The extension rides the existing paired AES-GCM companion transport and opens
no additional network listener. Profile changes or disconnects retire pending
transactions. Sharing is checked again during scans and before each response.

Each transaction has a random 128-bit request identifier, ordered pages of at
most 50 rows, a 2,000-game limit and a 25-second client deadline. The host permits
one scan at a time with a 15-second read interval. Invalid ordering, duplicate
AppIDs, wrong request IDs, excessive counts and malformed metadata cannot
publish a snapshot. A profile pins the imported snapshot to the authenticated
companion identity; changing that association requires forgetting the computer.

The reader accepts only local Steam roots and text manifests. It does not run
Steam commands, follow manifest symlinks, evaluate KeyValues directives, inspect
login files or accept a remote path. Individual files are bounded to 2 MiB,
nesting to 16 levels, library locations to 32 and examined directory entries to
10,000. Missing drives or malformed manifests produce a partial scan, preserving
previous information with its older observation date.

## Catalog refresh

After verified OpenID, the relay issues a random 256-bit capability scoped to
catalog reads for that SteamID. The client stores only CredentialVault
ciphertext. Refresh and revoke use an Authorization header, never a URL.
The relay stores only the digest and identity, bounds grants to 5,000, limits
refresh frequency and retires in-flight responses after revocation. Grants
expire after 30 days and are lost on relay restart. Old relays/expired grants
fall back to the existing sign-in flow. Unlink removes the local credential
even offline and attempts server revocation; an unreachable relay's grant
expires at its original deadline.

The Web API key remains server-side. Played free games are included. This
capability grants no Steam account, launch, installation, purchase or save
access. A server update is required to enable the new refresh endpoint.

## Qualification

The reader and encrypted-channel transaction have automated fixtures for
multiple drives, three computers, partial scans, malformed data, opt-in
permissions and cancellation. Real-machine installation layouts and sharing
between each OS still require device qualification. Inventory browsing on
desktop does not imply a desktop embedded decoder has been implemented.
