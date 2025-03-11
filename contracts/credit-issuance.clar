;; Credit Issuance Contract
;; Generates tradable credits for verified energy savings

(define-fungible-token energy-efficiency-credit)

(define-map improvements
  { improvement-id: uint }
  {
    building-id: uint,
    energy-saved: uint,
    verified-by: principal,
    credits-issued: uint
  }
)

(define-map credit-issuances
  { issuance-id: uint }
  {
    improvement-id: uint,
    amount: uint,
    issuance-date: uint
  }
)

(define-data-var issuance-nonce uint u0)
(define-data-var improvement-nonce uint u0)

(define-constant contract-owner tx-sender)

(define-read-only (get-improvement (improvement-id uint))
  (map-get? improvements { improvement-id: improvement-id })
)

(define-read-only (get-credit-issuance (issuance-id uint))
  (map-get? credit-issuances { issuance-id: issuance-id })
)

(define-public (register-improvement (building-id uint) (energy-saved uint))
  (let
    (
      (new-improvement-id (+ (var-get improvement-nonce) u1))
    )
    (var-set improvement-nonce new-improvement-id)
    (ok (map-set improvements
      { improvement-id: new-improvement-id }
      {
        building-id: building-id,
        energy-saved: energy-saved,
        verified-by: tx-sender,
        credits-issued: u0
      }
    ))
  )
)

(define-public (issue-credits (improvement-id uint) (amount uint))
  (let
    (
      (new-issuance-id (+ (var-get issuance-nonce) u1))
      (improvement (unwrap! (get-improvement improvement-id) (err u404)))
    )
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (asserts! (<= (+ (get credits-issued improvement) amount) (get energy-saved improvement)) (err u401))
    (var-set issuance-nonce new-issuance-id)
    (try! (ft-mint? energy-efficiency-credit amount (get verified-by improvement)))
    (map-set improvements
      { improvement-id: improvement-id }
      (merge improvement { credits-issued: (+ (get credits-issued improvement) amount) })
    )
    (ok (map-set credit-issuances
      { issuance-id: new-issuance-id }
      {
        improvement-id: improvement-id,
        amount: amount,
        issuance-date: block-height
      }
    ))
  )
)

(define-read-only (get-credit-balance (account principal))
  (ft-get-balance energy-efficiency-credit account)
)

