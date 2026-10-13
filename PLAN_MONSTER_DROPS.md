# Smart Quest Completion: Monster Drops

## Overview
A technical plan to implement smart quest completion logic. By analyzing monster drop packet metadata, the system can determine quest objectives (`questObjective`) and quest id requirements (`sReqQuests`) for specific targets.

---

## 1. Request Packet

```text
%xt%zm%getMonsterDrops%120439%1%
```

### Parameter Breakdown
* **`120439`**: `areaId`
* **`1`**: `monMapId` (Unique monster instance identifier on the map)

---

## 2. Drop Item Summary

| Item ID | Item Name | Type | Temp | Stack | Req Quest ID | Quest Name / Objective |
| :---: | :--- | :---: | :---: | :---: | :---: | :--- |
| **1564** | Basilisk's tail | Quest Item | Yes | 1 | `314` | Terrifying Reptile |
| **1580** | Black Knight Arm Piece | Quest Item | Yes | 1 | `318` | Hardly Suiting Armor |
| **5193** | Size S Finger | Quest Item | Yes | 1 | `700` | The Ring's The Thing |
| **7064** | GreenGuard Basilisk Scale | Quest Item | Yes | 3 | `964` | After a While… |
| **7462** | Basketful of Dyed Eggs | Item | No | 4 | *N/A* | *(None - Merge Item)* |
| **10836** | Vial of Basilisk Venom | Quest Item | Yes | 1 | `1603` | Stone Cold Monster |
| **72119** | Greenguard Basilisk Tail | Quest Item | Yes | 5 | `8832` | Dinner for Two |

---

## 3. Implementation Logic

1. **Packet Listening**: Intercept the incoming packet with command `cmd: "monsterDrops"`.
2. **Quest Requirement Evaluation**:
   * Inspect the `items` dictionary keyed by item ID.
   * Check whether `sReqQuests` matches currently active or pending quests.
   * Match `questObjective` against active objectives to determine whether farming this monster satisfies the quest conditions.
   * Verify `questGated` to prevent unnecessary combat if prerequisites are unmet.
3. **Inventory & Stack Check**:
   * Verify temporary inventory for items marked `bTemp: true`.
   * Compare current quantity against `iStk` to cease combat once targets are met.

---

## 4. Raw Response Payload

<details>
<summary>Click to view raw JSON packet</summary>

