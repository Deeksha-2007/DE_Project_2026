# Problem Understanding – Dream11 Fantasy Sports Database

## 1. Project Overview

Dream11 is a fantasy cricket platform where users create fantasy teams of exactly 11 players from the two real teams playing in a match. Each team must follow a 100-credit limit, with a maximum of 7 players from one real team. Users select a captain (2x points) and vice-captain (1.5x points). They can join contests using wallet money and receive winnings based on their performance.

The objective is to rebuild a properly structured database that supports fast user operations, accurate financial transactions and reliable reporting.

## 2. Problem Statements

| ID | Business Requirement | Stakeholder | Classification |
|---|---|---|---|
| P1 | Load the match lobby, player pool and available contests quickly before a match locks. | Fantasy players, User app team | Customer-facing / Real-time |
| P2 | Improve the speed of viewing saved teams, team previews, leaderboards and wallet history during live matches. | Fantasy players, User app team | Customer-facing / Real-time |
| P3 | Ensure team creation, contest joining and wallet deductions are fast and reliable. | Contest engine, Product team | Customer-facing / Real-time |
| P4 | Quickly identify teams violating fantasy rules and users entering multiple teams in the same contest. | Fair-play team | Customer-facing / Real-time |
| P5 | Identify paid contest entries where the corresponding wallet entry-fee deduction is missing. | Finance audit team | Reporting / Analytics |
| P6 | Improve withdrawal processing, refunds and compliance checks involving KYC, TDS and state restrictions. | Finance, Payouts and Compliance teams | Reporting / Analytics |
| P7 | Improve fantasy-point calculations, player averages, recent performance and player selection reports. | Points engine, Statistics team | Reporting / Analytics |
| P8 | Generate faster reports for contest fill rates, winnings, head-to-head performance and deposits while supporting 20x user growth. | Product and Finance teams | Reporting / Analytics |

## 3. Assumptions

1. Every fantasy team contains exactly 11 players selected from the two teams playing in that match.
2. The total credits used cannot exceed 100.
3. A maximum of 7 players can be selected from one real team.
4. The captain receives 2x fantasy points and the vice-captain receives 1.5x fantasy points.
5. Wallet transactions include deposits, entry fees, winnings, refunds, bonuses and withdrawals.
6. Financial and compliance records must remain accurate and consistent.

## 4. Conclusion

The database must support fast real-time operations, fair contest participation, accurate wallet management and efficient analytical reporting. It should also maintain data integrity and handle future growth without affecting performance.