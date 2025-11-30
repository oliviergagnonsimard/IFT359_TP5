#lang racket
(require "Flots-lib.rkt")
(require "TP5-lib-facturation.rkt")
(require "TP5-lib-charge.rkt")
(provide bill-one)
(provide bill-all)
(provide reorganize)
(provide total-bill-for)
(provide total-bill)
(provide CPU-load-stream)
(provide memory-load-stream)
(provide total-load-stream)
(provide stream-of-smoothed-total-loads)
(provide stream-of-overload-periods)
; ***************** IFT359 / TP5
; ***************** Gagnon-Simard, Olivier (24096336)


; Partie 1 : Les flots finis
(define (cout CPU mem nbTaches) (+ (* 10 CPU) (+ (* 5 mem) nbTaches)))

(define (bill-one stream-of-reports month company)
  (let* ([filtre
          (filter-stream
           (lambda (report)
             (and (equal? (report-company report) company)
                  (equal? (report-month report) month)))
           stream-of-reports)]

        

         [total
          (accumulate-stream
           (lambda (report acc)
             (+ acc (cout (report-CPU report)
                          (report-memory report)
                          1)))
           0
           filtre)]

         [type
          (if (empty-stream? filtre)
              '()
              (report-company-type (head filtre))
              )
          ]
         )

   (if (or (equal? type 'EDUCATION) (equal? type 'OBNL) (equal? type '()))
       (list month company 0)
    (list month company total))

    ))

(define (bill-all stream-of-reports month)

  (define tasks-this-month (filter-stream (lambda (g) (equal? month (report-month g))) stream-of-reports))

  (if (empty-stream? tasks-this-month) the-empty-stream
  
  (map-stream (lambda (x) (bill-one stream-of-reports month x))
              
   (accumulate-stream
   (lambda (report acc)
     (if (and (not (member (report-company report) acc)) (equal? month (report-month report))) (cons (report-company report) acc) acc)
     )
   '()
   stream-of-reports)
  ))
  )


(define (reorganize stream-of-reports)
  (cons-stream (head stream-of-reports)
               (reorganize (filter-stream (lambda (x) (equal? (report-company (head stream-of-reports)) (report-company x)))
                                         (tail stream-of-reports)))
              )
  )

(define (total-bill stream-of-reports fill-criteria?)
  (define filtre (filter-stream fill-criteria? stream-of-reports))

  (accumulate-stream
   (lambda (report acc)
     (if (or (eq? (report-company-type report) 'EDUCATION) (eq? (report-company-type report) 'OBNL)) acc
      (+ acc (cout (report-CPU report)
                  (report-memory report)
                  1)))
     )
   0
   filtre)
  )

(define (total-bill-for stream-of-reports month)
  (total-bill stream-of-reports (lambda (x) (eq? month (report-month x)) ))
 
  )

; Partie 2 : Les flots infinis

; Fonctions utilitaires
(define (charge-CPU worker) (state-n-waiting worker))
(define (charge-Mem worker) (+ (state-n-waiting worker) (state-n-history worker)))
(define (charge-Totale worker) (+ (* 2 (state-n-waiting worker)) (state-n-history worker)))

(define (CPU-load-stream workers-states-stream w-id)
  (map-stream
   charge-CPU
   (filter-stream (lambda (worker)
                    (eq? w-id (state-w-id worker))
                    )
                  workers-states-stream)

   )
  )

(define (memory-load-stream workers-states-stream w-id) 7)

(define (total-load-stream workers-states-stream w-id) 8)

(define (stream-of-smoothed-total-loads workers-state-stream w-id) 9)

(define (stream-of-overload-periods stream-of-states w-id overload?) 10)



   ;(equal? (bill-one the-stream-of-reports 'janvier 'Google) '(janvier Google 753))
   ;(equal? (bill-one the-stream-of-reports 'janvier 'APPLE) '(janvier APPLE 1251))
   ;(equal? (bill-one the-stream-of-reports 'janvier 'IXIA) '(janvier IXIA 0))
   ;(equal? (bill-one the-stream-of-reports 'janvier 'UdeS) '(janvier UdeS 0))
   ;(equal? (bill-one the-stream-of-reports 'janvier 'Microsoft) '(janvier Microsoft 0))
   ;(equal? (bill-one the-stream-of-reports 'février 'Google) '(février Google 501))
   ;(equal? (bill-one the-stream-of-reports 'février 'APPLE) '(février APPLE 12501))
   ;(equal? (bill-one the-stream-of-reports 'février 'IXIA) '(février IXIA 0))
   ;(equal? (bill-one the-stream-of-reports 'février 'UdeS) '(février UdeS 0))
   ;(equal? (bill-one the-stream-of-reports 'février 'Microsoft) '(février Microsoft 16251))
   ;(equal? (bill-one the-stream-of-reports 'mars 'Google) '(mars Google 0))
;(define (member-stream? element stream)
  ;(and (not (empty-stream? stream))
       ;(or (equal? element (head stream))
           ;(member-stream? element (tail stream)))))


;(define bills-janvier (bill-all the-stream-of-reports 'janvier))
;(define bills-février (bill-all the-stream-of-reports 'février))
;(define bills-mars (bill-all the-stream-of-reports 'mars))
;(eq? (length-stream bills-janvier) 4)
;(eq? (length-stream bills-février) 5)
;(empty-stream? (bill-all the-stream-of-reports 'mars))
;(member-stream? (bill-one the-stream-of-reports 'janvier 'Google) bills-janvier)
;(member-stream? (bill-one the-stream-of-reports 'janvier 'APPLE) bills-janvier)
;(member-stream? (bill-one the-stream-of-reports 'janvier 'IXIA) bills-janvier)
;(member-stream? (bill-one the-stream-of-reports 'janvier 'UdeS) bills-janvier)
     
;(member-stream? (bill-one the-stream-of-reports 'février 'Google) bills-février)
;(member-stream? (bill-one the-stream-of-reports 'février 'APPLE)bills-février)
;(member-stream? (bill-one the-stream-of-reports 'février 'IXIA) bills-février)
;(member-stream? (bill-one the-stream-of-reports 'février 'UdeS) bills-février)
;(member-stream? (bill-one the-stream-of-reports 'février 'Microsoft) bills-février)

;(make-task-report 'janvier 'W-1 'ts-1 10 5 'Google 'CORPORATIF)
                              ;(make-task-report 'janvier 'W-2 'ts-2 20 10 'Google 'CORPORATIF)
                              ;(make-task-report 'janvier 'W-3 'ts-3 30 15 'Google 'CORPORATIF)
                              ;(make-task-report 'février 'W-4 'ts-4 40 20 'Google 'CORPORATIF)
                              ;(make-task-report 'janvier 'W-1 'ts-1 200 100 'IXIA 'OBNL)
                              ;(make-task-report 'février 'W-2 'ts-1 2000 1000 'IXIA 'OBNL)
                              ;(make-task-report 'janvier 'W-3 'ts-1 300 150 'UdeS 'EDUCATION)
                              ;(make-task-report 'février 'W-4 'ts-1 3000 150 'UdeS 'EDUCATION)
                              ;(make-task-report 'janvier 'W-1 'ts-1 100 50 'APPLE 'CORPORATIF)
                              ;(make-task-report 'février 'W-2 'ts-1 1000 500 'APPLE 'CORPORATIF)
                              ;(make-task-report 'février 'W-3 'ts-1 1500 250 'Microsoft 'CORPORATIF)
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'Google))) 1254)
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'APPLE))) 13752)
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'IXIA))) 0)
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'UdeS))) 0)
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'Microsoft))) 16251)


;(foldr + 0 (map (lambda(m) (total-bill-for the-stream-of-reports m))
                        ;'(janvier février mars)))
;(foldr + 0 (map (lambda(cie) (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) cie))))
                          ;'(Google APPLE IXIA UdeS Microsoft)))


;(eq?
; (foldr + 0 (map (lambda(m) (total-bill-for the-stream-of-reports m))
;                        '(janvier février mars)))   
;       (foldr + 0 (map (lambda(cie) (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) cie))))
;                          '(Google APPLE IXIA UdeS Microsoft))))


; Month Worker-id Task-id CPU Memory Company CompanyType