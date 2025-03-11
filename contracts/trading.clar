;; Trading Contract
;; Facilitates buying and selling of energy efficiency credits

(define-map credit-balances
  { account: principal }
  { balance: uint }
)

(define-map orders
  { order-id: uint }
  {
    seller: principal,
    amount: uint,
    price: uint,
    status: (string-ascii 10)
  }
)

(define-data-var order-nonce uint u0)

(define-read-only (get-order (order-id uint))
  (map-get? orders { order-id: order-id })
)

(define-read-only (get-credit-balance (account principal))
  (default-to { balance: u0 } (map-get? credit-balances { account: account }))
)

(define-public (create-sell-order (amount uint) (price uint))
  (let
    (
      (new-order-id (+ (var-get order-nonce) u1))
      (seller-balance (get balance (get-credit-balance tx-sender)))
    )
    (asserts! (>= seller-balance amount) (err u401))
    (var-set order-nonce new-order-id)
    (map-set credit-balances
      { account: tx-sender }
      { balance: (- seller-balance amount) }
    )
    (ok (map-set orders
      { order-id: new-order-id }
      {
        seller: tx-sender,
        amount: amount,
        price: price,
        status: "active"
      }
    ))
  )
)

(define-public (fulfill-order (order-id uint))
  (let
    (
      (order (unwrap! (get-order order-id) (err u404)))
      (buyer-balance (get balance (get-credit-balance tx-sender)))
    )
    (asserts! (is-eq (get status order) "active") (err u400))
    (asserts! (>= (stx-get-balance tx-sender) (get price order)) (err u401))
    (try! (stx-transfer? (get price order) tx-sender (get seller order)))
    (map-set credit-balances
      { account: tx-sender }
      { balance: (+ buyer-balance (get amount order)) }
    )
    (ok (map-set orders
      { order-id: order-id }
      (merge order { status: "fulfilled" })
    ))
  )
)

(define-public (cancel-order (order-id uint))
  (let
    (
      (order (unwrap! (get-order order-id) (err u404)))
      (seller-balance (get balance (get-credit-balance (get seller order))))
    )
    (asserts! (is-eq tx-sender (get seller order)) (err u403))
    (asserts! (is-eq (get status order) "active") (err u400))
    (map-set credit-balances
      { account: (get seller order) }
      { balance: (+ seller-balance (get amount order)) }
    )
    (ok (map-set orders
      { order-id: order-id }
      (merge order { status: "cancelled" })
    ))
  )
)

;; Administrative function to set initial balances (for demonstration purposes)
(define-public (set-initial-balance (account principal) (balance uint))
  (ok (map-set credit-balances { account: account } { balance: balance }))
)

