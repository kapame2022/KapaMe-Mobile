# Trip messaging integration

The mobile app uses the signed-in user's bearer token for REST and SignalR.

- Inbox history: `GET /api/tripmessages/senders/{currentUserId}`. The updated API returns messages where the user is either sender or receiver. The client accepts the previous grouped arrays too.
- Trip history: `GET /api/tripmessages/{tripId}`. Map chats show only that trip and the selected pair of users.
- Send: `POST /api/tripmessages` with `tripId`, `sender`, `receiver`, and `message`. Displayed messages use the ID and UTC timestamp returned by the server.
- Hub: `https://kapameapi.azurewebsites.net/tripmessage`. The client listens for `ReceiveMessage`, automatically reconnects, rejoins watched trips with `JoinGroup`, and refreshes history to recover missed events.
- The updated POST action broadcasts `ReceiveMessage` to both authenticated users using `Clients.Users`. This also delivers a first incoming message before the recipient has opened the trip. The JWT NameIdentifier claim must match the sender/receiver IDs.

The inbox groups by the other person's ID, shows their latest message, and opens the history with that person across trips. A reply from the inbox uses the latest trip when that conversation was opened. Map links pass the selected `Trip` as the `/chat` route argument. Person names come from the included trip: `requesterName` and `transporterName` are matched to the other person’s user ID. The existing `senderName` and `receiverName` fields remain fallbacks for contacts not assigned to that trip. These are display-only model properties and require no database migration. Conversations where the signed-in user is only the receiver are included even before they send a reply. Read/unread indicators are local to the open inbox session, not server read receipts.

## Deployment

Changes in the sibling `KapaMe-API` project must be published to Azure:

- `Backend/KapaMe/KapaMe.API/Controllers/TripMessagesController.cs`
- `Backend/KapaMe/KapaMe.Data/Models/TripMessage.cs`
- `Backend/KapaMe/KapaMe.API/Controllers/TripsController.cs`
- `Backend/KapaMe/KapaMe.Data/Models/Trip.cs`

These changes add received-message history, populate person names, require a receiver on sends, and broadcast saved messages. The mobile changes do not deploy the API. Without the updated backend, the older endpoint may omit incoming conversations and REST sends do not broadcast live updates.

Restart the Flutter app after installing dependencies. To validate the deployed feature, use two test accounts: open a trip conversation, send and reply, check one inbox row per person, then disconnect/reconnect one client and verify missed messages return without duplicates. No live messages were sent during automated verification.

Focused checks:

```sh
flutter test test/chat_test.dart test/trip_chat_controller_test.dart
```
