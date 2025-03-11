;; Energy Audit Contract
;; Records baseline energy consumption for buildings

(define-map buildings
  { building-id: uint }
  {
    owner: principal,
    address: (string-ascii 100),
    baseline-consumption: uint,
    audit-date: uint
  }
)

(define-data-var building-nonce uint u0)

(define-constant contract-owner tx-sender)

(define-read-only (get-building (building-id uint))
  (map-get? buildings { building-id: building-id })
)

(define-public (register-building (address (string-ascii 100)) (baseline-consumption uint))
  (let
    (
      (new-building-id (+ (var-get building-nonce) u1))
    )
    (var-set building-nonce new-building-id)
    (ok (map-set buildings
      { building-id: new-building-id }
      {
        owner: tx-sender,
        address: address,
        baseline-consumption: baseline-consumption,
        audit-date: block-height
      }
    ))
  )
)

(define-public (update-baseline (building-id uint) (new-baseline uint))
  (let
    (
      (building (unwrap! (get-building building-id) (err u404)))
    )
    (asserts! (is-eq tx-sender (get owner building)) (err u403))
    (ok (map-set buildings
      { building-id: building-id }
      (merge building {
        baseline-consumption: new-baseline,
        audit-date: block-height
      })
    ))
  )
)

