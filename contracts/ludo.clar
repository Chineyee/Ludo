;; Ludo Gaming Platform Smart Contract
;; This contract handles game assets, player management, and marketplace functionality

;; Define data variables
(define-data-var admin principal tx-sender)
(define-map players 
    principal 
    {
        username: (string-ascii 50),
        games-played: uint,
        wins: uint,
        active-games: (list 10 uint),
        nft-balance: uint
    }
)

(define-map games 
    uint 
    {
        status: (string-ascii 20),
        players: (list 4 principal),
        winner: (optional principal),
        stake: uint,
        created-at: uint
    }
)

(define-map game-assets
    uint
    {
        owner: principal,
        name: (string-ascii 50),
        rarity: (string-ascii 20),
        price: uint,
        for-sale: bool
    }
)

;; Initialize contract variables
(define-data-var game-nonce uint u0)
(define-data-var asset-nonce uint u0)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-GAME-FULL (err u101))
(define-constant ERR-INVALID-GAME (err u102))
(define-constant ERR-NOT-ENOUGH-FUNDS (err u103))
(define-constant ERR-INVALID-USERNAME (err u104))
(define-constant ERR-INVALID-ASSET-NAME (err u105))
(define-constant ERR-INVALID-RARITY (err u106))
(define-constant ERR-INVALID-PRICE (err u107))
(define-constant ERR-INVALID-STATUS (err u108))
(define-constant ERR-GAME-NOT-IN-PROGRESS (err u109))

;; Define valid game statuses
(define-constant STATUS-IN-PROGRESS "in-progress")
(define-constant STATUS-COMPLETED "completed")

;; Read-only functions
(define-read-only (get-player-info (player principal))
    (map-get? players player)
)

(define-read-only (get-game-info (game-id uint))
    (map-get? games game-id)
)

(define-read-only (get-asset-info (asset-id uint))
    (map-get? game-assets asset-id)
)

;; Public functions
(define-public (register-player (username (string-ascii 50)))
    (let ((player tx-sender))
        (if (and (>= (len username) u1) (<= (len username) u50))
            (ok (map-set players 
                player
                {
                    username: username,
                    games-played: u0,
                    wins: u0,
                    active-games: (list),
                    nft-balance: u0
                }
            ))
            ERR-INVALID-USERNAME
        )
    )
)

(define-public (create-game (stake uint))
    (let (
        (game-id (var-get game-nonce))
        (player tx-sender)
    )
        (if (>= stake (stx-get-balance tx-sender))
            ERR-NOT-ENOUGH-FUNDS
            (begin
                (var-set game-nonce (+ game-id u1))
                (ok (map-set games
                    game-id
                    {
                        status: "waiting",
                        players: (list player),
                        winner: none,
                        stake: stake,
                        created-at: block-height
                    }
                ))
            )
        )
    )
)

(define-public (mint-game-asset (name (string-ascii 50)) (rarity (string-ascii 20)) (price uint))
    (let (
        (asset-id (var-get asset-nonce))
        (owner tx-sender)
    )
        (if (and 
            (and (>= (len name) u1) (<= (len name) u50))
            (and (>= (len rarity) u1) (<= (len rarity) u20))
            (> price u0)
        )
            (begin
                (var-set asset-nonce (+ asset-id u1))
                (ok (map-set game-assets
                    asset-id
                    {
                        owner: owner,
                        name: name,
                        rarity: rarity,
                        price: price,
                        for-sale: false
                    }
                ))
            )
            (if (not (and (>= (len name) u1) (<= (len name) u50)))
                ERR-INVALID-ASSET-NAME
                (if (not (and (>= (len rarity) u1) (<= (len rarity) u20)))
                    ERR-INVALID-RARITY
                    ERR-INVALID-PRICE
                )
            )
        )
    )
)

(define-public (list-asset-for-sale (asset-id uint) (price uint))
    (let (
        (asset (unwrap! (map-get? game-assets asset-id) ERR-INVALID-GAME))
    )
        (if (not (is-eq tx-sender (get owner asset)))
            ERR-NOT-AUTHORIZED
            (if (> price u0)
                (ok (map-set game-assets
                    asset-id
                    (merge asset {
                        price: price,
                        for-sale: true
                    })
                ))
                ERR-INVALID-PRICE
            )
        )
    )
)

(define-public (join-game (game-id uint))
    (let (
        (game (unwrap! (map-get? games game-id) ERR-INVALID-GAME))
        (player tx-sender)
        (current-players (get players game))
        (game-stake (get stake game))
        (new-player-list (list player))
    )
        (if (not (is-eq (get status game) "waiting"))
            ERR-INVALID-GAME
            (if (>= (len current-players) u4)
                ERR-GAME-FULL
                (if (>= game-stake (stx-get-balance tx-sender))
                    ERR-NOT-ENOUGH-FUNDS
                    (ok (map-set games
                        game-id
                        (merge game {
                            players: (unwrap! (as-max-len? (concat current-players new-player-list) u4) ERR-GAME-FULL),
                            status: (if (is-eq (+ (len current-players) u1) u4) 
                                      "waiting"
                                      "in-progress")
                        })
                    ))
                )
            )
        )
    )
)

(define-public (update-game-status (game-id uint))
    (let (
        (game (unwrap! (map-get? games game-id) ERR-INVALID-GAME))
        (current-players (get players game))
    )
        (asserts! (is-eq (len current-players) u4) ERR-GAME-FULL)
        (asserts! (is-some (index-of current-players tx-sender)) ERR-NOT-AUTHORIZED)
        (ok (map-set games
            game-id
            (merge game {
                status: "ready"
            })
        ))
    )
)

(define-public (update-game-progress (game-id uint) (new-status (string-ascii 20)) (winner (optional principal)))
    (let (
        (game (unwrap! (map-get? games game-id) ERR-INVALID-GAME))
        (current-players (get players game))
    )
        (asserts! (is-some (index-of current-players tx-sender)) ERR-NOT-AUTHORIZED)
        (asserts! (or (is-eq new-status STATUS-IN-PROGRESS) 
                     (is-eq new-status STATUS-COMPLETED)) 
                 ERR-INVALID-STATUS)
        
        (if (is-some winner)
            (if (is-eq new-status STATUS-COMPLETED)
                (begin
                    (asserts! (is-some (index-of current-players (unwrap! winner ERR-NOT-AUTHORIZED))) 
                             ERR-NOT-AUTHORIZED)
                    (update-winner-stats game-id winner)
                )
                ERR-GAME-NOT-IN-PROGRESS
            )
            (ok (map-set games
                game-id
                (merge game {
                    status: new-status
                })
            ))
        )
    )
)

;; Helper function to update winner statistics
(define-private (update-winner-stats (game-id uint) (winner-principal (optional principal)))
    (let (
        (game (unwrap! (map-get? games game-id) ERR-INVALID-GAME))
        (winner (unwrap! winner-principal ERR-NOT-AUTHORIZED))
        (winner-info (unwrap! (map-get? players winner) ERR-NOT-AUTHORIZED))
    )
        (ok (begin
            (map-set games
                game-id
                (merge game {
                    status: STATUS-COMPLETED,
                    winner: winner-principal
                })
            )
            (map-set players
                winner
                (merge winner-info {
                    wins: (+ (get wins winner-info) u1)
                })
            )
        ))
    )
)