```json
{
  "t": "xt",
  "b": {
    "r": -1,
    "o": {
      "cmd": "monsterDrops",
      "MonMapID": 1,
      "items": {
        "1564": {
          "ItemID": 1564,
          "sName": "Basilisk's tail",
          "sDesc": "How can a Basilisk stand without it's tail.",
          "iRng": 10,
          "iDPS": 100,
          "iLvl": 1,
          "iRty": 10,
          "iCost": 0,
          "bTemp": true,
          "iStk": 1,
          "bPTR": false,
          "bUpg": false,
          "bCoins": false,
          "bStaff": false,
          "sLink": "BasiliskTail",
          "iQSIndex": -1,
          "iQSValue": 0,
          "sReqQuests": "314",
          "bHouse": false,
          "sType": "Quest Item",
          "sIcon": "iibag",
          "sES": "None",
          "sElmt": "None",
          "metaValues": {},
          "iQty": 1,
          "questObjective": [
            "Terrifying Reptile"
          ],
          "questGated": [
            "Terrifying Reptile"
          ],
          "bVaryQty": false
        },
        "1580": {
          "ItemID": 1580,
          "sName": "Black Knight Arm Piece",
          "sDesc": "The arm plate from the Black Knight suit of armor.",
          "iRng": 0,
          "iDPS": 100,
          "iLvl": 1,
          "iRty": 10,
          "iCost": 0,
          "bTemp": true,
          "iStk": 1,
          "bPTR": false,
          "bUpg": false,
          "bCoins": false,
          "bStaff": false,
          "sLink": "",
          "iQSIndex": -1,
          "iQSValue": 0,
          "sReqQuests": "318",
          "bHouse": false,
          "sType": "Quest Item",
          "sIcon": "iibag",
          "sES": "None",
          "sElmt": "None",
          "metaValues": {},
          "iQty": 1,
          "questObjective": [
            "Hardly Suiting Armor"
          ],
          "questGated": [
            "Hardly Suiting Armor"
          ],
          "bVaryQty": false
        },
        "5193": {
          "ItemID": 5193,
          "sName": "Size S Finger",
          "sDesc": "A human finger. Gross.",
          "iRng": 10,
          "iDPS": 0,
          "iLvl": 1,
          "iRty": 10,
          "iCost": 0,
          "bTemp": true,
          "iStk": 1,
          "bPTR": false,
          "bUpg": false,
          "bCoins": false,
          "bStaff": false,
          "sLink": "",
          "iQSIndex": -1,
          "iQSValue": 0,
          "sReqQuests": "700",
          "bHouse": false,
          "sType": "Quest Item",
          "sIcon": "iibag",
          "sES": "None",
          "sElmt": "None",
          "metaValues": {},
          "iQty": 1,
          "questObjective": [
            "The Ring's The Thing"
          ],
          "questGated": [
            "The Ring's The Thing"
          ],
          "bVaryQty": false
        },
        "7064": {
          "ItemID": 7064,
          "sName": "GreenGuard Basilisk Scale",
          "sDesc": "A scale from a basilisk that lives in GreenGuard Forest.",
          "iRng": 10,
          "iDPS": 0,
          "iLvl": 1,
          "iRty": 10,
          "iCost": 0,
          "bTemp": true,
          "iStk": 3,
          "bPTR": false,
          "bUpg": false,
          "bCoins": false,
          "bStaff": false,
          "sLink": "",
          "iQSIndex": -1,
          "iQSValue": 0,
          "sReqQuests": "964",
          "bHouse": false,
          "sType": "Quest Item",
          "sIcon": "iibag",
          "sES": "None",
          "sElmt": "None",
          "metaValues": {},
          "iQty": 1,
          "questObjective": [
            "After a While… "
          ],
          "questGated": [
            "After a While… "
          ],
          "bVaryQty": false
        },
        "7462": {
          "ItemID": 7462,
          "sName": "Basketful of Dyed Eggs",
          "sDesc": "An evolved bunny berserker can't go around without their basket of eggs to hand out. (Or throw at opponents!) Use this in the merge shop to make the Evolved Bunny Berserker armor!",
          "iRng": 10,
          "iDPS": 0,
          "iLvl": 1,
          "iRty": 10,
          "iCost": 10,
          "bTemp": false,
          "iStk": 4,
          "bPTR": false,
          "bUpg": false,
          "bCoins": false,
          "bStaff": false,
          "sLink": "",
          "iQSIndex": -1,
          "iQSValue": 0,
          "sReqQuests": "",
          "bHouse": false,
          "sType": "Item",
          "sIcon": "iibag",
          "sES": "None",
          "sElmt": "None",
          "metaValues": {},
          "iQty": 1,
          "bVaryQty": false
        },
        "10836": {
          "ItemID": 10836,
          "sName": "Vial of Basilisk Venom",
          "sDesc": "This was NOT an easy item to get!",
          "iRng": 10,
          "iDPS": 0,
          "iLvl": 1,
          "iRty": 10,
          "iCost": 0,
          "bTemp": true,
          "iStk": 1,
          "bPTR": false,
          "bUpg": false,
          "bCoins": false,
          "bStaff": false,
          "sLink": "",
          "iQSIndex": -1,
          "iQSValue": 0,
          "sReqQuests": "1603",
          "bHouse": false,
          "sType": "Quest Item",
          "sIcon": "iibag",
          "sES": "None",
          "sElmt": "None",
          "metaValues": {},
          "iQty": 1,
          "questObjective": [
            "Stone Cold Monster"
          ],
          "questGated": [
            "Stone Cold Monster"
          ],
          "bVaryQty": false
        },
        "72119": {
          "ItemID": 72119,
          "sName": "Greenguard Basilisk Tail",
          "sDesc": "",
          "iRng": 10,
          "iDPS": 0,
          "iLvl": 1,
          "iRty": 10,
          "iCost": 0,
          "bTemp": true,
          "iStk": 5,
          "bPTR": false,
          "bUpg": false,
          "bCoins": false,
          "bStaff": false,
          "sLink": "",
          "iQSIndex": -1,
          "iQSValue": 0,
          "sReqQuests": "8832",
          "bHouse": false,
          "sType": "Quest Item",
          "sIcon": "iibag",
          "sES": "None",
          "sElmt": "None",
          "metaValues": {},
          "iQty": 1,
          "questObjective": [
            "Dinner for Two"
          ],
          "questGated": [
            "Dinner for Two"
          ],
          "bVaryQty": false
        }
      }
    }
  }
}
```
</details>