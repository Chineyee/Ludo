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

(define-public (join-game (game-id uint))
    (let (
        (game (unwrap! (map-get? games game-id) ERR-INVALID-GAME))
        (player tx-sender)
        (current-players (get players game))
    )
        (if (>= (len current-players) u4)
            ERR-GAME-FULL
            (ok (map-set games
                game-id
                (merge game 
                    {
                        players: (as-max-len? (concat current-players (list player)) u4)
                    }
                )
            ))
        )
    )
)

(define-public (mint-game-asset (name (string-ascii 50)) (rarity (string-ascii 20)) (price uint))
    (let (
        (asset-id (var-get asset-nonce))
        (owner tx-sender)
    )
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
)

(define-public (list-asset-for-sale (asset-id uint) (price uint))
    (let (
        (asset (unwrap! (map-get? game-assets asset-id) ERR-INVALID-GAME))
    )
        (if (not (is-eq tx-sender (get owner asset)))
            ERR-NOT-AUTHORIZED
            (ok (map-set game-assets
                asset-id
                (merge asset {
                    price: price,
                    for-sale: true
                })
            ))
        )
    )
)