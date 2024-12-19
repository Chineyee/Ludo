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